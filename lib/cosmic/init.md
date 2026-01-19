# init

 Cosmopolitan Lua utilities.
 Main entry point and utilities for cosmic modules.

## Types

### Env

 Environment with standard output and error streams.

```teal
local record Env
  stdout: FILE
  stderr: FILE
end
```

### cosmic

```teal
local record cosmic
  _VERSION: string
  _DESCRIPTION: string
  main: function(fn: MainFn)
end
```
