--- Access embedded documentation from the cosmic binary.
--- Provides a CLI interface similar to Go's `go doc` command.
--- Documentation is embedded in the binary at build time under /zip/.docs/

local cosmo = require("cosmo")
local path_mod = require("cosmo.path")
local walk = require("cosmic.walk")

--- A documentation topic (module or symbol).
local record Topic
  name: string
  path: string
  description: string
end

--- Result from a docs operation.
local record DocsResult
  ok: boolean
  output: string
end

local DOCS_PATH = "/zip/.docs"

--- Check if embedded docs are available.
--- @return boolean True if docs are embedded
local function has_docs(): boolean
  -- Try to collect any markdown files from the docs directory
  local files = walk.collect(DOCS_PATH, "%.md$")
  return #files > 0
end

--- List all markdown files recursively under the docs directory.
--- @param dir string Directory to scan
--- @return {string} List of file paths relative to DOCS_PATH
local function list_docs_recursive(dir: string): {string}
  local results: {string} = {}

  -- Use walk.collect to find all .md files
  local full_paths = walk.collect(DOCS_PATH, "%.md$")

  for _, full_path in ipairs(full_paths) do
    -- Convert absolute path to relative path from DOCS_PATH
    local rel_path = full_path:sub(#DOCS_PATH + 2)  -- +2 to skip the trailing /
    if rel_path ~= "README.md" then
      table.insert(results, rel_path)
    end
  end

  return results
end

--- Extract module name from a doc file path.
--- Converts paths like "lib/cosmic/doc.md" or "cosmo/path.md" to "cosmic.doc" or "cosmo.path"
--- @param file_path string Path to the markdown file
--- @return string Module name in dot notation
local function path_to_module(file_path: string): string
  -- Remove .md extension
  local name = file_path:gsub("%.md$", "")

  -- Handle lib/cosmic/foo -> cosmic.foo
  name = name:gsub("^lib/", "")

  -- Handle lib/docs/foo -> docs.foo
  name = name:gsub("^docs/", "")

  -- Handle lib/types/foo -> types.foo
  name = name:gsub("^types/", "")

  -- Convert / to .
  name = name:gsub("/", ".")

  return name
end

--- Extract the first paragraph (description) from markdown content.
--- @param content string Markdown content
--- @return string First paragraph after the header
local function extract_description(content: string): string
  -- Skip the header line and any blank lines
  local lines: {string} = {}
  local in_paragraph = false
  local past_header = false

  for line in content:gmatch("[^\n]*") do
    if not past_header then
      if line:match("^#") then
        past_header = true
      end
    elseif in_paragraph then
      if line:match("^%s*$") then
        break
      else
        table.insert(lines, line)
      end
    elseif not line:match("^%s*$") and not line:match("^#") then
      in_paragraph = true
      table.insert(lines, line)
    end
  end

  local desc = table.concat(lines, " "):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
  -- Truncate if too long
  if #desc > 80 then
    desc = desc:sub(1, 77) .. "..."
  end
  return desc
end

--- List all available documentation topics.
--- @return {Topic} List of available topics
local function list_topics(): {Topic}
  local topics: {Topic} = {}

  local files = list_docs_recursive(DOCS_PATH)
  for _, file in ipairs(files) do
    local full_path = DOCS_PATH .. "/" .. file
    local content = cosmo.Slurp(full_path)
    local module_name = path_to_module(file)
    local description = ""

    if content then
      description = extract_description(content)
    end

    table.insert(topics, {
      name = module_name,
      path = file,
      description = description,
    })
  end

  -- Sort topics by name
  table.sort(topics, function(a: Topic, b: Topic): boolean
    return a.name < b.name
  end)

  return topics
end

--- Format the topic list for display.
--- @param topics {Topic} List of topics
--- @return string Formatted output
local function format_topic_list(topics: {Topic}): string
  local lines: {string} = {}

  table.insert(lines, "cosmic documentation")
  table.insert(lines, "")
  table.insert(lines, "Modules:")

  -- Find the longest module name for alignment
  local max_len = 0
  for _, topic in ipairs(topics) do
    if #topic.name > max_len then
      max_len = #topic.name
    end
  end

  for _, topic in ipairs(topics) do
    local padding = string.rep(" ", max_len - #topic.name + 2)
    table.insert(lines, "  " .. topic.name .. padding .. topic.description)
  end

  table.insert(lines, "")
  table.insert(lines, "Use 'cosmic --docs <module>' for more information about a module.")
  table.insert(lines, "Use 'cosmic --docs <module>.<symbol>' for information about a specific function or type.")

  return table.concat(lines, "\n")
end

--- Find the doc file path for a module name.
--- @param module_name string Module name in dot notation (e.g., "cosmo.path")
--- @return string Full path to the doc file, or nil if not found
local function find_doc_file(module_name: string): string
  local topics = list_topics()

  for _, topic in ipairs(topics) do
    if topic.name == module_name then
      return DOCS_PATH .. "/" .. topic.path
    end
  end

  return nil
end

--- Extract a specific section from markdown content.
--- @param content string Full markdown content
--- @param symbol string Symbol name to find (function, type, etc.)
--- @return string Section content or nil if not found
local function extract_section(content: string, symbol: string): string
  local lines: {string} = {}
  local in_section = false
  local section_level = 0

  for line in content:gmatch("[^\n]*") do
    if in_section then
      -- Check if we hit another section of same or higher level
      local level = line:match("^(#+)")
      if level and #level <= section_level then
        break
      end
      table.insert(lines, line)
    else
      -- Look for section header matching the symbol
      local level, header = line:match("^(#+)%s*(.+)$")
      if level and header then
        -- Clean up header (remove backticks, etc.)
        local clean_header = header:gsub("`", ""):gsub("^%s+", ""):gsub("%s+$", "")
        if clean_header:lower() == symbol:lower() or clean_header == symbol then
          in_section = true
          section_level = #level
          table.insert(lines, line)
        end
      end
    end
  end

  if #lines == 0 then
    return nil
  end

  return table.concat(lines, "\n")
end

--- Show documentation for a module.
--- @param module_name string Module name in dot notation
--- @return DocsResult Result with documentation content
local function show_module(module_name: string): DocsResult
  local doc_path = find_doc_file(module_name)

  if not doc_path then
    return {
      ok = false,
      output = "error: documentation not found for '" .. module_name .. "'\n" ..
               "Use 'cosmic --docs' to see available modules.",
    }
  end

  local content = cosmo.Slurp(doc_path)
  if not content then
    return {
      ok = false,
      output = "error: failed to read documentation file",
    }
  end

  return {
    ok = true,
    output = content,
  }
end

--- Show documentation for a specific symbol within a module.
--- @param module_name string Module name in dot notation
--- @param symbol string Symbol name (function, type, etc.)
--- @return DocsResult Result with documentation content
local function show_symbol(module_name: string, symbol: string): DocsResult
  local doc_path = find_doc_file(module_name)

  if not doc_path then
    return {
      ok = false,
      output = "error: documentation not found for '" .. module_name .. "'\n" ..
               "Use 'cosmic --docs' to see available modules.",
    }
  end

  local content = cosmo.Slurp(doc_path)
  if not content then
    return {
      ok = false,
      output = "error: failed to read documentation file",
    }
  end

  local section = extract_section(content, symbol)
  if not section then
    return {
      ok = false,
      output = "error: symbol '" .. symbol .. "' not found in module '" .. module_name .. "'\n" ..
               "Use 'cosmic --docs " .. module_name .. "' to see available symbols.",
    }
  end

  return {
    ok = true,
    output = section,
  }
end

--- Main entry point for the docs command.
--- @param query string Optional query string (module or module.symbol)
--- @return DocsResult Result with documentation content
local function run(query?: string): DocsResult
  -- Check if docs are available
  if not has_docs() then
    return {
      ok = false,
      output = "error: no documentation embedded in this binary\n" ..
               "Build cosmic with 'make cosmic-docs' to include documentation.",
    }
  end

  -- No query: list all topics
  if not query or query == "" then
    local topics = list_topics()
    if #topics == 0 then
      return {
        ok = false,
        output = "error: no documentation found",
      }
    end
    return {
      ok = true,
      output = format_topic_list(topics),
    }
  end

  -- Parse query: module or module.symbol
  -- Handle cases like "cosmo.path" (module) vs "cosmo.path.basename" (module.symbol)
  -- We need to try progressively shorter module names
  local parts: {string} = {}
  for part in query:gmatch("[^%.]+") do
    table.insert(parts, part)
  end

  -- Try full query as module name first
  local doc_path = find_doc_file(query)
  if doc_path then
    return show_module(query)
  end

  -- Try module.symbol pattern (last part is symbol)
  if #parts >= 2 then
    local symbol = parts[#parts]
    local module_parts: {string} = {}
    for i = 1, #parts - 1 do
      table.insert(module_parts, parts[i])
    end
    local module_name = table.concat(module_parts, ".")

    doc_path = find_doc_file(module_name)
    if doc_path then
      return show_symbol(module_name, symbol)
    end
  end

  -- Nothing found
  return {
    ok = false,
    output = "error: documentation not found for '" .. query .. "'\n" ..
             "Use 'cosmic --docs' to see available modules.",
  }
end

local record DocsModule
  run: function(query?: string): DocsResult
  has_docs: function(): boolean
  list_topics: function(): {Topic}
end

local M: DocsModule = {
  run = run,
  has_docs = has_docs,
  list_topics = list_topics,
}

return M
