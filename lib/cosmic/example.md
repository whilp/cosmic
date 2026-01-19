# example

 Go-style executable example testing.
 Parses Example_* functions from Teal files, runs them, and verifies output.

## Types

### Example

 A parsed example function with its expected output.

```teal
local record Example
  name: string
  body: string
  expected_output: string
  line: integer
end
```

### ExampleResult

 Result from running a single example.

```teal
local record ExampleResult
  name: string
  passed: boolean
  expected: string
  actual: string
  error: string
end
```

### RunResult

 Result from running all examples in a file.

```teal
local record RunResult
  exit_code: integer
  results: {ExampleResult}
  error: string
end
```

### ExampleModule

```teal
local record ExampleModule
  run: function(file_path: string): RunResult
  parse_examples: function(source: string): {Example}
  format_results: function(file_path: string, run_result: RunResult): string
end
```
