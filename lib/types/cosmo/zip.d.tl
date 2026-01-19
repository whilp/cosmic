-- Type definitions for cosmo.zip module

local record ZipAppender
  add: function(self: ZipAppender, name: string, content: string): boolean, string
  close: function(self: ZipAppender)
end

local record ZipStat
  size: integer
  compressed_size: integer
  crc32: integer
  mtime: integer
  method: integer
  mode: integer
end

local record ZipReader
  list: function(self: ZipReader): {string}
  stat: function(self: ZipReader, name: string): ZipStat
  read: function(self: ZipReader, name: string): string
  close: function(self: ZipReader)
end

local record zip
  open: function(path: string, mode: string): ZipAppender, string
  from: function(data: string): ZipReader, string
end

return zip
