#!/usr/bin/env cosmic
-- Doctest runner: generates executable tests from extracted doctest examples
--
-- Usage:
--   cosmic -- lib/build/doctest/runner.tl input.doctest.extracted output.test.tl
--
-- Reads a .doctest.extracted JSON file containing examples extracted from
-- documentation and generates an executable test file that runs each example
-- in a pcall, tracking pass/fail counts.

local cosmo = require("cosmo")

-- Type definitions for the extracted doctest format
-- These match the format produced by lib/build/doctest/extractor.tl

local record ExtractedExample
  id: string
  source_file: string
  source_line: integer
  kind: string
  code: string
  expected_output: string
  requires_setup: boolean
  requires_teardown: boolean
  tags: {string}
end

local record DoctestExtracted
  examples: {string: ExtractedExample}
  total_count: integer
  file_count: integer
end

-- Internal format for generating tests
local record Example
  title: string
  code: string
  setup: string
  teardown: string
  line: integer
  source_file: string
end

local record GeneratedTest
  source: string
  test_count: integer
  content: string
end

-- Parse command line arguments
local function parse_args(args: {string}): string, string, string
  if #args < 2 then
    io.stderr:write("usage: cosmic -- lib/build/doctest/runner.tl <input.doctest.extracted> <output.test.tl>\n")
    io.stderr:write("\n")
    io.stderr:write("Generates executable test files from extracted doctest examples.\n")
    os.exit(1)
  end

  local input = args[1]
  local output = args[2]

  -- Validate input file exists
  local input_content = cosmo.Slurp(input)
  if not input_content then
    return nil, nil, "failed to read input file: " .. input
  end

  return input, output, nil
end

-- Convert ExtractedExample to internal Example format
local function convert_example(ex: ExtractedExample, setup_code: string, teardown_code: string): Example
  -- Generate a title from the example ID or extract from code
  local title = ex.id

  -- Try to extract a more readable title from the first line of code
  local first_line = ex.code:match("^[^\n]+")
  if first_line and #first_line < 60 then
    title = first_line
  end

  return {
    title = title,
    code = ex.code,
    setup = setup_code or "",
    teardown = teardown_code or "",
    line = ex.source_line,
    source_file = ex.source_file,
  }
end

-- Load and parse the extracted doctest JSON
local function load_extracted(path: string): DoctestExtracted, string
  local content = cosmo.Slurp(path)
  if not content then
    return nil, "failed to read file: " .. path
  end

  local ok, data = pcall(cosmo.DecodeJson, content)
  if not ok then
    return nil, "failed to parse JSON: " .. tostring(data)
  end

  -- Validate structure
  if type(data) ~= "table" then
    return nil, "invalid JSON: expected object"
  end

  local extracted = data as DoctestExtracted
  if not extracted.examples or type(extracted.examples) ~= "table" then
    return nil, "missing or invalid field: examples"
  end

  return extracted, nil
end

-- Escape a string for safe inclusion in Lua code
local function escape_lua_string(s: string): string
  -- Use long string literals to avoid most escaping issues
  -- Check if the string contains ]] which would break long strings
  if s:find("]]", 1, true) then
    -- Fall back to quoted string with escaping
    return '"' .. s:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', '\\r'):gsub('\t', '\\t') .. '"'
  else
    return "[[" .. s .. "]]"
  end
end

-- Generate test code for a single example
local function generate_example_test(example: Example, index: integer): string
  local parts: {string} = {}

  -- Add comment header
  table.insert(parts, "-- Example " .. tostring(index) .. ": " .. (example.title or "untitled"))
  if example.source_file then
    table.insert(parts, "-- Source: " .. example.source_file .. ":" .. tostring(example.line or 0))
  elseif example.line then
    table.insert(parts, "-- Source line: " .. tostring(example.line))
  end
  table.insert(parts, "do")
  table.insert(parts, "  test_count = test_count + 1")
  table.insert(parts, "  local example_num = test_count")
  table.insert(parts, "")

  -- Add the test execution with pcall
  table.insert(parts, "  local ok, err = pcall(function()")

  -- Add setup code if present
  if example.setup and example.setup ~= "" then
    table.insert(parts, "    -- Setup")
    for line in example.setup:gmatch("[^\n]+") do
      table.insert(parts, "    " .. line)
    end
    table.insert(parts, "")
  end

  -- Add the actual example code
  table.insert(parts, "    -- Example code")
  for line in example.code:gmatch("[^\n]+") do
    table.insert(parts, "    " .. line)
  end
  table.insert(parts, "")

  -- Add teardown code if present
  if example.teardown and example.teardown ~= "" then
    table.insert(parts, "    -- Teardown")
    for line in example.teardown:gmatch("[^\n]+") do
      table.insert(parts, "    " .. line)
    end
  end

  table.insert(parts, "  end)")
  table.insert(parts, "")

  -- Track results
  table.insert(parts, "  if ok then")
  table.insert(parts, "    pass_count = pass_count + 1")
  table.insert(parts, "  else")
  table.insert(parts, "    fail_count = fail_count + 1")
  table.insert(parts, "    local title = " .. escape_lua_string(example.title or "untitled"))
  table.insert(parts, "    io.stderr:write(string.format('FAIL: Example %d (%s)\\n', example_num, title))")
  table.insert(parts, "    io.stderr:write('  ' .. tostring(err) .. '\\n')")
  table.insert(parts, "  end")
  table.insert(parts, "end")
  table.insert(parts, "")

  return table.concat(parts, "\n")
