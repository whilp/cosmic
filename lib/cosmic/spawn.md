# spawn

 Process spawning utilities.
 Spawn external processes with control over stdin, stdout, and stderr.

## Types

### Pipe

 Pipe for reading/writing process I/O.

### SpawnHandle

 Handle for a spawned process.

### SpawnOpts

 Options for spawning a process.

### SpawnModule

## Functions

### pipe:write

```teal
function pipe:write(data: string): number
```

 Write data to the pipe.

**Parameters:**

- `data` (string) - The data to write

**Returns:**

- number - The number of bytes written

### pipe:read

```teal
function pipe:read(size?: number): string
```

 Read data from the pipe.
 If size is provided, reads up to that many bytes. Otherwise, reads until EOF.

**Parameters:**

- `size` (number) - Optional number of bytes to read

**Returns:**

- string - The data read from the pipe

### handle:wait

```teal
function handle:wait(): number, string
```

 Wait for the process to exit and return its exit code.
 Closes stdin and reads/closes stdout and stderr before waiting.

**Returns:**

- number - The exit code if the process exited normally
- string - Error message if the process terminated abnormally

### handle:read

```teal
function handle:read(size?: number): boolean | string, string, number
```

 Read output from the process.
 If size is specified, reads that many bytes and returns the data as a string.
 If size is not specified, reads all output, waits for process to exit, and returns
 success status, output, and exit code.

**Parameters:**

- `size` (number) - Optional number of bytes to read

**Returns:**

- boolean|string - Success status (true if exit code is 0) or output string if size specified
- string - The stdout output from the process
- number - The exit code of the process

## Examples

### spawn

```teal
  local spawn = require("cosmic.spawn")
  local h = spawn.spawn({"echo", "hello world"})
  local ok, out = h:read()
  print(out)
  -- Output:
  -- hello world
```

Output:
```
hello world

```

### spawn stdin

```teal
  local spawn = require("cosmic.spawn")
  local h = spawn.spawn({"cat"}, {stdin = "hello from stdin"})
  local ok, out = h:read()
  print(out)
  -- Output:
  -- hello from stdin
```

Output:
```
hello from stdin

```

### spawn exit code

```teal
  local spawn = require("cosmic.spawn")
  local h = spawn.spawn({"sh", "-c", "exit 0"})
  local code = h:wait()
  print("exit code:", code)
  -- Output:
  -- exit code:	0
```

Output:
```
exit code:	0

```
