# embed

 Embed files into cosmic executable.
 Creates a copy of the cosmic executable with files appended as a zip archive.

## Types

### EmbedResult

 Result returned from embed operation.

```teal
local record EmbedResult
  ok: boolean
  message: string
  file_count: integer
end
```

### FileToEmbed

```teal
local record FileToEmbed
  path: string
  content: string
  stored_name: string
end
```

### EmbedModule

```teal
local record EmbedModule
  run: function(files: {string}, output?: string, exe_path?: string): EmbedResult
end
```

## Functions

### run

```teal
function run(files: {string}, output?: string, exe_path?: string): EmbedResult
```

 Embed files into a copy of the cosmic executable.
 Creates a new executable with files appended as a zip archive.
 The original executable is copied and files are added to the end as a zip.

**Parameters:**

- `files` ({string}) - List of file paths to embed
- `output` (string) - Output path for the new executable (defaults to "cosmic")
- `exe_path` (string) - Path to the executable to copy (defaults to arg[-1])

**Returns:**

- EmbedResult - Result with ok status, message, and file count
