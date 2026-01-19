# walk

 Directory tree walking utilities.
 Recursively traverse directories with visitor pattern or glob matching.

## Types

### Stat

 File or directory metadata.

```teal
local record Stat
  mode: function(self): number
  size: function(self): number
  mtim: function(self): number
end
```

### DirHandle

 Handle for reading directory entries.

```teal
local record DirHandle
  read: function(self): string
  close: function(self)
end
```

### FileInfo

 File information with Unix permissions.

```teal
local record FileInfo
  mode: number
end
```

### WalkModule

```teal
local record WalkModule
  walk: function<T>(dir: string, visitor: Visitor, ctx?: T): T
  collect: function(dir: string, pattern: string): {string}
  collect_all: function(dir: string, base?: string, files?: {string:FileInfo}): {string:FileInfo}
end
```

## Functions

### walk

```teal
function walk(dir: string, visitor: Visitor, ctx?: T): T
```

 Walk a directory tree, calling visitor for each entry.
 Recursively traverses subdirectories unless visitor returns false.

**Parameters:**

- `dir` (string) - The directory to walk
- `visitor` (Visitor) - Function called for each file and directory
- `ctx` (T) - Optional context passed to visitor function

**Returns:**

- T - The context object, potentially modified by visitor

### collect

```teal
function collect(dir: string, pattern: string): {string}
```

 Collect file paths matching a Lua pattern.
 Recursively walks directory tree and returns matching file paths.

**Parameters:**

- `dir` (string) - The directory to search
- `pattern` (string) - Lua pattern to match against file basenames

**Returns:**

- {string} - List of full paths to matching files

### collect_all

```teal
function collect_all(dir: string, base?: string, files?: {string:FileInfo}): {string:FileInfo}
```

 Recursively collect all files with their Unix permissions.
 Returns a map of relative paths to file information.

**Parameters:**

- `dir` (string) - The directory to walk
- `base` (string) - Internal: relative path prefix (used during recursion)
- `files` ({string:FileInfo}) - Internal: accumulator map (used during recursion)

**Returns:**

- {string:FileInfo} - Map of relative paths to file information
