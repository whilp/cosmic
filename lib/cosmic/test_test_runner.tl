#!/usr/bin/env run-test.lua
-- test cosmic --test option for running tests

local path = require("cosmo.path")
local spawn = require("cosmic.spawn")
local cosmo = require("cosmo")

local cosmic = path.join(os.getenv("TEST_BIN"), "cosmic")
local tmpdir = os.getenv("TEST_TMPDIR")

-- Test basic --test execution with passing test
local function test_basic_passing_test()
  local test_file = path.join(tmpdir, "passing_test.lua")
  cosmo.Barf(test_file, [[
print("Test is running")
assert(1 + 1 == 2, "math works")
print("Test passed")
]])

  local ok, out = spawn({cosmic, "--test", test_file}):read()
  assert(ok, "cosmic --test should exit 0 for passing test")
  assert((out as string):find("pass"), "output should contain 'pass' status")
  assert((out as string):find("Test is running"), "output should contain test stdout")
  assert((out as string):find("Test passed"), "output should contain test completion message")
end
test_basic_passing_test()

-- Test --test execution with failing test
local function test_failing_test()
  local test_file = path.join(tmpdir, "failing_test.lua")
  cosmo.Barf(test_file, [[
print("Test started")
assert(false, "intentional failure")
print("This should not print")
]])

  local ok, out = spawn({cosmic, "--test", test_file}):read()
  assert(ok, "cosmic --test should exit 0 even for failing test")
  assert((out as string):find("fail"), "output should contain 'fail' status")
  assert((out as string):find("Test started"), "output should contain stdout before failure")
  assert((out as string):find("intentional failure"), "output should contain error message")
  assert(not (out as string):find("This should not print"), "should not print after failure")
end
test_failing_test()

-- Test --test with non-existent file (infrastructure error)
local function test_nonexistent_file()
  local test_file = path.join(tmpdir, "nonexistent.lua")

  local ok, out = spawn({cosmic, "--test", test_file}):read()
  assert(not ok, "cosmic --test should exit 1 for missing file")
  assert((out as string):find("fail"), "output should contain 'fail' status")
  assert((out as string):find("failed to load test"), "output should indicate load failure")
end
test_nonexistent_file()

-- Test --test with syntax error in test file
local function test_syntax_error()
  local test_file = path.join(tmpdir, "syntax_error.lua")
  cosmo.Barf(test_file, [[
print("Start test")
this is not valid lua syntax!!!
print("End test")
]])

  local ok, out = spawn({cosmic, "--test", test_file}):read()
  assert(not ok, "cosmic --test should exit 1 for syntax error")
  assert((out as string):find("fail"), "output should contain 'fail' status")
  assert((out as string):find("failed to load test"), "output should indicate load failure")
end
test_syntax_error()

-- Test --test output format (status, stdout, stderr sections)
local function test_output_format()
  local test_file = path.join(tmpdir, "output_format.lua")
  cosmo.Barf(test_file, [[
print("This goes to stdout")
io.stderr:write("This goes to stderr\n")
]])

  local ok, out = spawn({cosmic, "--test", test_file}):read()
  assert(ok, "cosmic --test should succeed")
  assert((out as string):find("pass"), "output should have pass status")
  assert((out as string):find("## stdout"), "output should have stdout section")
  assert((out as string):find("## stderr"), "output should have stderr section")
  assert((out as string):find("This goes to stdout"), "stdout should be captured")
  assert((out as string):find("This goes to stderr"), "stderr should be captured")
end
test_output_format()

-- Test --test with empty test file (should pass)
local function test_empty_file()
  local test_file = path.join(tmpdir, "empty.lua")
  cosmo.Barf(test_file, "")

  local ok, out = spawn({cosmic, "--test", test_file}):read()
  assert(ok, "cosmic --test should succeed for empty file")
  assert((out as string):find("pass"), "empty test should pass")
end
test_empty_file()

-- Test --test with multiple assertions
local function test_multiple_assertions()
  local test_file = path.join(tmpdir, "multiple_assertions.lua")
  cosmo.Barf(test_file, [[
assert(1 == 1, "first assertion")
print("First passed")
assert(2 == 2, "second assertion")
print("Second passed")
assert(3 == 3, "third assertion")
print("Third passed")
]])

  local ok, out = spawn({cosmic, "--test", test_file}):read()
  assert(ok, "cosmic --test should succeed")
  assert((out as string):find("pass"), "test should pass")
  assert((out as string):find("First passed"), "should reach first assertion")
  assert((out as string):find("Second passed"), "should reach second assertion")
  assert((out as string):find("Third passed"), "should reach third assertion")
end
test_multiple_assertions()

-- Test --test with failing assertion shows which one failed
local function test_failure_location()
  local test_file = path.join(tmpdir, "failure_location.lua")
  cosmo.Barf(test_file, [[
assert(1 == 1, "first assertion")
print("First passed")
assert(2 == 3, "second assertion should fail")
print("Should not print")
]])

  local ok, out = spawn({cosmic, "--test", test_file}):read()
  assert(ok, "cosmic --test should exit 0 for failing test")
  assert((out as string):find("fail"), "test should fail")
  assert((out as string):find("First passed"), "should complete first assertion")
  assert((out as string):find("second assertion should fail"), "error message should mention which assertion")
  assert(not (out as string):find("Should not print"), "should stop at failure")
end
test_failure_location()

print("All --test runner tests passed")