end

-- Generate the complete test file
local function generate_test(extracted: DoctestExtracted): GeneratedTest, string
  if not extracted.examples or extracted.total_count == 0 then
    return nil, "no examples to generate tests for"
  end

  -- First pass: collect setup and teardown code, group examples by file
  local setup_code = ""
  local teardown_code = ""
  local examples_by_file: {string: {ExtractedExample}} = {}
  local source_files: {string} = {}

  for _, ex in pairs(extracted.examples) do
    if ex.kind == "setup" then
      setup_code = setup_code .. ex.code .. "\n"
    elseif ex.kind == "teardown" then
      teardown_code = teardown_code .. ex.code .. "\n"
    elseif ex.kind == "example" then
      if not examples_by_file[ex.source_file] then
        examples_by_file[ex.source_file] = {}
        table.insert(source_files, ex.source_file)
      end
      table.insert(examples_by_file[ex.source_file], ex)
    end
  end

  -- Sort examples by source line within each file
  for _, file_examples in pairs(examples_by_file) do
    table.sort(file_examples, function(a: ExtractedExample, b: ExtractedExample): boolean
      return a.source_line < b.source_line
    end)
  end

  -- Sort source files for consistent output
  table.sort(source_files)

  -- Convert to internal Example format
  local examples: {Example} = {}
  for _, source_file in ipairs(source_files) do
    for _, ex in ipairs(examples_by_file[source_file]) do
      table.insert(examples, convert_example(ex, setup_code, teardown_code))
    end
  end

  if #examples == 0 then
    return nil, "no executable examples found (only setup/teardown)"
  end

  local parts: {string} = {}

  -- Add shebang and header
  table.insert(parts, "#!/usr/bin/env cosmic")
  table.insert(parts, "-- Auto-generated doctest from extracted examples")
  table.insert(parts, "--")
  table.insert(parts, "-- This file was automatically generated by lib/build/doctest/runner.tl")
  table.insert(parts, "-- Do not edit manually. Regenerate from source documentation.")
  table.insert(parts, "-- Sources: " .. table.concat(source_files, ", "))
  table.insert(parts, "")

  -- Add test tracking variables
  table.insert(parts, "local test_count = 0")
  table.insert(parts, "local pass_count = 0")
  table.insert(parts, "local fail_count = 0")
  table.insert(parts, "")

  -- Generate test code for each example
  for i, example in ipairs(examples) do
    table.insert(parts, generate_example_test(example, i))
  end

  -- Add summary and exit
  table.insert(parts, "-- Test summary")
  table.insert(parts, "if fail_count > 0 then")
  table.insert(parts, "  io.stderr:write(string.format('\\nDoctest failed: %d/%d examples passed\\n', pass_count, test_count))")
  table.insert(parts, "  os.exit(1)")
  table.insert(parts, "else")
  table.insert(parts, "  io.stdout:write(string.format('Doctest passed: %d/%d examples\\n', pass_count, test_count))")
  table.insert(parts, "  os.exit(0)")
  table.insert(parts, "end")
  table.insert(parts, "")

  local result: GeneratedTest = {
    source = table.concat(source_files, ", "),
    test_count = #examples,
    content = table.concat(parts, "\n")
  }

  return result, nil
end

-- Write the generated test to a file
local function write_test(path: string, test: GeneratedTest): boolean, string
  local ok = cosmo.Barf(path, test.content)
  if not ok then
    return nil, "failed to write test file: " .. path
  end

  return true, nil
end

-- Main entry point
local function main(args: {string}): integer
  -- Parse arguments
  local input, output, err = parse_args(args)
  if err then
    io.stderr:write("error: " .. err .. "\n")
    return 1
  end

  -- Load extracted doctest data
  local extracted: DoctestExtracted
  extracted, err = load_extracted(input)
  if err then
    io.stderr:write("error: " .. err .. "\n")
    return 1
  end

  -- Generate test file
  local test: GeneratedTest
  test, err = generate_test(extracted)
  if err then
    io.stderr:write("error: " .. err .. "\n")
    return 1
  end

  -- Write test file
  local ok: boolean
  ok, err = write_test(output, test)
  if err then
    io.stderr:write("error: " .. err .. "\n")
    return 1
  end

  -- Report success
  io.stdout:write(string.format("Generated %d doctest examples from %s\n",
    test.test_count, test.source))
  io.stdout:write(string.format("Wrote test file: %s\n", output))

  return 0
end

-- Run if executed directly
if cosmo.is_main() then
  os.exit(main(arg))
end

-- Export for testing
return {
  load_extracted = load_extracted,
  generate_test = generate_test,
  escape_lua_string = escape_lua_string,
}
