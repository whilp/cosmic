#!/usr/bin/env lua
--- Tests for the embedded documentation module.

local docs = require("cosmic.docs")

-- Test extract_description (via module inspection)
local function test_path_to_module()
  -- Test that the module can be loaded
  assert(docs, "docs module should load")
  assert(docs.run, "docs.run should exist")
  assert(docs.has_docs, "docs.has_docs should exist")
  assert(docs.list_topics, "docs.list_topics should exist")
  print("test_path_to_module: PASS")
end
test_path_to_module()

-- Test has_docs returns a boolean
local function test_has_docs()
  local result = docs.has_docs()
  assert(type(result) == "boolean", "has_docs should return a boolean")
  print("test_has_docs: PASS")
end
test_has_docs()

-- Test run with no docs embedded
local function test_run_no_docs()
  -- When no docs are embedded, run should return an error
  local result = docs.run()
  assert(result, "run should return a result")
  assert(result.output, "result should have output")
  -- Either it has docs (ok=true) or it doesn't (ok=false with error message)
  if not result.ok then
    assert(result.output:match("no documentation"), "error should mention no documentation")
  end
  print("test_run_no_docs: PASS")
end
test_run_no_docs()

-- Test run with a query when no docs embedded
local function test_run_with_query_no_docs()
  local result = docs.run("cosmo.path")
  assert(result, "run should return a result")
  assert(result.output, "result should have output")
  -- Either it has docs or it doesn't
  if not result.ok then
    assert(result.output:match("documentation") or result.output:match("not found"),
           "error should mention documentation or not found")
  end
  print("test_run_with_query_no_docs: PASS")
end
test_run_with_query_no_docs()

-- Test list_topics
local function test_list_topics()
  local topics = docs.list_topics()
  assert(type(topics) == "table", "list_topics should return a table")
  -- If docs are embedded, topics will have entries; otherwise empty
  print("test_list_topics: PASS (found " .. #topics .. " topics)")
end
test_list_topics()

print("")
print("All docs tests passed!")
