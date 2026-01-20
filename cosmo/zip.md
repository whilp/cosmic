# zip

## Types

### ZipAppender

 Writer for adding files to a ZIP archive.

```teal
local record ZipAppender
  --  Add a file to the ZIP archive.
  add: function(self: ZipAppender, name: string, content: string): boolean, string
  --  Close the ZIP archive and finalize all entries.
  close: function(self: ZipAppender)
end
```

### ZipStat

 File metadata within a ZIP archive.

```teal
local record ZipStat
  --  Uncompressed file size in bytes.
  size: number
  --  Compressed file size in bytes.
  compressed_size: number
  --  CRC32 checksum of uncompressed data.
  crc32: number
  --  Modification time as Unix timestamp.
  mtime: number
  --  Compression method (0=stored, 8=deflated).
  method: number
  --  Unix file mode/permissions.
  mode: number
end
```

### ZipReader

 Reader for extracting files from a ZIP archive.

```teal
local record ZipReader
  --  List all files in the ZIP archive.
  list: function(self: ZipReader): {string}
  --  Get metadata for a specific file in the archive.
  stat: function(self: ZipReader, name: string): ZipStat
  --  Read the contents of a file from the archive.
  read: function(self: ZipReader, name: string): string
  --  Close the ZIP reader and release resources.
  close: function(self: ZipReader)
end
```

## Functions

### open

```teal
function open(path: string, mode: string): ZipAppender, string
```

 Open a ZIP archive for reading or writing.
 For writing, creates a new archive or appends to an existing one.
 Example - Creating a ZIP archive:
     local zip = require("cosmo.zip")
     local archive = assert(zip.open("output.zip", "w"))
     archive:add("hello.txt", "Hello, World!")
     archive:add("data/config.json", '{"key": "value"}')
     archive:close()
 Example - Reading a ZIP archive:
     local archive = assert(zip.from(io.open("input.zip", "rb"):read("*a")))
     local files = archive:list()
     for _, name in ipairs(files) do
       local content = archive:read(name)
       print(name, #content)
     end
     archive:close()

**Parameters:**

- `path` (string) - Path to the ZIP file
- `mode` (string) - Open mode: "r" for reading, "w" for writing, "a" for appending

**Returns:**

- ZipAppender|nil - appender ZIP writer object on success
- string|nil - error Error message on failure

### from

```teal
function from(data: string): ZipReader, string
```

 Open a ZIP archive from in-memory data.

**Parameters:**

- `data` (string) - ZIP file contents as a string

**Returns:**

- ZipReader|nil - reader ZIP reader object on success
- string|nil - error Error message on failure
