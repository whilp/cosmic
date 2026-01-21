--- Access embedded documentation from the cosmic binary.
--- Provides a CLI interface similar to Go's `go doc` command.
--- Documentation is parsed at build time and embedded as a serialized Lua index.

local cosmo = require("cosmo")

--- A function parameter.
local record Param
  name: string
  param_type: string
  description: string
end

--- A function return value.
local record Return
  return_type: string
  description: string
end

--- Documentation for a function.
local record FunctionDoc
  name: string
  description: string
  params: {Param}
  returns: {Return}
  signature: string
  line: integer
  is_local: boolean
end

--- Documentation for a record type.
local record RecordDoc
  name: string
  description: string
  fields: {{string, string, string}}  -- name, type, description
  line: integer
end

--- Documentation for an example function.
local record ExampleDoc
  name: string
  description: string
  body: string
  expected_output: string
  line: integer
end

--- Complete documentation for a module.
local record ModuleDoc
  file: string
  module_doc: string
  functions: {FunctionDoc}
  records: {RecordDoc}
  examples: {ExampleDoc}
end

--- A documentation index containing all modules.
local record DocIndex
  modules: {string:ModuleDoc}
end

--- Result from a docs operation.
local record DocsResult
  ok: boolean
  output: string
end

local INDEX_PATH = "/zip/.docs/index.lua"

-- Cached index
local cached_index: DocIndex = nil

--- Load the embedded documentation index.
--- @return DocIndex The documentation index, or nil if not available
--- @return string Error message if loading failed
local function load_index(): DocIndex, string
  if cached_index then
    return cached_index, nil
  end

  local source = cosmo.Slurp(INDEX_PATH)
  if not source then
    return nil, "no documentation index embedded"
  end

  local chunk, err = load("return " .. source)
  if not chunk then
    return nil, "failed to parse index: " .. (err or "unknown")
  end

  local ok, result = pcall(chunk)
  if not ok then
    return nil, "failed to load index: " .. tostring(result)
  end

  cached_index = result as DocIndex
  return cached_index, nil
end

--- Check if embedded docs are available.
--- @return boolean True if docs are embedded
local function has_docs(): boolean
  local index, _ = load_index()
  return index ~= nil
end

--- Extract first paragraph from module description.
--- @param text string Full description text
--- @return string First paragraph, truncated if needed
local function first_paragraph(text: string): string
  if not text then return "" end

  -- Take first line or up to first blank line
  local para = text:match("^([^\n]+)")
  if not para then return "" end

  para = para:gsub("^%s+", ""):gsub("%s+$", "")

  if #para > 80 then
    para = para:sub(1, 77) .. "..."
  end

  return para
end

--- List all available documentation topics.
--- @return {{string, string}} List of {name, description} pairs, sorted by name
local function list_topics(): {{string, string}}
  local index, err = load_index()
  if not index then
    return {}
  end

  local topics: {{string, string}} = {}
  for name, doc in pairs(index.modules) do
    local desc = first_paragraph(doc.module_doc)
    table.insert(topics, {name, desc})
  end

  table.sort(topics, function(a: {string, string}, b: {string, string}): boolean
    return a[1] < b[1]
  end)

  return topics
end

