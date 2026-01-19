# fetch

 Structured HTTP fetch with optional retry.
 Wraps cosmo.Fetch with structured results to prevent accidentally discarding errors.

## Types

### Result

 Result from a fetch operation.

```teal
local record Result
  ok: boolean
  status: number
  headers: {string:string}
  body: string
  error: string
end
```

### Opts

```teal
local record Opts
  headers: {string:string}
  maxresponse: number
  max_attempts: number
  max_delay: number
  should_retry: function(Result): boolean
end
```

### fetch

```teal
local record fetch
  Fetch: function(url: string, opts?: Opts): Result
  Opts: Opts
  Result: Result
end
```
