--- Extract documentation from Teal files and render as markdown.
--- Parses doc comments, records, functions, and examples from .tl files.

--- A function parameter with type and description.
local record Param
  name: string
  param_type: string
  description: string
end

--- A function return value with type and description.
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

--- Extract leading doc comment (--- or -- style) before a position.
--- Scans backwards from the given position to collect doc comment lines.
--- @param source string The source code to search
--- @param pos integer The position to search backwards from
--- @param allow_regular_comments boolean If true, also extract -- style comments (default: false)
--- @return string The extracted doc comment, or nil if none found
local function extract_doc_comment(source: string, pos: integer, allow_regular_comments?: boolean): string
  -- Find the start of the line containing pos
  local line_start = pos
  while line_start > 1 and source:sub(line_start - 1, line_start - 1) ~= "\n" do
    line_start = line_start - 1
  end

  -- Collect doc comment lines going backwards
  local doc_lines: {string} = {}
  local check_pos = line_start - 1  -- Start before current line

  while check_pos > 0 do
    -- Find start of previous line
    local prev_line_start = check_pos
    while prev_line_start > 1 and source:sub(prev_line_start - 1, prev_line_start - 1) ~= "\n" do
      prev_line_start = prev_line_start - 1
    end

    local line = source:sub(prev_line_start, check_pos - 1)

    -- Check if it's a doc comment (--- style)
    local doc_content = line:match("^%s*%-%-%-(.*)$")
    if doc_content then
      table.insert(doc_lines, 1, doc_content)
      check_pos = prev_line_start - 1
    elseif allow_regular_comments then
      -- Also check for regular -- comments if allowed
      local regular_comment = line:match("^%s*%-%-([^%-].*)$")
      if regular_comment then
        table.insert(doc_lines, 1, regular_comment)
        check_pos = prev_line_start - 1
      elseif line:match("^%s*$") then
        -- Empty line - stop
        break
      else
        -- Non-doc line - stop
        break
      end
    elseif line:match("^%s*$") then
      -- Empty line - stop
      break
    else
      -- Non-doc line - stop
      break
    end
  end

  if #doc_lines == 0 then
    return nil
  end

  return table.concat(doc_lines, "\n")
end

--- Parse @param and @return annotations from doc comment.
--- Extracts structured parameter and return information along with description.
--- @param doc string The doc comment to parse
--- @return {Param} List of parameters
--- @return {Return} List of return values
--- @return string The description text (non-annotation lines)
local function parse_annotations(doc: string): {Param}, {Return}, string
  if not doc then
    return {}, {}, nil
  end

  local params: {Param} = {}
  local returns: {Return} = {}
  local desc_lines: {string} = {}

  for line in doc:gmatch("[^\n]+") do
    local param_name, param_type, param_desc = line:match("^%s*@param%s+(%S+)%s+(%S+)%s*(.*)")
    if param_name then
      table.insert(params, {
        name = param_name,
        param_type = param_type,
        description = param_desc ~= "" and param_desc or nil,
      })
    else
      local ret_type, ret_desc = line:match("^%s*@return%s+(%S+)%s*(.*)")
      if ret_type then
        table.insert(returns, {
          return_type = ret_type,
          description = ret_desc ~= "" and ret_desc or nil,
        })
      else
        -- Regular description line
        table.insert(desc_lines, line)
      end
    end
  end

  local description = #desc_lines > 0 and table.concat(desc_lines, "\n") or nil
  return params, returns, description
end

