# cosmic-lua Quick Start Guide

Get started with cosmic-lua in 5 minutes.

## Installation

Download and run the latest release:

```bash
curl -L -o cosmic-lua https://github.com/whilp/cosmic/releases/latest/download/cosmic-lua
chmod +x cosmic-lua
```

Or build from source:

```bash
make cosmic
# Binary will be at: o/cosmic
```

## Your First Program

Create `hello.tl`:

```teal
local cosmic = require("cosmic")

cosmic.main(function(args: {string}, env: cosmic.Env): number
  env.stdout:write("Hello from cosmic-lua!\n")
  return 0
end)
```

Run it:

```bash
./cosmic-lua hello.tl
# Output: Hello from cosmic-lua!
```

**What's happening**:
- `cosmic.main()` wraps your program with proper initialization
- `args` contains command-line arguments
- `env` provides stdin/stdout/stderr
- Return 0 for success, non-zero for errors

## Your Second Program: Fetch a URL

Create `fetch-example.tl`:

```teal
local cosmic = require("cosmic")
local fetch = require("cosmic.fetch")

cosmic.main(function(args: {string}, env: cosmic.Env): number, string
  if #args < 2 then
    return 1, "Usage: fetch-example.tl <url>"
  end

  local url = args[2]
  local result = fetch.Fetch(url)

  if result.ok then
    env.stdout:write("Status: " .. tostring(result.status) .. "\n")
    env.stdout:write("Body length: " .. #result.body .. " bytes\n")
    return 0
  else
    return 1, "Fetch failed: " .. result.error
  end
end)
```

Run it:

```bash
./cosmic-lua fetch-example.tl https://example.com
# Status: 200
# Body length: 1256 bytes
```

**Key points**:
- `fetch.Fetch()` returns a `Result` with `ok`, `status`, `headers`, `body`, or `error`
- Always check `result.ok` before using `result.body`
- Errors are returned as strings, not thrown

## Your Third Program: Spawn a Process

Create `run-command.tl`:

```teal
local cosmic = require("cosmic")
local spawn = require("cosmic.spawn")

cosmic.main(function(args: {string}, env: cosmic.Env): number, string
  -- Spawn a process and capture output
  local handle = spawn.spawn({"ls", "-la"})

  if not handle then
    return 1, "Failed to spawn process"
  end

  -- Read output and wait for process to exit
  local ok, output, exit_code = handle:read()

  env.stdout:write(output)

  if ok then
    return 0
  else
    return exit_code, "Command failed"
  end
end)
```

Run it:

```bash
./cosmic-lua run-command.tl
# total 128
# drwxr-xr-x  15 user  staff   480 Jan 25 10:30 .
# ...
```

**Key points**:
- `spawn.spawn()` returns a `SpawnHandle`
- `handle:read()` captures stdout and waits for exit
- Returns `(success, output, exit_code)`

## Your Fourth Program: Walk a Directory

Create `find-files.tl`:

```teal
local cosmic = require("cosmic")
local walk = require("cosmic.walk")

cosmic.main(function(args: {string}, env: cosmic.Env): number
  local pattern = args[2] or "%.tl$"  -- Default: find .tl files

  local files = walk.collect(".", pattern)

  env.stdout:write("Found " .. #files .. " files matching '" .. pattern .. "':\n")
  for _, file in ipairs(files) do
    env.stdout:write("  " .. file .. "\n")
  end

  return 0
end)
```

Run it:

```bash
./cosmic-lua find-files.tl "%.md$"
# Found 3 files matching '%.md$':
#   ./README.md
#   ./QUICKSTART.md
#   ./TUTORIAL.md
```

**Key points**:
- `walk.collect()` finds files matching a Lua pattern
- Returns array of full paths
- Use `walk.walk()` for custom visitor pattern

## Your Fifth Program: SQLite Database

Create `database-example.tl`:

```teal
local cosmic = require("cosmic")
local lsqlite3 = require("cosmo.lsqlite3")

cosmic.main(function(args: {string}, env: cosmic.Env): number, string
  -- Open database (creates if doesn't exist)
  local db = lsqlite3.open("example.db")
  if not db then
    return 1, "Failed to open database"
  end

  -- Create table
  local sql = [[
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY,
      name TEXT NOT NULL,
      email TEXT UNIQUE
    )
  ]]

  if db:exec(sql) ~= lsqlite3.OK then
    return 1, "Failed to create table: " .. db:errmsg()
  end

  -- Insert data using prepared statement
  local stmt = db:prepare("INSERT INTO users (name, email) VALUES (?, ?)")
  stmt:bind_values("Alice", "alice@example.com")
  stmt:step()
  stmt:finalize()

  -- Query data
  env.stdout:write("Users:\n")
  db:exec("SELECT name, email FROM users", function(udata: any, cols: number, values: {string}, names: {string}): number
    env.stdout:write("  " .. values[1] .. " <" .. values[2] .. ">\n")
    return 0
  end)

  db:close()
  return 0
end)
```

Run it:

```bash
./cosmic-lua database-example.tl
# Users:
#   Alice <alice@example.com>
```

**Key points**:
- `lsqlite3.open()` creates/opens database
- Use prepared statements for parameterized queries
- Always check return codes against `lsqlite3.OK`
- Call `stmt:finalize()` and `db:close()` to clean up

## Common Patterns

### Fetch with Retry

