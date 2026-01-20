-- type declarations for cosmo.path

local record path
  dirname: function(str: string): string
  basename: function(str: string): string
  join: function(str?: string, ...: string): string
  exists: function(path: string): boolean
  isfile: function(path: string): boolean
  isdir: function(path: string): boolean
  islink: function(path: string): boolean
end

return path

