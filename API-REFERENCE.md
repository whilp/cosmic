# cosmic-lua API Reference

Complete API documentation for all cosmic-lua modules.

## Table of Contents

### cosmic Package (High-Level Utilities)
- [cosmic.init](#cosmicinit) - Main entry point and initialization
- [cosmic.fetch](#cosmicfetch) - HTTP fetching with retry
- [cosmic.spawn](#cosmicspawn) - Process spawning
- [cosmic.walk](#cosmicwalk) - Directory tree walking
- [cosmic.doc](#cosmicdoc) - Documentation extraction
- [cosmic.embed](#cosmicembed) - File embedding
- [cosmic.example](#cosmicexample) - Executable examples
- [cosmic.teal](#cosmicteal) - Teal compilation

### cosmo Package (Low-Level System Interfaces)
- [cosmo.getopt](#cosmogetopt) - Command-line parsing
- [cosmo.lsqlite3](#cosmolsqlite3) - SQLite database
- [cosmo.unix](#cosmounix) - POSIX system calls
- [cosmo.path](#cosmopath) - Path manipulation
- [cosmo.re](#cosmore) - Regular expressions
- [cosmo.zip](#cosmozip) - ZIP archive access
- [cosmo.argon2](#cosmoargon2) - Password hashing
- [cosmo.maxmind](#cosmomaxmind) - GeoIP lookups
- [cosmo.finger](#cosmofinger) - TCP fingerprinting
- [cosmo.goodsocket](#cosmogoodsocket) - Socket programming

---

## cosmic.init

Main entry point for cosmic-lua programs.

### Types

```teal
local record Env
  stdin: File
  stdout: File
  stderr: File
  environ: {string:string}
end

local record File
  write: function(self: File, data: string): boolean
  read: function(self: File, size?: number): string
  close: function(self: File)
end
```

### Functions

#### cosmic.main(fn)

Wrap your program's main function with proper initialization and exit handling.

```teal
cosmic.main(function(args: {string}, env: Env): number, string
  -- Your program logic here
  return 0  -- exit code
end)
```

**Parameters**:
- `fn` - Main function that receives args and env

**Main function signature**:
- `args: {string}` - Command-line arguments (args[1] is script name, args[2+] are user args)
- `env: Env` - Environment with stdin/stdout/stderr and environ map

**Returns**:
- `number` - Exit code (0 = success, non-zero = error)
- `string` (optional) - Error message (written to stderr if provided)

**Example**:

```teal
local cosmic = require("cosmic")

cosmic.main(function(args: {string}, env: cosmic.Env): number, string
  if #args < 2 then
    return 1, "Usage: program <arg>"
  end

  env.stdout:write("Hello, " .. args[2] .. "\n")
  return 0
end)
```

**When to use**: Always wrap your program's entry point with `cosmic.main()`.

**Notes**:
- Only runs when script is executed directly (not when required as module)
- Automatically writes error message to stderr if second return value is provided
- Calls `os.exit()` with the exit code

---

## cosmic.fetch

Structured HTTP fetching with optional retry logic.

### Types

```teal
local record Result
  ok: boolean          -- true if fetch succeeded
  status: number       -- HTTP status code (200, 404, etc.)
  headers: {string:string}  -- Response headers
  body: string         -- Response body
  error: string        -- Error message (only set if ok == false)
end

local record Opts
  headers: {string:string}     -- Request headers
  maxresponse: number          -- Maximum response size in bytes
  max_attempts: number         -- Maximum retry attempts (default: 1)
  max_delay: number            -- Maximum delay between retries in seconds (default: 30)
  should_retry: function(Result): boolean  -- Custom retry logic
end
```

### Functions

#### fetch.Fetch(url, opts?)

Fetch a URL and return structured result.

```teal
local fetch = require("cosmic.fetch")

local result = fetch.Fetch(url: string, opts?: Opts): Result
```

**Parameters**:
- `url: string` - URL to fetch
- `opts: Opts` (optional) - Fetch options

**Returns**: `Result` with `ok`, `status`, `headers`, `body`, or `error`

**Example: Basic fetch**

```teal
local fetch = require("cosmic.fetch")

local result = fetch.Fetch("https://example.com")
if result.ok then
  print("Status:", result.status)
  print("Content-Type:", result.headers["content-type"])
  print("Body length:", #result.body)
else
  print("Error:", result.error)
end
```

**Example: Fetch with retry**

```teal
local result = fetch.Fetch("https://api.example.com/data", {
  max_attempts = 3,
  max_delay = 30,
  should_retry = function(r: fetch.Result): boolean
    -- Retry on network errors, 5xx, or rate limiting
    return not r.ok or r.status >= 500 or r.status == 429
  end,
  headers = {
    ["User-Agent"] = "my-app/1.0",
    ["Accept"] = "application/json",
  },
})
```

**Example: Download large file with size limit**

```teal
local result = fetch.Fetch(url, {
  maxresponse = 10 * 1024 * 1024,  -- 10 MB limit
})
```

**Retry behavior**:
- Exponential backoff: waits 2^attempt seconds between retries
- Max delay caps the wait time
- `should_retry` callback determines if a response should be retried
- Defaults to no retry (max_attempts = 1)

**Notes**:
- Always check `result.ok` before accessing `result.body`
- Network errors return `ok = false` with `error` message
- HTTP errors (4xx, 5xx) return `ok = true` with `status` code (unless custom retry logic)
- Wraps `cosmo.Fetch()` to prevent accidentally discarding errors

---

## cosmic.spawn

Process spawning with control over stdin, stdout, and stderr.

### Types

```teal
local record Pipe
  fd: number
  write: function(self: Pipe, data: string): number
  read: function(self: Pipe, size?: number): string
  close: function(self: Pipe)
end

local record SpawnHandle
  pid: number
  stdin: Pipe
  stdout: Pipe
  stderr: Pipe
  wait: function(self: SpawnHandle): number, string
  read: function(self: SpawnHandle, size?: number): boolean | string, string, number
end

local record SpawnOpts
  stdin: string | number   -- String to write, or fd number
  stdout: number           -- fd number for stdout
  stderr: number           -- fd number for stderr
  env: {string}            -- Environment variables ["KEY=value", ...]
  cwd: string              -- Working directory
end
```

### Functions

#### spawn.spawn(argv, opts?)

Spawn a process and return a handle for interaction.

```teal
local spawn = require("cosmic.spawn")

local handle, err = spawn.spawn(argv: {string}, opts?: SpawnOpts): SpawnHandle, string
```

**Parameters**:
- `argv: {string}` - Command and arguments (argv[1] is the command)
- `opts: SpawnOpts` (optional) - Spawn options

**Returns**:
- `SpawnHandle` - Handle for process interaction
- `string` - Error message if spawn failed

**Example: Run command and capture output**

```teal
local spawn = require("cosmic.spawn")

local handle = spawn.spawn({"ls", "-la"})
if not handle then
  error("Failed to spawn process")
end

-- Read output and wait for exit
local ok, output, exit_code = handle:read()
print(output)
print("Exit code:", exit_code)
```

**Example: Pass stdin to process**

```teal
local handle = spawn.spawn({"cat"}, {
  stdin = "Hello from stdin!",
})
local ok, output = handle:read()
print(output)  -- "Hello from stdin!"
```

**Example: Run command in different directory**

```teal
local handle = spawn.spawn({"git", "status"}, {
  cwd = "/path/to/repo",
})
local ok, output = handle:read()
```

**Example: Custom environment**

```teal
local handle = spawn.spawn({"env"}, {
  env = {
    "PATH=/usr/bin:/bin",
    "HOME=/tmp",
    "MY_VAR=custom_value",
  },
})
```

**Example: Stream output in chunks**

```teal
local handle = spawn.spawn({"long-running-command"})

-- Read stdout in 1KB chunks
while true do
  local chunk = handle.stdout:read(1024)
  if not chunk or chunk == "" then
    break
  end
  print("Chunk:", chunk)
end

local exit_code = handle:wait()
print("Exited with:", exit_code)
```

**Handle methods**:

- `handle:read(size?)` - If size specified, returns that many bytes as string. If no size, reads all output, waits for exit, returns (success, output, exit_code).
- `handle:wait()` - Wait for process to exit, return exit code or (nil, error_msg)
- `handle.stdin:write(data)` - Write to process stdin
- `handle.stdout:read(size?)` - Read from process stdout
- `handle.stderr:read(size?)` - Read from process stderr
- `handle.stdin:close()` - Close stdin pipe
- `handle.stdout:close()` - Close stdout pipe
- `handle.stderr:close()` - Close stderr pipe

**Notes**:
- Command is found via PATH if argv[1] doesn't contain "/"
- stdin is automatically closed after writing if provided as string
- Pipes are created automatically unless fd numbers are provided
- Always call `wait()` or `read()` to reap the child process

---

## cosmic.walk

Directory tree walking and file collection.

### Types

```teal
local record Stat
  mode: function(self): number
  size: function(self): number
  mtim: function(self): number
end

local type Visitor = function(full_path: string, entry: string, stat: Stat, ctx: any): boolean
```

### Functions

#### walk.walk(dir, visitor, ctx?)

Walk directory tree, calling visitor for each entry.

```teal
local walk = require("cosmic.walk")

walk.walk<T>(dir: string, visitor: Visitor, ctx?: T): T
```

**Parameters**:
- `dir: string` - Directory to walk
- `visitor: Visitor` - Function called for each file/directory
- `ctx: T` (optional) - Context passed through to visitor

**Visitor signature**:
- `full_path: string` - Complete path to file/directory
- `entry: string` - Basename of file/directory
- `stat: Stat` - File metadata
- `ctx: any` - User-provided context
- **Returns**: `boolean` - Return false to skip recursing into subdirectories

**Returns**: Context object (potentially modified by visitor)

**Example: Print all files**

```teal
local walk = require("cosmic.walk")
local unix = require("cosmo.unix")

walk.walk(".", function(path, name, stat, ctx)
  if unix.S_ISDIR(stat:mode()) then
    print("Dir:", path)
  else
    print("File:", path, "size:", stat:size())
  end
  return true  -- continue recursing
end)
```

**Example: Skip .git directories**

```teal
walk.walk(".", function(path, name, stat, ctx)
  if unix.S_ISDIR(stat:mode()) and name == ".git" then
    print("Skipping:", path)
    return false  -- don't recurse into .git
  end
  return true
end)
```

**Example: Collect data with context**

```teal
local ctx = {
  file_count = 0,
  total_size = 0,
}

walk.walk(".", function(path, name, stat, ctx)
  if not unix.S_ISDIR(stat:mode()) then
    ctx.file_count = ctx.file_count + 1
    ctx.total_size = ctx.total_size + stat:size()
  end
  return true
end, ctx)

print("Files:", ctx.file_count, "Total size:", ctx.total_size)
```

#### walk.collect(dir, pattern)

Collect file paths matching a Lua pattern.

```teal
local files = walk.collect(dir: string, pattern: string): {string}
```

**Parameters**:
- `dir: string` - Directory to search
- `pattern: string` - Lua pattern to match against basenames

**Returns**: Array of full paths to matching files

**Example: Find all Teal files**

```teal
local files = walk.collect(".", "%.tl$")
for _, file in ipairs(files) do
  print(file)
end
```

**Example: Find all test files**

```teal
local test_files = walk.collect("lib", "_test%.tl$")
```

**Pattern examples**:
- `"%.tl$"` - Files ending in .tl
- `"^test_"` - Files starting with test_
- `"%.lua$"` - Lua files
- `"README"` - Files containing README

#### walk.collect_all(dir, base?, files?)

Recursively collect all files with Unix permissions.

```teal
local files = walk.collect_all(dir: string, base?: string, files?: {string:FileInfo}): {string:FileInfo}
```

**Returns**: Map of relative paths to `{mode: number}` info

**Example**:

```teal
local files = walk.collect_all("lib")
for path, info in pairs(files) do
  print(path, string.format("0%o", info.mode))
end
```

---

## cosmo.getopt

POSIX-style command-line argument parsing.

### Types

```teal
local record GetoptParser
  next: function(self): string, string
  remaining: function(self): {string}
  unknown: function(self): string
end
```

### Functions

#### getopt.new(args, short, long)

Create a new command-line parser.

```teal
local getopt = require("cosmo.getopt")

local parser = getopt.new(
  args: {string},
  short: string,
  long: {{string, string, string}}
): GetoptParser
```

**Parameters**:
- `args: {string}` - Command-line arguments (usually from cosmic.main)
- `short: string` - Short options (e.g., "hvo:") where `:` means required argument
- `long: {{name, arg_type, short_equiv}}` - Long option definitions

**Long option format**:
- `name: string` - Long option name (e.g., "help", "output")
- `arg_type: string` - "none" or "required"
- `short_equiv: string` - Corresponding short option letter

**Example: Basic argument parsing**

```teal
local getopt = require("cosmo.getopt")
local cosmic = require("cosmic")

cosmic.main(function(args, env)
  local verbose = false
  local output = "out.txt"

  local parser = getopt.new(args, "hvo:", {
    {"help", "none", "h"},
    {"verbose", "none", "v"},
    {"output", "required", "o"},
  })

  while true do
    local opt, arg = parser:next()
    if not opt then break end

    if opt == "h" or opt == "help" then
      env.stdout:write("Usage: program [options] <files>\n")
      return 0
    elseif opt == "v" or opt == "verbose" then
      verbose = true
    elseif opt == "o" or opt == "output" then
      output = arg
    else
      local unknown = parser:unknown()
      return 1, "Unknown option: " .. unknown
    end
  end

  local files = parser:remaining()

  if verbose then
    env.stderr:write("Output file: " .. output .. "\n")
    env.stderr:write("Processing " .. #files .. " files\n")
  end

  return 0
end)
```

**Usage**:

```bash
./program -v -o result.txt file1.txt file2.txt
./program --verbose --output result.txt file1.txt file2.txt
./program -vo result.txt file1.txt  # Combined short options
```

**Parser methods**:

- `parser:next()` - Returns next option and its argument: `(opt: string, arg: string)`
  - `opt` is the option letter/name (e.g., "v" or "verbose")
  - `arg` is the option argument (for options requiring arguments)
  - Returns `nil` when no more options
- `parser:remaining()` - Returns array of remaining non-option arguments
- `parser:unknown()` - Returns the unknown option that caused :next() to return "?"

**Notes**:
- Short options can be combined: `-vh` is same as `-v -h`
- Long options use `--name` or `--name=value`
- `--` stops option parsing; remaining args are non-options
- Unknown options return "?" from `next()`

---

## cosmo.lsqlite3

SQLite3 database interface.

### Types

```teal
local record Database
  exec: function(self: Database, sql: string, callback?: function, udata?: any): number
  prepare: function(self: Database, sql: string): Statement
  close: function(self: Database): number
  last_insert_rowid: function(self: Database): number
  errmsg: function(self: Database): string
  errcode: function(self: Database): number
end

local record Statement
  bind: function(self: Statement, idx: number, value: any): number
  bind_values: function(self: Statement, ...: any): number
  step: function(self: Statement): number
  reset: function(self: Statement): number
  finalize: function(self: Statement): number
  get_value: function(self: Statement, idx: number): any
  get_values: function(self: Statement): {any}
end
```

### Constants

```teal
lsqlite3.OK         -- Successful result
lsqlite3.ERROR      -- SQL error
lsqlite3.ROW        -- Step() has a row ready
lsqlite3.DONE       -- Step() has finished executing
-- Many more constants available
```

### Functions

#### lsqlite3.open(filename)

Open or create an SQLite database.

```teal
local lsqlite3 = require("cosmo.lsqlite3")

local db = lsqlite3.open(filename: string): Database
```

**Parameters**:
- `filename: string` - Path to database file (or ":memory:" for in-memory database)

**Returns**: `Database` handle (or nil on error)

**Example: Create and use database**

```teal
local lsqlite3 = require("cosmo.lsqlite3")

local db = lsqlite3.open("mydata.db")
if not db then
  error("Failed to open database")
end

-- Create table
local sql = [[
  CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL
  )
]]

if db:exec(sql) ~= lsqlite3.OK then
  error("Failed to create table: " .. db:errmsg())
end

-- Insert data using prepared statement
local stmt = db:prepare("INSERT INTO users (name, email) VALUES (?, ?)")
stmt:bind_values("Alice", "alice@example.com")
if stmt:step() ~= lsqlite3.DONE then
  error("Insert failed: " .. db:errmsg())
end
stmt:finalize()

-- Query data
db:exec("SELECT * FROM users", function(udata, cols, values, names)
  print(values[1], values[2], values[3])  -- id, name, email
  return 0
end)

db:close()
```

**Example: Transaction with rollback**

```teal
local db = lsqlite3.open("data.db")

db:exec("BEGIN TRANSACTION")

local stmt = db:prepare("INSERT INTO items (name, price) VALUES (?, ?)")

for _, item in ipairs(items) do
  stmt:bind_values(item.name, item.price)
  if stmt:step() ~= lsqlite3.DONE then
    db:exec("ROLLBACK")
    error("Insert failed: " .. db:errmsg())
  end
  stmt:reset()
end

stmt:finalize()
db:exec("COMMIT")
db:close()
```

**Example: Reading query results**

```teal
local stmt = db:prepare("SELECT id, name, email FROM users WHERE email LIKE ?")
stmt:bind_values("%@example.com")

while stmt:step() == lsqlite3.ROW do
  local id = stmt:get_value(1)
  local name = stmt:get_value(2)
  local email = stmt:get_value(3)
  print(id, name, email)
end

stmt:finalize()
```

**Database methods**:
- `db:exec(sql, callback?, udata?)` - Execute SQL (DDL/DML)
- `db:prepare(sql)` - Create prepared statement
- `db:close()` - Close database connection
- `db:last_insert_rowid()` - Get last inserted row ID
- `db:errmsg()` - Get last error message
- `db:errcode()` - Get last error code

**Statement methods**:
- `stmt:bind(index, value)` - Bind value to parameter by index
- `stmt:bind_values(...)` - Bind all values at once
- `stmt:step()` - Execute statement (returns ROW or DONE)
- `stmt:reset()` - Reset statement for reuse
- `stmt:finalize()` - Free statement resources
- `stmt:get_value(index)` - Get column value by index
- `stmt:get_values()` - Get all column values as array

**Best practices**:
- Always check return codes against lsqlite3.OK, lsqlite3.DONE, etc.
- Always call `stmt:finalize()` when done with statement
- Always call `db:close()` when done with database
- Use transactions for bulk operations
- Use prepared statements to prevent SQL injection

---

## cosmo.unix

POSIX system call interface.

### Types

```teal
local record Stat
  mode: function(self): number
  size: function(self): number
  mtim: function(self): number
  atim: function(self): number
  ctim: function(self): number
  dev: function(self): number
  ino: function(self): number
  nlink: function(self): number
  uid: function(self): number
  gid: function(self): number
end
```

### File Type Checks

```teal
unix.S_ISDIR(mode)   -- Is directory?
unix.S_ISREG(mode)   -- Is regular file?
unix.S_ISLNK(mode)   -- Is symbolic link?
unix.S_ISFIFO(mode)  -- Is FIFO?
unix.S_ISCHR(mode)   -- Is character device?
unix.S_ISBLK(mode)   -- Is block device?
unix.S_ISSOCK(mode)  -- Is socket?
```

### Constants

```teal
unix.CLOCK_REALTIME
unix.CLOCK_MONOTONIC
unix.O_RDONLY
unix.O_WRONLY
unix.O_RDWR
unix.O_CREAT
unix.O_APPEND
-- Many more...
```

### Functions

#### unix.stat(path)

Get file metadata.

```teal
local stat = unix.stat(path: string): Stat
```

**Example**:

```teal
local unix = require("cosmo.unix")

local stat = unix.stat("/path/to/file")
if not stat then
  print("File doesn't exist")
else
  if unix.S_ISDIR(stat:mode()) then
    print("It's a directory")
  else
    print("File size:", stat:size(), "bytes")
    print("Modified:", stat:mtim())
  end
end
```

#### unix.getcwd()

Get current working directory.

```teal
local cwd = unix.getcwd(): string
```

#### unix.chdir(path)

Change working directory.

```teal
local ok = unix.chdir(path: string): boolean
```

#### unix.clock_gettime(clock_id)

Get current time.

```teal
local timestamp = unix.clock_gettime(clock_id: number): number
```

**Example**:

```teal
local now = unix.clock_gettime(unix.CLOCK_REALTIME)
print("Unix timestamp:", now)
```

#### unix.nanosleep(seconds, nanoseconds)

Sleep for specified duration.

```teal
unix.nanosleep(seconds: number, nanoseconds: number)
```

**Example**:

```teal
unix.nanosleep(2, 500000000)  -- Sleep 2.5 seconds
```

#### unix.environ()

Get environment variables.

```teal
local env = unix.environ(): {string:string}
```

**Example**:

```teal
local env = unix.environ()
print("PATH:", env["PATH"])
print("HOME:", env["HOME"])
```

#### File Operations

```teal
unix.open(path, flags, mode?)
unix.close(fd)
unix.read(fd, size)
unix.write(fd, data)
unix.pipe()
unix.dup(fd)
unix.dup2(oldfd, newfd)
```

#### Process Operations

```teal
unix.fork()
unix.execve(path, argv, env)
unix.execvpe(file, argv, env)
unix.wait(pid)
unix.waitpid(pid, options)
unix.WIFEXITED(status)
unix.WEXITSTATUS(status)
unix.WIFSIGNALED(status)
unix.WTERMSIG(status)
```

#### Directory Operations

```teal
unix.opendir(path)
unix.mkdir(path, mode)
unix.rmdir(path)
```

---

## cosmo.path

Path manipulation utilities.

### Functions

#### path.join(...)

Join path components.

```teal
local full_path = path.join(...: string): string
```

**Example**:

```teal
local path = require("cosmo.path")

local p = path.join("/home", "user", "documents", "file.txt")
-- Result: "/home/user/documents/file.txt"

local p2 = path.join("relative", "path", "file.txt")
-- Result: "relative/path/file.txt"
```

#### path.dirname(path)

Get parent directory.

```teal
local parent = path.dirname(path: string): string
```

**Example**:

```teal
local parent = path.dirname("/home/user/file.txt")
-- Result: "/home/user"
```

#### path.basename(path)

Get filename component.

```teal
local name = path.basename(path: string): string
```

---

## cosmo.re

POSIX regular expression matching.

### Functions

#### re.search(pattern, string)

Search for pattern in string.

```teal
local re = require("cosmo.re")

local match = re.search(pattern: string, string: string): {string}
```

**Example**:

```teal
local re = require("cosmo.re")

local matches = re.search("([0-9]+)", "There are 42 items")
if matches then
  print("Found number:", matches[1])  -- "42"
end
```

---

## cosmo.zip

ZIP archive access (for reading embedded files).

### Functions

#### zip.open(path)

Open ZIP archive (or executable with embedded ZIP).

```teal
local zip = require("cosmo.zip")

local archive = zip.open(path: string)
```

**Example: Read embedded file**

```teal
-- cosmic-lua embeds files in /zip/ directory
local handle = io.open("/zip/tl.lua", "r")
local content = handle:read("*all")
handle:close()
```

---

## cosmo.argon2

Password hashing with Argon2.

### Functions

#### argon2.hash(password, salt, opts)

Hash password using Argon2.

```teal
local argon2 = require("cosmo.argon2")

local hash = argon2.hash(password: string, salt: string, opts?: table): string
```

---

## cosmic.doc

Extract documentation from Teal files.

### Functions

#### doc.extract(file)

Extract documentation comments and types from Teal source.

---

## cosmic.embed

Embed files into cosmic executable.

### Functions

#### embed.add(zip_path, file_content)

Add file to embedded ZIP archive.

---

## cosmic.example

Go-style executable example testing.

Write functions like `Example_feature()` with `-- Output:` comments to create testable examples.

---

## cosmic.teal

Teal compilation and type-checking.

### Functions

#### teal.check(file)

Type-check Teal file.

#### teal.compile(file)

Compile Teal to Lua.

---

## Quick Reference

| Category | Module | Function | Purpose |
|----------|--------|----------|---------|
| **HTTP** | cosmic.fetch | `Fetch(url, opts?)` | Fetch URL with retry |
| **Process** | cosmic.spawn | `spawn(argv, opts?)` | Spawn process |
| **Files** | cosmic.walk | `walk(dir, visitor, ctx?)` | Walk directory tree |
| **Files** | cosmic.walk | `collect(dir, pattern)` | Find files by pattern |
| **CLI** | cosmo.getopt | `new(args, short, long)` | Parse command-line args |
| **Database** | cosmo.lsqlite3 | `open(path)` | Open SQLite database |
| **Files** | cosmo.unix | `stat(path)` | Get file metadata |
| **Files** | cosmo.path | `join(...)` | Join path components |
| **Files** | cosmo.path | `dirname(path)` | Get parent directory |
| **System** | cosmo.unix | `getcwd()` | Get current directory |
| **System** | cosmo.unix | `environ()` | Get environment vars |
| **System** | cosmo.unix | `clock_gettime(id)` | Get current time |
| **System** | cosmo.unix | `nanosleep(sec, nsec)` | Sleep |
| **Regex** | cosmo.re | `search(pattern, str)` | Regex search |
| **Archive** | cosmo.zip | `open(path)` | Open ZIP archive |
| **Security** | cosmo.argon2 | `hash(password, salt)` | Hash password |

---

## Type Checking

cosmic-lua includes the Teal type checker:

```bash
./cosmic-lua /zip/tl.lua check myprogram.tl
```

---

## Common Patterns

See [QUICKSTART.md](QUICKSTART.md#common-patterns) for common usage patterns.

---

## See Also

- [QUICKSTART.md](QUICKSTART.md) - Get started quickly
- [README.md](README.md) - Project overview
- [examples/](examples/) - Complete example programs
- Source code in `lib/cosmic/*.tl` - Well-documented implementations
