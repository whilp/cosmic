#!/usr/bin/env cosmic
-- Test file for doctest example module

local example = require("build.doctest.example")

-- Test: new_collection creates an empty collection
local collection = example.new_collection()
assert(collection.total_count == 0, "new collection should have 0 examples")
assert(collection.file_count == 0, "new collection should have 0 files")

-- Test: new_example creates a valid example
local ex = example.new_example({
   source_file = "test.tl",
   source_line = 10,
   kind = "example",
   code = "print('hello')",
   expected_output = "",
   tags = {},
})
assert(ex.id ~= nil, "example should have an ID")
assert(ex.source_file == "test.tl", "source_file should match")
assert(ex.source_line == 10, "source_line should match")

-- Test: validate_example validates correct examples
local valid, err = example.validate_example(ex)
assert(valid, "example should be valid: " .. tostring(err))

-- Test: validate_example catches invalid examples
local bad_ex = example.new_example({
   source_file = "",
   source_line = 10,
   kind = "example",
   code = "print('test')",
   expected_output = "",
   tags = {},
})
valid, err = example.validate_example(bad_ex)
assert(not valid, "example with empty source_file should be invalid")

-- Test: has_assertions detects assertions
local ex_with_assert = example.new_example({
   source_file = "test.tl",
   source_line = 1,
   kind = "example",
   code = "assert(1 == 1)",
   expected_output = "",
   tags = {},
})
assert(example.has_assertions(ex_with_assert), "should detect assert() calls")

local ex_with_output = example.new_example({
   source_file = "test.tl",
   source_line = 1,
   kind = "example",
   code = "print(1 + 1)",
   expected_output = "2",
   tags = {},
})
assert(example.has_assertions(ex_with_output), "should detect expected output")

-- Test: add_example adds to collection
example.add_example(collection, ex)
assert(collection.total_count == 1, "collection should have 1 example")
assert(collection.file_count == 1, "collection should have 1 file")

-- Test: dedent removes common indentation
local indented = [[
   local x = 1
   local y = 2
   print(x + y)
]]
local dedented = example.dedent(indented)
assert(dedented:match("^local x = 1"), "dedent should remove leading spaces")

print("All tests passed!")
