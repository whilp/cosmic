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

### pipe:read

### handle:wait

### handle:read

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
