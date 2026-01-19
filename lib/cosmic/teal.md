# teal

 Teal compilation and type-checking.
 --compile uses lax mode for permissive compilation.
 --check uses strict mode for thorough type checking.

## Types

### Issue

 A compiler or type checker issue.

```teal
local record Issue
  file: string
  line: integer
  column: integer
  message: string
  severity: string
end
```

### CompileOpts

 Options for compiling Teal to Lua.

```teal
local record CompileOpts
  include_dirs: {string}
  gen_target: string
  gen_compat: string
end
```

### CheckOpts

 Options for type-checking Teal files.

```teal
local record CheckOpts
  include_dirs: {string}
end
```

### CompileResult

 Result from compiling a Teal file.

```teal
local record CompileResult
  ok: boolean
  code: string
  errors: {Issue}
end
```

### CheckResult

 Result from type-checking a Teal file.

```teal
local record CheckResult
  ok: boolean
  warnings: {Issue}
  errors: {Issue}
end
```

### TlError

 Error from the Teal compiler.

```teal
local record TlError
  msg: string
  filename: string
  y: integer
  x: integer
end
```

### TlResult

 Result from Teal's process_string function.

```teal
local record TlResult
  syntax_errors: {TlError}
  type_errors: {TlError}
  warnings: {TlError}
  ast: any
end
```

### ProcessResult

 Internal result from processing a Teal file.

```teal
local record ProcessResult
  tl_result: TlResult
  shebang: string
  error: Issue
end
```

### TealModule

```teal
local record TealModule
  compile: function(input_path: string, opts?: CompileOpts): CompileResult
  check: function(input_path: string, opts?: CheckOpts): CheckResult
  format_issues: function(issues: {Issue}): string
  get_default_include_dirs: function(): {string}
end
```
