-- cosmic.docs: access bundled documentation
--
-- Provides programmatic access to documentation bundled in the cosmic-lua
-- binary. Documentation is stored in /zip/.lua/docs/ within the binary.
--
-- Usage:
--   local docs = require("cosmic.docs")
--   local content = docs.get("modules/cosmic.spawn.txt")
--   print(content)

local cosmo = require("cosmo")
local unix = require("cosmo.unix")
local path = require("cosmo.path")

local record SearchResult
  path: string
  line: number
  text: string
end

local record docs
  -- Get documentation content by path
  get: function(doc_path: string): string, string

  -- List all available documentation files
  list: function(): {string}

  -- Search documentation content for query string
  search: function(query: string): {SearchResult}

  -- Extract all documentation to a directory
  extract_all: function(dest_dir: string): boolean, string

  -- Check if documentation exists
  exists: function(doc_path: string): boolean

  -- Get documentation base path
  base_path: function(): string
end

local DOC_BASE = "/zip/.lua/docs"

-- Get documentation content by path
local function get(doc_path: string): string, string
  local full_path = path.join(DOC_BASE, doc_path)

  -- Check if file exists
  local stat = unix.stat(full_path)
  if not stat or not unix.S_ISREG(stat:mode()) then
    return nil, "documentation not found: " .. doc_path
  end

  -- Try to read the file
  local ok, content = pcall(cosmo.Slurp, full_path)
  if not ok then
    return nil, "failed to read documentation: " .. doc_path
  end

  return content
end

-- Check if documentation exists
local function exists(doc_path: string): boolean
  local full_path = path.join(DOC_BASE, doc_path)
  local stat = unix.stat(full_path)
  return stat ~= nil and unix.S_ISREG(stat:mode())
end

-- List all available documentation files
local function list(): {string}
  local results: {string} = {}

  -- Check if docs directory exists
  local stat = unix.stat(DOC_BASE)
  if not stat or not unix.S_ISDIR(stat:mode()) then
    return results
  end

  -- Walk the docs directory recursively
  local function walk_docs(dir: string, base: string)
    local handle = unix.opendir(dir)
    if not handle then return end

    while true do
      local entry = handle:read()
      if not entry then break end

      if entry ~= "." and entry ~= ".." then
        local full_path = path.join(dir, entry)
        local rel_path = base == "" and entry or path.join(base, entry)
        local entry_stat = unix.stat(full_path)

        if entry_stat then
          if unix.S_ISDIR(entry_stat:mode()) then
            walk_docs(full_path, rel_path)
          elseif unix.S_ISREG(entry_stat:mode()) then
            table.insert(results, rel_path)
          end
        end
      end
    end
    handle:close()
  end

  walk_docs(DOC_BASE, "")
  table.sort(results)
  return results
end

-- Search documentation content for query string
local function search(query: string): {SearchResult}
  local results: {SearchResult} = {}
  local query_lower = query:lower()

  for _, doc_path in ipairs(list()) do
    local content = get(doc_path)
    if content then
      local line_num = 0
      for line in content:gmatch("[^\n]*") do
        line_num = line_num + 1
        if line:lower():find(query_lower, 1, true) then
          table.insert(results, {
            path = doc_path,
            line = line_num,
            text = line:match("^%s*(.-)%s*$") or line  -- Trim whitespace
          })
        end
      end
    end
  end

  return results
end

-- Extract all documentation to a directory
local function extract_all(dest_dir: string): boolean, string
  -- Create destination directory
  local ok, err = unix.makedirs(dest_dir)
  if not ok then
    return nil, "failed to create directory: " .. dest_dir .. " (" .. (err or "unknown error") .. ")"
  end

  local extracted = 0
  for _, doc_path in ipairs(list()) do
    local content = get(doc_path)
    if content then
      local dest_path = path.join(dest_dir, doc_path)

      -- Create parent directories
      local dir = dest_path:match("(.+)/[^/]+$")
      if dir then
        unix.makedirs(dir)
      end

      -- Write file
      local write_ok = cosmo.Barf(dest_path, content)
      if write_ok then
        extracted = extracted + 1
      end
    end
  end

  if extracted == 0 then
    return nil, "no documentation files found to extract"
  end

  return true
end

-- Get documentation base path
local function base_path(): string
  return DOC_BASE
end

local M: docs = {
  get = get,
  list = list,
  search = search,
  extract_all = extract_all,
  exists = exists,
  base_path = base_path,
}

return M
