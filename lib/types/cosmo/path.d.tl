--- Path manipulation utilities.
--- The path module provides functions for manipulating UNIX-style paths.

local record path
  --- Joins path components into a single path.
  ---
  --- Concatenates path components intelligently, handling slashes appropriately:
  --- - `/usr` + `lib` = `/usr/lib`
  --- - `/usr/` + `lib` = `/usr/lib`
  --- - `/usr/lib` + `/lib` = `/lib` (absolute path takes precedence)
  ---
  --- You may specify 1 or more arguments. If `nil` arguments are specified,
  --- they're skipped. Empty strings behave similarly to `nil`, but may
  --- coerce a trailing slash.
  ---
  --- Example:
  ---
  ---     local path = require("cosmo.path")
  ---     assert(path.join("/usr", "local", "bin") == "/usr/local/bin")
  ---
  --- @return string The joined path
  join: function(...: string): string

  --- Strips final component of path.
  ---
  --- Returns the directory component of a path:
  --- - `.` returns `.`
  --- - `..` returns `.`
  --- - `/` returns `/`
  --- - `usr` returns `.`
  --- - `/usr/` returns `/`
  --- - `/usr/lib` returns `/usr`
  --- - `/usr/lib/` returns `/usr`
  ---
  --- @param p string The path to process
  --- @return string The directory component
  dirname: function(p: string): string

  --- Returns final component of path.
  ---
  --- Extracts the filename component from a path:
  --- - `.` returns `.`
  --- - `..` returns `..`
  --- - `/` returns `/`
  --- - `usr` returns `usr`
  --- - `/usr/` returns `usr`
  --- - `/usr/lib` returns `lib`
  --- - `/usr/lib/` returns `lib`
  ---
  --- @param p string The path to process
  --- @return string The filename component
  basename: function(p: string): string

  --- Returns `true` if path exists.
  ---
  --- This function is inclusive of regular files, directories, and special files.
  --- Symbolic links are followed and resolved. On error, `false` is returned.
  ---
  --- @param p string The path to check
  --- @return boolean `true` if the path exists
  exists: function(p: string): boolean
end

return path
