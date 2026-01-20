--- ZIP archive reading and writing.
--- The zip module provides functionality for creating and reading ZIP archives.

--- Writer for adding files to a ZIP archive.
local record ZipAppender
  --- Add a file to the ZIP archive.
  ---
  --- @param name string The path/filename within the ZIP archive
  --- @param content string The file content to add
  --- @return boolean success `true` on success
  --- @return string|nil error Error message on failure
  add: function(self: ZipAppender, name: string, content: string): boolean, string

  --- Close the ZIP archive and finalize all entries.
  close: function(self: ZipAppender)
end

--- File metadata within a ZIP archive.
local record ZipStat
  --- Uncompressed file size in bytes.
  size: number

  --- Compressed file size in bytes.
  compressed_size: number

  --- CRC32 checksum of uncompressed data.
  crc32: number

  --- Modification time as Unix timestamp.
  mtime: number

  --- Compression method (0=stored, 8=deflated).
  method: number

  --- Unix file mode/permissions.
  mode: number
end

--- Reader for extracting files from a ZIP archive.
local record ZipReader
  --- List all files in the ZIP archive.
  ---
  --- @return {string} files Array of file paths in the archive
  list: function(self: ZipReader): {string}

  --- Get metadata for a specific file in the archive.
  ---
  --- @param name string The file path within the archive
  --- @return ZipStat stat File metadata
  stat: function(self: ZipReader, name: string): ZipStat

  --- Read the contents of a file from the archive.
  ---
  --- @param name string The file path within the archive
  --- @return string content The file contents
  read: function(self: ZipReader, name: string): string

  --- Close the ZIP reader and release resources.
  close: function(self: ZipReader)
end

local record zip
  --- Open a ZIP archive for reading or writing.
  ---
  --- For writing, creates a new archive or appends to an existing one.
  ---
  --- Example - Creating a ZIP archive:
  ---
  ---     local zip = require("cosmo.zip")
  ---     local archive = assert(zip.open("output.zip", "w"))
  ---     archive:add("hello.txt", "Hello, World!")
  ---     archive:add("data/config.json", '{"key": "value"}')
  ---     archive:close()
  ---
  --- Example - Reading a ZIP archive:
  ---
  ---     local archive = assert(zip.from(io.open("input.zip", "rb"):read("*a")))
  ---     local files = archive:list()
  ---     for _, name in ipairs(files) do
  ---       local content = archive:read(name)
  ---       print(name, #content)
  ---     end
  ---     archive:close()
  ---
  --- @param path string Path to the ZIP file
  --- @param mode string Open mode: "r" for reading, "w" for writing, "a" for appending
  --- @return ZipAppender|nil appender ZIP writer object on success
  --- @return string|nil error Error message on failure
  open: function(path: string, mode: string): ZipAppender, string

  --- Open a ZIP archive from in-memory data.
  ---
  --- @param data string ZIP file contents as a string
  --- @return ZipReader|nil reader ZIP reader object on success
  --- @return string|nil error Error message on failure
  from: function(data: string): ZipReader, string
end

return zip