--- Render topic list as CLI output.
--- @param topics {{string, string}} List of {name, description} pairs
--- @return string Formatted output
local function render_topic_list(topics: {{string, string}}): string
  local lines: {string} = {}

  table.insert(lines, "cosmic documentation")
  table.insert(lines, "")
  table.insert(lines, "Modules:")

  -- Find max name length for alignment
  local max_len = 0
  for _, topic in ipairs(topics) do
    if #topic[1] > max_len then
      max_len = #topic[1]
    end
  end

  for _, topic in ipairs(topics) do
    local padding = string.rep(" ", max_len - #topic[1] + 2)
    table.insert(lines, "  " .. topic[1] .. padding .. topic[2])
  end

  table.insert(lines, "")
  table.insert(lines, "Use 'cosmic --docs <module>' for more information.")
  table.insert(lines, "Use 'cosmic --docs <module>.<symbol>' for a specific symbol.")

  return table.concat(lines, "\n")
end

--- Render a function as CLI output.
--- @param func FunctionDoc Function documentation
--- @return string Formatted output
local function render_function(func: FunctionDoc): string
  local lines: {string} = {}

  table.insert(lines, "### " .. func.name)
  table.insert(lines, "")

  if func.signature then
    table.insert(lines, "```teal")
    table.insert(lines, "function " .. func.name .. func.signature)
    table.insert(lines, "```")
    table.insert(lines, "")
  end

  if func.description then
    table.insert(lines, func.description)
    table.insert(lines, "")
  end

  if func.params and #func.params > 0 then
    table.insert(lines, "**Parameters:**")
    table.insert(lines, "")
    for _, param in ipairs(func.params) do
      local line = "- `" .. param.name .. "` (" .. param.param_type .. ")"
      if param.description then
        line = line .. " - " .. param.description
      end
      table.insert(lines, line)
    end
    table.insert(lines, "")
  end

  if func.returns and #func.returns > 0 then
    table.insert(lines, "**Returns:**")
    table.insert(lines, "")
    for _, ret in ipairs(func.returns) do
      local line = "- " .. ret.return_type
      if ret.description then
        line = line .. " - " .. ret.description
      end
      table.insert(lines, line)
    end
    table.insert(lines, "")
  end

  return table.concat(lines, "\n")
end

--- Render a record/type as CLI output.
--- @param rec RecordDoc Record documentation
--- @return string Formatted output
local function render_record(rec: RecordDoc): string
  local lines: {string} = {}

  table.insert(lines, "### " .. rec.name)
  table.insert(lines, "")

  if rec.description then
    table.insert(lines, rec.description)
    table.insert(lines, "")
  end

  if rec.fields and #rec.fields > 0 then
    table.insert(lines, "```teal")
    table.insert(lines, "local record " .. rec.name)
    for _, field in ipairs(rec.fields) do
      local fname, ftype, fdesc = field[1], field[2], field[3]
      if fdesc and fdesc ~= "" then
        for desc_line in fdesc:gmatch("[^\n]+") do
          table.insert(lines, "  -- " .. desc_line)
        end
      end
      table.insert(lines, "  " .. fname .. ": " .. ftype)
    end
    table.insert(lines, "end")
    table.insert(lines, "```")
    table.insert(lines, "")
  end

  return table.concat(lines, "\n")
end

--- Render an example as CLI output.
--- @param example ExampleDoc Example documentation
--- @return string Formatted output
local function render_example(example: ExampleDoc): string
  local lines: {string} = {}

  local title = example.name:gsub("^Example_?", ""):gsub("_", " ")
  if title == "" then
    title = "Basic usage"
  end

  table.insert(lines, "### " .. title)
  table.insert(lines, "")

  if example.description then
    table.insert(lines, example.description)
    table.insert(lines, "")
  end

  if example.body then
    table.insert(lines, "```teal")
    -- Clean up body - remove Output: section
    local body = example.body
    local output_start = body:find("%-%-%s*Output:")
    if output_start then
      body = body:sub(1, output_start - 1)
    end
    body = body:gsub("^%s*\n", ""):gsub("\n%s*$", "")
    table.insert(lines, body)
    table.insert(lines, "```")
    table.insert(lines, "")
  end

  if example.expected_output then
    table.insert(lines, "Output:")
    table.insert(lines, "```")
    table.insert(lines, example.expected_output)
    table.insert(lines, "```")
    table.insert(lines, "")
  end

  return table.concat(lines, "\n")
end

--- Render a full module as CLI output.
--- @param name string Module name
--- @param doc ModuleDoc Module documentation
--- @return string Formatted output
local function render_module(name: string, doc: ModuleDoc): string
  local lines: {string} = {}

  -- Extract simple name from path
  local simple_name = name:match("([^%.]+)$") or name
  table.insert(lines, "# " .. simple_name)
  table.insert(lines, "")

  if doc.module_doc then
    table.insert(lines, doc.module_doc)
    table.insert(lines, "")
  end

  -- Types/Records
  if doc.records and #doc.records > 0 then
    table.insert(lines, "## Types")
    table.insert(lines, "")
    for _, rec in ipairs(doc.records) do
      table.insert(lines, render_record(rec))
    end
  end

  -- Functions
  if doc.functions and #doc.functions > 0 then
    table.insert(lines, "## Functions")
    table.insert(lines, "")
    for _, func in ipairs(doc.functions) do
      table.insert(lines, render_function(func))
    end
  end

  -- Examples
  if doc.examples and #doc.examples > 0 then
    table.insert(lines, "## Examples")
    table.insert(lines, "")
    for _, example in ipairs(doc.examples) do
      table.insert(lines, render_example(example))
    end
  end

  return table.concat(lines, "\n")
end

--- Find a symbol in a module's documentation.
--- @param doc ModuleDoc Module documentation
--- @param symbol string Symbol name to find
--- @return string Rendered symbol documentation, or nil if not found
local function find_symbol(doc: ModuleDoc, symbol: string): string
  -- Check functions
  if doc.functions then
    for _, func in ipairs(doc.functions) do
      if func.name == symbol or func.name:lower() == symbol:lower() then
        return render_function(func)
      end
    end
  end

  -- Check records
  if doc.records then
    for _, rec in ipairs(doc.records) do
      if rec.name == symbol or rec.name:lower() == symbol:lower() then
        return render_record(rec)
      end
    end
  end

  -- Check examples
  if doc.examples then
    for _, example in ipairs(doc.examples) do
      local example_name = example.name:gsub("^Example_?", "")
      if example_name == symbol or example_name:lower() == symbol:lower() then
        return render_example(example)
      end
    end
  end

  return nil
end

--- Main entry point for the docs command.
--- @param query string Optional query string (module or module.symbol)
--- @return DocsResult Result with documentation content
local function run(query?: string): DocsResult
  local index, err = load_index()
  if not index then
    return {
      ok = false,
      output = "error: " .. (err or "no documentation embedded") .. "\n" ..
               "Build with 'make cosmic' to include documentation.",
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
      output = render_topic_list(topics),
    }
  end

  -- Try exact module match first
  if index.modules[query] then
    return {
      ok = true,
      output = render_module(query, index.modules[query]),
    }
  end

  -- Try module.symbol pattern
  local parts: {string} = {}
  for part in query:gmatch("[^%.]+") do
    table.insert(parts, part)
  end

  if #parts >= 2 then
    local symbol = parts[#parts]
    local module_parts: {string} = {}
    for i = 1, #parts - 1 do
      table.insert(module_parts, parts[i])
    end
    local module_name = table.concat(module_parts, ".")

    local doc = index.modules[module_name]
    if doc then
      local rendered = find_symbol(doc, symbol)
      if rendered then
        return {
          ok = true,
          output = rendered,
        }
      else
        return {
          ok = false,
          output = "error: symbol '" .. symbol .. "' not found in '" .. module_name .. "'\n" ..
                   "Use 'cosmic --docs " .. module_name .. "' to see available symbols.",
        }
      end
    end
  end

  -- Nothing found
  return {
    ok = false,
    output = "error: documentation not found for '" .. query .. "'\n" ..
             "Use 'cosmic --docs list' to see available modules.",
  }
end

local record DocsModule
  run: function(query?: string): DocsResult
  has_docs: function(): boolean
  list_topics: function(): {{string, string}}
  load_index: function(): DocIndex, string
  render_module: function(name: string, doc: ModuleDoc): string
end

local M: DocsModule = {
  run = run,
  has_docs = has_docs,
  list_topics = list_topics,
  load_index = load_index,
  render_module = render_module,
}

return M
