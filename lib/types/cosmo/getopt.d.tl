-- type declarations for cosmo.getopt

local record parser
  next: function(self: parser): string, string
  remaining: function(self: parser): {string}
  unknown: function(self: parser): {string}
end

local record getopt
  new: function(args: {string}, optstring: string, longopts?: {table}): parser
end

return getopt