--- Parse a .tl file and extract documentation.
--- Extracts module docs, records, functions, and examples from source code.
--- @param source string The source code to parse
--- @param file_path string Path to the file being parsed
--- @return ModuleDoc Complete documentation for the module
local function parse(source: string, file_path: string): ModuleDoc
  local doc: ModuleDoc = {
    file = file_path,
    module_doc = nil,
    functions = {},
    records = {},
    examples = {},
  }

  -- Extract module-level doc comment (at very beginning)
  local first_doc = source:match("^%s*(%-%-%-[^\n]*)")
  if first_doc then
    local module_doc_lines: {string} = {}
    local pos = 1
    while true do
      local line_end = source:find("\n", pos)
      if not line_end then break end
      local line = source:sub(pos, line_end - 1)
      local doc_content = line:match("^%s*%-%-%-(.*)$")
      if doc_content then
        table.insert(module_doc_lines, doc_content)
        pos = line_end + 1
      else
        break
      end
    end
    if #module_doc_lines > 0 then
      doc.module_doc = table.concat(module_doc_lines, "\n")
    end
  end

  -- Find all function definitions
  local line_num = 1
  local last_pos = 1

  local function update_line_num(new_pos: integer)
    for i = last_pos, new_pos - 1 do
      if source:sub(i, i) == "\n" then
        line_num = line_num + 1
      end
    end
    last_pos = new_pos
  end

  -- Find functions: local function name() or function name()
  -- Capture full signature including return types
  for func_start, is_local, func_name in source:gmatch("()(local%s+)function%s+([%w_:]+)%s*%(") do
    update_line_num(func_start as integer)

    -- Skip Example_* functions (handled separately)
    if not (func_name as string):match("^Example") then
      -- Find the signature: from ( to the end of the line or to the function body
      local sig_start = source:find("%(", func_start as integer)
      local sig_end = sig_start
      local depth = 0

      -- Scan forward to find the matching closing paren
      for i = sig_start, #source do
        local char = source:sub(i, i)
        if char == "(" then
          depth = depth + 1
        elseif char == ")" then
          depth = depth - 1
          if depth == 0 then
            sig_end = i
            -- Continue scanning for return type annotation up to newline
            local j = i + 1
            while j <= #source do
              local c = source:sub(j, j)
              if c == "\n" then
                break
              end
              sig_end = j
              j = j + 1
            end
            break
          end
        end
      end

      local signature = source:sub(sig_start, sig_end)

      -- Skip malformed signatures (should not contain words like "everything", "until", etc)
      if signature:match("%s+everything%s+") or signature:match("%s+until%s+") then
        goto continue_local
      end

      local func_doc = extract_doc_comment(source, func_start as integer)
      local params, returns, description = parse_annotations(func_doc)

      table.insert(doc.functions, {
        name = func_name as string,
        description = description,
        params = params,
        returns = returns,
        signature = signature,
        line = line_num,
        is_local = is_local ~= nil,
      })
      ::continue_local::
    end
  end

  -- Also find non-local functions
  line_num = 1
  last_pos = 1
  for func_start, func_name in source:gmatch("()function%s+([%w_:]+)%s*%(") do
    -- Skip if this is a "local function" or a function type annotation in a record
    local before = source:sub(math.max(1, (func_start as integer) - 20), (func_start as integer) - 1)
    if not before:match("local%s*$") and not before:match(":%s*$") then
      update_line_num(func_start as integer)

      if not (func_name as string):match("^Example") then
        -- Find the signature: from ( to the end of the line or to the function body
        local sig_start = source:find("%(", func_start as integer)
        local sig_end = sig_start
        local depth = 0

        -- Scan forward to find the matching closing paren
        for i = sig_start, #source do
          local char = source:sub(i, i)
          if char == "(" then
            depth = depth + 1
          elseif char == ")" then
            depth = depth - 1
            if depth == 0 then
              sig_end = i
              -- Continue scanning for return type annotation up to newline
              local j = i + 1
              while j <= #source do
                local c = source:sub(j, j)
                if c == "\n" then
                  break
                end
                sig_end = j
                j = j + 1
              end
              break
            end
          end
        end

        local signature = source:sub(sig_start, sig_end)

        -- Skip malformed signatures (should not contain words like "everything", "until", etc)
        if signature:match("%s+everything%s+") or signature:match("%s+until%s+") then
          goto continue_nonlocal
        end

        local func_doc = extract_doc_comment(source, func_start as integer)
        local params, returns, description = parse_annotations(func_doc)

        table.insert(doc.functions, {
          name = func_name as string,
          description = description,
          params = params,
          returns = returns,
          signature = signature,
          line = line_num,
          is_local = false,
        })
        ::continue_nonlocal::
      end
    end
  end

  -- Find record definitions
  line_num = 1
  last_pos = 1
  for rec_start, rec_name in source:gmatch("()local%s+record%s+([%w_]+)") do
    update_line_num(rec_start as integer)

    local rec_doc = extract_doc_comment(source, rec_start as integer)
    local _, _, description = parse_annotations(rec_doc)

    -- Extract fields from the record body
    local fields: {{string, string, string}} = {}

    -- Find the record body (between record Name and end)
    local body_start = source:find("\n", rec_start as integer)
    if body_start then
      -- Find the matching end for this record
      local depth = 1
      local i = body_start + 1
      local record_end = i

      while i <= #source and depth > 0 do
        local word_start, word_end, word = source:find("(%a+)", i)
        if word_start == i then
          if word == "record" or word == "enum" then
            depth = depth + 1
          elseif word == "end" then
            depth = depth - 1
            if depth == 0 then
              record_end = word_start - 1
            end
          end
          i = word_end + 1
        else
          i = i + 1
        end
      end

      -- Now parse fields in the record body
      local body = source:sub(body_start, record_end)
      local field_pos = 1

      while field_pos <= #body do
        -- Find field definition: name: type
        local fstart, fend, fname, ftype = body:find("%s*([%w_]+)%s*:%s*([^\n]+)", field_pos)
        if not fstart then break end

        -- Extract doc comment before this field
        local field_absolute_pos = body_start + fstart
        local field_doc = extract_doc_comment(source, field_absolute_pos)
        local _, _, field_description = parse_annotations(field_doc)

        -- Clean up the type (remove trailing comments and whitespace)
        local clean_type = ftype:match("^%s*(.-)%s*$")
        if clean_type:match("%-%-%s*.*$") then
          clean_type = clean_type:gsub("%s*%-%-.*$", "")
        end

        table.insert(fields, {fname, clean_type, field_description or ""})
        field_pos = fend + 1
      end
    end

    table.insert(doc.records, {
      name = rec_name as string,
      description = description,
      fields = fields,
      line = line_num,
    })
  end

  -- Find Example_* functions
  line_num = 1
  last_pos = 1
  for func_start, func_name in source:gmatch("()local%s+function%s+(Example[%w_]*)%s*%(") do
    update_line_num(func_start as integer)

    -- Extract doc comment before this example (allow regular -- comments for examples)
    local example_doc = extract_doc_comment(source, func_start as integer, true)
    local _, _, example_description = parse_annotations(example_doc)

    -- Find the function body
    local body_start = source:find("%)", func_start as integer) + 1
    local depth = 1
    local i = body_start

    while i <= #source and depth > 0 do
      -- Skip strings and comments (simplified)
      if source:sub(i, i) == '"' or source:sub(i, i) == "'" then
        local quote = source:sub(i, i)
        i = i + 1
        while i <= #source do
          if source:sub(i, i) == "\\" then
            i = i + 2
          elseif source:sub(i, i) == quote then
            i = i + 1
            break
          else
            i = i + 1
          end
        end
      elseif source:sub(i, i+1) == "--" then
        local newline = source:find("\n", i)
        i = newline and newline + 1 or #source + 1
      else
        local word_start, word_end, word = source:find("(%a+)", i)
        if word_start == i then
          if word == "function" or word == "if" or word == "for" or word == "while" then
            depth = depth + 1
          elseif word == "until" or word == "end" then
            depth = depth - 1
          end
          i = word_end + 1
        else
          i = i + 1
        end
      end
    end

    local body_end = i - 4
    local body = source:sub(body_start, body_end)

    -- Extract expected output
    local expected: string = nil
    local output_start = body:find("%-%-%s*Output:")
    if output_start then
      local lines: {string} = {}
      local output_pos = output_start
      local line_end = body:find("\n", output_pos)
      if line_end then
        output_pos = line_end + 1
        while true do
          local content_match_start, _, prefix, content = body:find("^(%s*%-%-%s?)(.*)\n?", output_pos)
          if content_match_start == output_pos and prefix then
            table.insert(lines, content)
            output_pos = output_pos + #prefix + #content
            if body:sub(output_pos, output_pos) == "\n" then
              output_pos = output_pos + 1
            else
              break
            end
          else
            break
          end
        end
      end
      expected = table.concat(lines, "\n")
    end

    table.insert(doc.examples, {
      name = func_name as string,
      description = example_description,
      body = body,
      expected_output = expected,
      line = line_num,
    })
  end

  return doc
end

--- Render documentation as markdown.
--- Converts parsed documentation into formatted markdown with sections for types, functions, and examples.
--- @param doc ModuleDoc The documentation to render
--- @return string Formatted markdown documentation
local function render(doc: ModuleDoc): string
  local lines: {string} = {}

  -- Module header
  local module_name = doc.file:match("([^/]+)%.tl$") or doc.file
  table.insert(lines, "# " .. module_name)
  table.insert(lines, "")

  if doc.module_doc then
    table.insert(lines, doc.module_doc)
    table.insert(lines, "")
  end

  -- Records
  if #doc.records > 0 then
    table.insert(lines, "## Types")
    table.insert(lines, "")

    for _, rec in ipairs(doc.records) do
      table.insert(lines, "### " .. rec.name)
      table.insert(lines, "")
      if rec.description then
        table.insert(lines, rec.description)
        table.insert(lines, "")
      end

      -- Show the full record definition if fields exist
      if #rec.fields > 0 then
        table.insert(lines, "```teal")
        table.insert(lines, "local record " .. rec.name)
        for _, field in ipairs(rec.fields) do
          local field_name, field_type, field_desc = field[1], field[2], field[3]
          -- Add field description as a comment above the field
          if field_desc and field_desc ~= "" then
            -- Split multi-line descriptions
            for desc_line in field_desc:gmatch("[^\n]+") do
              table.insert(lines, "  -- " .. desc_line)
            end
          end
          table.insert(lines, "  " .. field_name .. ": " .. field_type)
        end
        table.insert(lines, "end")
        table.insert(lines, "```")
        table.insert(lines, "")
      end
    end
  end

  -- Functions
  local exported_functions: {FunctionDoc} = {}
  for _, func in ipairs(doc.functions) do
    if not func.is_local then
      table.insert(exported_functions, func)
    end
  end

  if #exported_functions > 0 then
    table.insert(lines, "## Functions")
    table.insert(lines, "")

    for _, func in ipairs(exported_functions) do
      table.insert(lines, "### " .. func.name)
      table.insert(lines, "")

      -- Show signature if available
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

      if #func.params > 0 then
        table.insert(lines, "**Parameters:**")
        table.insert(lines, "")
        for _, param in ipairs(func.params) do
          local param_line = "- `" .. param.name .. "` (" .. param.param_type .. ")"
          if param.description then
            param_line = param_line .. " - " .. param.description
          end
          table.insert(lines, param_line)
        end
        table.insert(lines, "")
      end

      if #func.returns > 0 then
        table.insert(lines, "**Returns:**")
        table.insert(lines, "")
        for _, ret in ipairs(func.returns) do
          local ret_line = "- " .. ret.return_type
          if ret.description then
            ret_line = ret_line .. " - " .. ret.description
          end
          table.insert(lines, ret_line)
        end
        table.insert(lines, "")
      end
    end
  end

  -- Examples
  if #doc.examples > 0 then
    table.insert(lines, "## Examples")
    table.insert(lines, "")

    for _, example in ipairs(doc.examples) do
      -- Convert Example_foo_bar to "foo bar" title
      local title = example.name:gsub("^Example_?", ""):gsub("_", " ")
      if title == "" then
        title = "Basic usage"
      end
      table.insert(lines, "### " .. title)
      table.insert(lines, "")

      -- Add description if present
      if example.description then
        table.insert(lines, example.description)
        table.insert(lines, "")
      end

      table.insert(lines, "```teal")

      -- Clean up the body for display and remove -- Output: section
      local body = example.body
      -- Remove the -- Output: comment block
      local output_start = body:find("%-%-%s*Output:")
      if output_start then
        -- Remove everything from -- Output: onwards
        body = body:sub(1, output_start - 1)
      end
      -- Clean up leading/trailing whitespace
      body = body:gsub("^%s*\n", ""):gsub("\n%s*$", "")
      table.insert(lines, body)

      table.insert(lines, "```")
      table.insert(lines, "")

      if example.expected_output then
        table.insert(lines, "Output:")
        table.insert(lines, "```")
        table.insert(lines, example.expected_output)
        table.insert(lines, "```")
        table.insert(lines, "")
      end
    end
  end

  return table.concat(lines, "\n")
end

--- Main entry point: parse file and render markdown.
--- Reads a Teal file, extracts documentation, and renders it as markdown.
--- @param file_path string Path to the Teal file to document
--- @return boolean Success status
--- @return string Markdown documentation on success, error message on failure
local function render_file(file_path: string): boolean, string
  local f, err = io.open(file_path, "r")
  if not f then
    return false, "cannot open file: " .. (err or "unknown")
  end

  local source = f:read("*a")
  f:close()

  local doc = parse(source, file_path)
  local markdown = render(doc)

  return true, markdown
end

local record DocModule
  parse: function(source: string, file_path: string): ModuleDoc
  render: function(doc: ModuleDoc): string
  render_file: function(file_path: string): boolean, string
end

local M: DocModule = {
  parse = parse,
  render = render,
  render_file = render_file,
}

return M
