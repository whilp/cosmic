-- Type definitions for cosmo.zip module

local record ZipAppender
  add: function(self: ZipAppender, name: string, content: string): boolean, string
  close: function(self: ZipAppender)
end

local record ZipReader
  -- Add reader methods as needed
end

local record zip
  open: function(path: string, mode: string): ZipAppender, string
  from: function(data: string): ZipReader, string
end

return zip