```teal
local fetch = require("cosmic.fetch")

local result = fetch.Fetch(url, {
  max_attempts = 3,
  max_delay = 30,
  should_retry = function(r: fetch.Result): boolean
    -- Retry on server errors or rate limiting
    return not r.ok or r.status >= 500 or r.status == 429
  end,
  headers = {
    ["User-Agent"] = "my-app/1.0",
  },
})
```

### Spawn with Stdin

```teal
local spawn = require("cosmic.spawn")

local handle = spawn.spawn({"cat"}, {
  stdin = "Hello from stdin!",
})
local ok, output = handle:read()
print(output)  -- "Hello from stdin!"
```

### Walk Directory with Custom Logic

```teal
local walk = require("cosmic.walk")
local unix = require("cosmo.unix")

walk.walk(".", function(path: string, name: string, stat: any, ctx: any): boolean
  if unix.S_ISDIR(stat:mode()) then
    print("Directory:", path)
    return true  -- Continue recursing
  else
    print("File:", path, "size:", stat:size())
    return true
  end
end)
```

### Database Transaction

```teal
local lsqlite3 = require("cosmo.lsqlite3")

local db = lsqlite3.open("data.db")

-- Start transaction
db:exec("BEGIN TRANSACTION")

-- Do multiple operations
local stmt = db:prepare("INSERT INTO items (name) VALUES (?)")
for i = 1, 100 do
  stmt:bind_values("Item " .. tostring(i))
  stmt:step()
  stmt:reset()
end
stmt:finalize()

-- Commit
db:exec("COMMIT")
db:close()
```

## Command-Line Argument Parsing

```teal
local cosmic = require("cosmic")
local getopt = require("cosmo.getopt")

cosmic.main(function(args: {string}, env: cosmic.Env): number, string
  local verbose = false
  local output_file: string = nil

  local parser = getopt.new(args, "vo:", {
    {"verbose", "none", "v"},
    {"output", "required", "o"},
  })

  while true do
    local opt, arg = parser:next()
    if not opt then break end

    if opt == "v" or opt == "verbose" then
      verbose = true
    elseif opt == "o" or opt == "output" then
      output_file = arg
    end
  end

  local remaining = parser:remaining()

  if verbose then
    env.stderr:write("Verbose mode enabled\n")
    env.stderr:write("Remaining args: " .. table.concat(remaining, ", ") .. "\n")
  end

  return 0
end)
```

Run it:

```bash
./cosmic-lua args.tl -v -o output.txt file1 file2
# Verbose mode enabled
# Remaining args: file1, file2
```

## File Operations

```teal
local unix = require("cosmo.unix")
local path = require("cosmo.path")

-- Check if file exists
local stat = unix.stat("/path/to/file")
if stat then
  if unix.S_ISDIR(stat:mode()) then
    print("It's a directory")
  else
    print("It's a file")
    print("Size:", stat:size())
    print("Modified:", stat:mtim())
  end
end

-- Get current directory
local cwd = unix.getcwd()
print("Current directory:", cwd)

-- Join paths
local full_path = path.join(cwd, "subdir", "file.txt")
print("Full path:", full_path)

-- Get parent directory
local parent = path.dirname(full_path)
print("Parent:", parent)
```

## Next Steps

1. **Read the API Reference** - See `API-REFERENCE.md` for complete module documentation
2. **Explore Examples** - Check the `examples/` directory for complete programs
3. **Read Module Docs** - Run `./cosmic-lua --docs <module>` for detailed documentation
4. **Try the Tutorial** - Work through `TUTORIAL.md` for hands-on exercises
5. **Build Something** - Create your own cosmic-lua program!

## Where to Get Help

- **Documentation**: See README.md and API-REFERENCE.md
- **Examples**: Check the `examples/` directory
- **Source Code**: Read `lib/cosmic/*.tl` for implementation details
- **Tests**: Look at `lib/cosmic/*_test.tl` for usage examples
- **Issues**: https://github.com/whilp/cosmic/issues

## Quick Reference Card

| Task | Module | Function |
|------|--------|----------|
| Fetch URL | cosmic.fetch | `fetch.Fetch(url, opts?)` |
| Run command | cosmic.spawn | `spawn.spawn(argv, opts?)` |
| Find files | cosmic.walk | `walk.collect(dir, pattern)` |
| Walk directory | cosmic.walk | `walk.walk(dir, visitor, ctx?)` |
| Parse CLI args | cosmo.getopt | `getopt.new(args, short, long)` |
| SQLite database | cosmo.lsqlite3 | `lsqlite3.open(path)` |
| File info | cosmo.unix | `unix.stat(path)` |
| Join paths | cosmo.path | `path.join(...)` |
| Current time | cosmo.unix | `unix.clock_gettime(unix.CLOCK_REALTIME)` |

## Teal Type Checking

cosmic-lua includes full Teal support. Check your programs:

```bash
./cosmic-lua /zip/tl.lua check myprogram.tl
```

This catches type errors before runtime!

## Tips for Success

1. **Always check return values** - Most functions return `nil` or `false` on error
2. **Use type annotations** - Teal's type checking catches bugs early
3. **Read the source** - The `lib/cosmic/*.tl` files are well-documented
4. **Start simple** - Master one module at a time
5. **Use the REPL** - Run `./cosmic-lua` with no args for interactive mode

Happy coding with cosmic-lua! 🚀
