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
