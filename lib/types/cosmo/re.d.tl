-- type declarations for cosmo.re

local record Errno
  errno: function(self: Errno): number
  doc: function(self: Errno): string
  __tostring: function(self: Errno): string
end

local record Regex
  search: function(self: Regex, str: string, flags?: number): string
end

local record re
  NOMATCH: number
  BADPAT: number
  ECOLLATE: number
  ECTYPE: number
  EESCAPE: number
  ESUBREG: number
  EBRACK: number
  EPAREN: number

  search: function(regex: string, text: string, flags?: number): string
  compile: function(regex: string, flags?: number): Regex
end

return re

