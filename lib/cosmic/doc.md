# doc

 Extract documentation from Teal files and render as markdown.
 Parses doc comments, records, functions, and examples from .tl files.

## Types

### Param

 A function parameter with type and description.

```teal
local record Param
  name: string
  param_type: string
  description: string
end
```

### Return

 A function return value with type and description.

```teal
local record Return
  return_type: string
  description: string
end
```

### FunctionDoc

 Documentation for a function.

```teal
local record FunctionDoc
  name: string
  description: string
  params: {Param}
  returns: {Return}
  signature: string
  line: integer
  is_local: boolean
end
```

### RecordDoc

 Documentation for a record type.

```teal
local record RecordDoc
  name: string
  description: string
  fields: {{string, string, string}}
  line: integer
end
```

### ExampleDoc

 Documentation for an example function.

```teal
local record ExampleDoc
  name: string
  description: string
  body: string
  expected_output: string
  line: integer
end
```

### ModuleDoc

 Complete documentation for a module.

```teal
local record ModuleDoc
  file: string
  module_doc: string
  functions: {FunctionDoc}
  records: {RecordDoc}
  examples: {ExampleDoc}
end
```

### DocModule

```teal
local record DocModule
  parse: function(source: string, file_path: string): ModuleDoc
  render: function(doc: ModuleDoc): string
  render_file: function(file_path: string): boolean, string
end
```
