-- type declarations for cosmo.maxmind

local record Db
  lookup: function(self: Db, ip: number): Result
end

local record Result
  get: function(self: Result): any
  netmask: function(self: Result): number
end

local record maxmind
  open: function(filepath: string): Db
end

return maxmind

