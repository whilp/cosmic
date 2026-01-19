--- Directory tree walking utilities.
--- Recursively traverse directories with visitor pattern or glob matching.
local unix = require("cosmo.unix")
local path = require("cosmo.path")

--- File or directory metadata.
local record Stat
  mode: function(self): number
  size: function(self): number
  mtim: function(self): number
end

--- Handle for reading directory entries.
local record DirHandle
  read: function(self): string
  close: function(self)
end

--- File information with Unix permissions.
local record FileInfo
  mode: number
end

--- Visitor function type for directory traversal.
--- Return false to skip recursion into subdirectories.
--- @param full_path string The complete path to the file or directory
--- @param entry string The basename of the file or directory
--- @param stat Stat File metadata
--- @param ctx any User-provided context passed through the walk
--- @return boolean Return false to skip recursing into this directory
local type Visitor = function(full_path: string, entry: string, stat: Stat, ctx: any): boolean

--- Walk a directory tree, calling visitor for each entry.
--- Recursively traverses subdirectories unless visitor returns false.
--- @param dir string The directory to walk
--- @param visitor Visitor Function called for each file and directory
--- @param ctx T Optional context passed to visitor function
--- @return T The context object, potentially modified by visitor
local function walk<T>(dir: string, visitor: Visitor, ctx?: T): T
  ctx = ctx or {} as T
  local handle = unix.opendir(dir) as DirHandle
  if not handle then return ctx end

  while true do
    local entry = handle:read()
    if not entry then break end
    if entry ~= "." and entry ~= ".." then
      local full_path = path.join(dir, entry)
      local stat = unix.stat(full_path) as Stat
      if stat then
        local continue = visitor(full_path, entry, stat, ctx)
        if continue ~= false and unix.S_ISDIR(stat:mode()) then
          walk(full_path, visitor, ctx)
        end
      end
    end
  end
  handle:close()
  return ctx
end

--- Collect file paths matching a Lua pattern.
--- Recursively walks directory tree and returns matching file paths.
--- @param dir string The directory to search
--- @param pattern string Lua pattern to match against file basenames
--- @return {string} List of full paths to matching files
local function collect(dir: string, pattern: string): {string}
  local results: {string} = {}
  walk(dir, function(full_path: string, entry: string, stat: Stat, ctx: {string}): boolean
    if not unix.S_ISDIR(stat:mode()) and entry:match(pattern) then
      table.insert(ctx, full_path)
    end
    return true
  end, results)
  return results
end

--- Recursively collect all files with their Unix permissions.
--- Returns a map of relative paths to file information.
--- @param dir string The directory to walk
--- @param base string Internal: relative path prefix (used during recursion)
--- @param files {string:FileInfo} Internal: accumulator map (used during recursion)
--- @return {string:FileInfo} Map of relative paths to file information
local function collect_all(dir: string, base?: string, files?: {string:FileInfo}): {string:FileInfo}
  files = files or {}
  base = base or ""

  local handle = unix.opendir(dir) as DirHandle
  if not handle then return files end

  while true do
    local entry = handle:read()
    if not entry then break end
    if entry ~= "." and entry ~= ".." then
      local full_path = path.join(dir, entry)
      local rel_path = base == "" and entry or path.join(base, entry)
      local stat = unix.stat(full_path) as Stat

      if stat then
        if unix.S_ISDIR(stat:mode()) then
          collect_all(full_path, rel_path, files)
        elseif unix.S_ISREG(stat:mode()) or unix.S_ISLNK(stat:mode()) then
          local mode = stat:mode() & 0x1ff
          files[rel_path] = { mode = mode }
        end
      end
    end
  end
  handle:close()
  return files
end

local record WalkModule
  walk: function<T>(dir: string, visitor: Visitor, ctx?: T): T
  collect: function(dir: string, pattern: string): {string}
  collect_all: function(dir: string, base?: string, files?: {string:FileInfo}): {string:FileInfo}
end

local M: WalkModule = {
  walk = walk,
  collect = collect,
  collect_all = collect_all,
}

return M
