#!/usr/bin/env cosmic
-- Test the doctest runner

local cosmo = require("cosmo")
local unix = require("cosmo.unix")
local path = require("cosmo.path")

local tmpdir = os.getenv("TEST_TMPDIR") or "/tmp"
local test_dir = path.join(tmpdir, "doctest-runner-test")
unix.makedirs(test_dir)

-- Test 1: Basic example extraction and generation
local function test_basic_generation()
  local extracted_json = [[{
  "source": "lib/cosmic/example.tl",
  "examples": [
    {
      "title": "simple addition",
      "code": "local x = 1 + 1\nassert(x == 2)",
      "line": 10
    },
    {
      "title": "string concatenation",
      "code": "local s = 'hello' .. ' ' .. 'world'\nassert(s == 'hello world')",
      "line": 20
    }
  ]
}]]

  local input_file = path.join(test_dir, "test1.doctest.extracted")
  local output_file = path.join(test_dir, "test1.test.tl")

  -- Write input file
  assert(cosmo.Barf(input_file, extracted_json), "failed to write input file")

  -- Run the runner
  local runner = require("build.doctest.runner")
  local extracted, err = runner.load_extracted(input_file)
  assert(extracted, "failed to load extracted: " .. tostring(err))
  assert(extracted.source == "lib/cosmic/example.tl", "wrong source path")
  assert(#extracted.examples == 2, "expected 2 examples")

  local test, gen_err = runner.generate_test(extracted)
  assert(test, "failed to generate test: " .. tostring(gen_err))
  assert(test.test_count == 2, "wrong test count")
  assert(test.content:find("#!/usr/bin/env cosmic"), "missing shebang")
  assert(test.content:find("simple addition"), "missing first example")
  assert(test.content:find("string concatenation"), "missing second example")
  assert(test.content:find("test_count"), "missing test counter")
  assert(test.content:find("pass_count"), "missing pass counter")
  assert(test.content:find("os.exit"), "missing exit call")
end
test_basic_generation()

-- Test 2: Examples with setup and teardown
local function test_setup_teardown()
  local extracted_json = [[{
  "source": "lib/cosmic/spawn.tl",
  "examples": [
    {
      "title": "spawn with setup",
      "setup": "local spawn = require('cosmic.spawn')",
      "code": "local handle = spawn({'echo', 'test'})\nassert(handle ~= nil)",
      "teardown": "-- cleanup",
      "line": 50
    }
  ]
}]]

  local input_file = path.join(test_dir, "test2.doctest.extracted")

  assert(cosmo.Barf(input_file, extracted_json), "failed to write input file")

  local runner = require("build.doctest.runner")
  local extracted, err = runner.load_extracted(input_file)
  assert(extracted, "failed to load: " .. tostring(err))

  local test, gen_err = runner.generate_test(extracted)
  assert(test, "failed to generate: " .. tostring(gen_err))
  assert(test.content:find("Setup"), "missing setup section")
  assert(test.content:find("Teardown"), "missing teardown section")
  assert(test.content:find("local spawn = require"), "missing setup code")
  assert(test.content:find("cleanup"), "missing teardown code")
end
test_setup_teardown()

-- Test 3: String escaping
local function test_string_escaping()
  local runner = require("build.doctest.runner")

  -- Test simple string
  local escaped = runner.escape_lua_string("hello world")
  assert(escaped == "[[hello world]]", "simple string failed")

  -- Test string with ]] (should use quoted form)
  escaped = runner.escape_lua_string("test ]] end")
  assert(escaped:find('^"'), "should use quoted form for ]]")
  assert(escaped:find('"$'), "should close quoted form")

  -- Test string with special characters
  escaped = runner.escape_lua_string('line1\nline2\ttab')
  assert(escaped, "escaping special chars failed")
end
test_string_escaping()

-- Test 4: Error handling for invalid JSON
local function test_invalid_json()
  local input_file = path.join(test_dir, "invalid.doctest.extracted")
  assert(cosmo.Barf(input_file, "not valid json {{{"), "failed to write")

  local runner = require("build.doctest.runner")
  local extracted, err = runner.load_extracted(input_file)
  assert(not extracted, "should fail on invalid JSON")
  assert(err and err:find("parse"), "should report parse error")
end
test_invalid_json()

-- Test 5: Error handling for missing required fields
local function test_missing_fields()
  local input_file = path.join(test_dir, "missing.doctest.extracted")
  assert(cosmo.Barf(input_file, '{"examples": []}'), "failed to write")

  local runner = require("build.doctest.runner")
  local extracted, err = runner.load_extracted(input_file)
  assert(not extracted, "should fail on missing source")
  assert(err and err:find("source"), "should report missing source")
end
test_missing_fields()

-- Test 6: Empty examples list
local function test_empty_examples()
  local input_file = path.join(test_dir, "empty.doctest.extracted")
  assert(cosmo.Barf(input_file, '{"source": "test.tl", "examples": []}'), "failed to write")

  local runner = require("build.doctest.runner")
  local extracted, err = runner.load_extracted(input_file)
  assert(extracted, "should load empty examples")
  assert(#extracted.examples == 0, "should have no examples")

  local test, gen_err = runner.generate_test(extracted)
  assert(not test, "should not generate test for empty examples")
  assert(gen_err and gen_err:find("no examples"), "should report no examples")
end
test_empty_examples()

-- Test 7: Generated test structure
local function test_generated_structure()
  local extracted_json = [[{
  "source": "test.tl",
  "examples": [{
    "title": "test",
    "code": "assert(true)"
  }]
}]]

  local input_file = path.join(test_dir, "structure.doctest.extracted")
  assert(cosmo.Barf(input_file, extracted_json), "failed to write")

  local runner = require("build.doctest.runner")
  local extracted = runner.load_extracted(input_file)
  local test = runner.generate_test(extracted)

  -- Verify structure
  local content = test.content
  assert(content:match("test_count = 0"), "should initialize test_count")
  assert(content:match("pass_count = 0"), "should initialize pass_count")
  assert(content:match("fail_count = 0"), "should initialize fail_count")
  assert(content:match("test_count = test_count %+ 1"), "should increment test_count")
  assert(content:match("pcall%(function%(%)"), "should use pcall")
  assert(content:match("if ok then"), "should check pcall result")
  assert(content:match("pass_count = pass_count %+ 1"), "should increment pass on success")
  assert(content:match("fail_count = fail_count %+ 1"), "should increment fail on error")
  assert(content:match("io%.stderr:write"), "should write to stderr on failure")
  assert(content:match("if fail_count > 0 then"), "should check for failures")
  assert(content:match("os%.exit%(1%)"), "should exit 1 on failure")
  assert(content:match("os%.exit%(0%)"), "should exit 0 on success")
end
test_generated_structure()

print("All doctest runner tests passed!")
