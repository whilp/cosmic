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

### RecordName

### DocModule

```teal
local record DocModule
  parse: function(source: string, file_path: string): ModuleDoc
  parse_dtl: function(source: string, file_path: string): ModuleDoc
  render: function(doc: ModuleDoc): string
  render_file: function(file_path: string): boolean, string
  render_dtl_file: function(file_path: string): boolean, string
end
```

## Functions

### parse

```teal
function parse(source: string, file_path: string): ModuleDoc
```

 Parse a .tl file and extract documentation.
 Extracts module docs, records, functions, and examples from source code.

**Parameters:**

- `source` (string) - The source code to parse
- `file_path` (string) - Path to the file being parsed

**Returns:**

- ModuleDoc - Complete documentation for the module

### render

```teal
function render(doc: ModuleDoc): string
```

 Render documentation as markdown.
 Converts parsed documentation into formatted markdown with sections for types, functions, and examples.

**Parameters:**

- `doc` (ModuleDoc) - The documentation to render

**Returns:**

- string - Formatted markdown documentation

### parse_dtl

```teal
function parse_dtl(source: string, file_path: string): ModuleDoc
```

 Parse a .d.tl type declaration file and extract documentation.
 Extracts records, their fields, methods, and documentation comments.

**Parameters:**

- `source` (string) - The source code to parse
- `file_path` (string) - Path to the file being parsed

**Returns:**

- ModuleDoc - Complete documentation for the module

### render_file

```teal
function render_file(file_path: string): boolean, string
```

 Main entry point: parse file and render markdown.
 Reads a Teal file, extracts documentation, and renders it as markdown.

**Parameters:**

- `file_path` (string) - Path to the Teal file to document

**Returns:**

- boolean - Success status
- string - Markdown documentation on success, error message on failure

### render_dtl_file

```teal
function render_dtl_file(file_path: string): boolean, string
```

 Main entry point for .d.tl files: parse and render markdown.
 Reads a Teal type declaration file and renders documentation as markdown.

**Parameters:**

- `file_path` (string) - Path to the .d.tl file to document

**Returns:**

- boolean - Success status
- string - Markdown documentation on success, error message on failure
