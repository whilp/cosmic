#!/usr/bin/env cosmic
-- test cosmic.doc module

local path = require("cosmo.path")
local spawn = require("cosmic.spawn")
local cosmo = require("cosmo")
local doc = require("cosmic.doc")

local cosmic = path.join(os.getenv("TEST_BIN"), "cosmic")
local tmpdir = os.getenv("TEST_TMPDIR")

local function write_temp(name: string, content: string): string
  local filepath = path.join(tmpdir, name)
  cosmo.Barf(filepath, content)
  return filepath
end

-- Test parsing module-level doc comment
local function test_parse_module_doc()
  local source = [[--- This is the module description
--- It spans multiple lines
local x = 1
]]
  local result = doc.parse(source, "test.tl")
  assert(result.module_doc, "should extract module doc")
  assert(result.module_doc:find("module description"), "should contain description")
  assert(result.module_doc:find("multiple lines"), "should contain all lines")
end
test_parse_module_doc()

-- Test parsing function with doc comment
local function test_parse_function_doc()
  local source = [[
--- Add two numbers together
--- @param a number the first number
--- @param b number the second number
--- @return number the sum
local function add(a: number, b: number): number
  return a + b
end
]]
  local result = doc.parse(source, "test.tl")
  assert(#result.functions == 1, "should find one function")
  local fn = result.functions[1]
  assert(fn.name == "add", "function name should be 'add'")
  assert(fn.description:find("Add two numbers"), "should have description")
  assert(#fn.params == 2, "should have two params")
  assert(fn.params[1].name == "a", "first param should be 'a'")
  assert(fn.params[1].param_type == "number", "first param type should be 'number'")
  assert(#fn.returns == 1, "should have one return")
  assert(fn.returns[1].return_type == "number", "return type should be 'number'")
end
test_parse_function_doc()

-- Test parsing record
local function test_parse_record()
  local source = [[
--- A point in 2D space
local record Point
  x: number
  y: number
end
]]
  local result = doc.parse(source, "test.tl")
  assert(#result.records == 1, "should find one record")
  assert(result.records[1].name == "Point", "record name should be 'Point'")
  assert(result.records[1].description:find("2D space"), "should have description")
end
test_parse_record()

-- Test parsing Example_* functions
local function test_parse_example()
  local source = [[
local function Example_basic()
  print("hello")
  -- Output:
  -- hello
end
]]
  local result = doc.parse(source, "test.tl")
  assert(#result.examples == 1, "should find one example")
  assert(result.examples[1].name == "Example_basic", "example name should match")
  -- doc.parse extracts output with trailing newline from comment lines
  assert(result.examples[1].expected_output:match("^hello"), "should extract expected output")
end
test_parse_example()

-- Test that Example_* functions are not included in regular functions
local function test_example_not_in_functions()
  local source = [[
local function Example_foo()
  print("test")
end

local function real_function()
  return 42
end
]]
  local result = doc.parse(source, "test.tl")
  assert(#result.functions == 1, "should only find one regular function")
  assert(result.functions[1].name == "real_function", "should be the non-example function")
  assert(#result.examples == 1, "should find one example")
end
test_example_not_in_functions()

-- Test render produces markdown
local function test_render_markdown()
  local source = [[--- Test module
local record Foo
  x: number
end

local function Example_usage()
  print("hello")
  -- Output:
  -- hello
end
]]
  local result = doc.parse(source, "mymodule.tl")
  local md = doc.render(result)
  assert(md:find("# mymodule"), "should have module header")
  assert(md:find("Test module"), "should have module description")
  assert(md:find("## Types"), "should have Types section")
  assert(md:find("### Foo"), "should have Foo record")
  assert(md:find("## Examples"), "should have Examples section")
  assert(md:find("```teal"), "should have teal code block")
end
test_render_markdown()

-- Test render_file with valid file
local function test_render_file()
  local input = write_temp("doc_test.tl", [[--- A test file
local function helper()
  return 1
end
]])
  local ok, md = doc.render_file(input)
  assert(ok, "render_file should succeed")
  assert(md:find("# doc_test"), "should have filename as header")
  assert(md:find("A test file"), "should have module doc")
end
test_render_file()

-- Test render_file with missing file
local function test_render_file_missing()
  local ok, err = doc.render_file("/nonexistent/file.tl")
  assert(not ok, "render_file should fail on missing file")
  assert(err:find("cannot open"), "should have error message")
end
test_render_file_missing()

-- Test cosmic --doc command
local function test_cosmic_doc_command()
  local input = write_temp("cmd_test.tl", [[--- Command test module
local record Widget
  id: number
end
]])
  local ok, out = spawn({cosmic, "--doc", input}):read()
  assert(ok, "cosmic --doc should succeed")
  assert((out as string):find("# cmd_test"), "output should have header")
  assert((out as string):find("Command test module"), "output should have module doc")
  assert((out as string):find("### Widget"), "output should have record")
end
test_cosmic_doc_command()

-- Test cosmic --doc with missing file
local function test_cosmic_doc_missing_file()
  local ok, out = spawn({cosmic, "--doc", "/nonexistent/file.tl"}):read()
  assert(not ok, "cosmic --doc should fail on missing file")
end
test_cosmic_doc_missing_file()

-- Test function without doc comment
local function test_function_no_doc()
  local source = [[
local function undocumented()
  return 42
end
]]
  local result = doc.parse(source, "test.tl")
  assert(#result.functions == 1, "should find function")
  assert(result.functions[1].description == nil, "should have no description")
  assert(#result.functions[1].params == 0, "should have no params")
end
test_function_no_doc()

-- Test multiple functions
local function test_multiple_functions()
  local source = [[
--- First function
local function first()
end

--- Second function
local function second()
end
]]
  local result = doc.parse(source, "test.tl")
  assert(#result.functions == 2, "should find two functions")
  assert(result.functions[1].name == "first", "first function")
  assert(result.functions[2].name == "second", "second function")
end
test_multiple_functions()

-- Test example title conversion
local function test_example_title()
  local source = [[
local function Example_foo_bar_baz()
  print("test")
end
]]
  local result = doc.parse(source, "test.tl")
  local md = doc.render(result)
  assert(md:find("### foo bar baz"), "should convert underscores to spaces in title")
end
test_example_title()

print("All doc tests passed!")
