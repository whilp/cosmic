#!/usr/bin/env run-test.lua
-- test cosmic --test option with shebang usage

local unix = require("cosmo.unix")
local path = require("cosmo.path")
local spawn = require("cosmic.spawn")
local cosmo = require("cosmo")

local cosmic = path.join(os.getenv("TEST_BIN"), "cosmic")
local tmpdir = os.getenv("TEST_TMPDIR")

-- Test shebang with --test option (passing test)
local function test_shebang_passing()
  local test_file = path.join(tmpdir, "shebang_passing.lua")
  cosmo.Barf(test_file, string.format([[#!/usr/bin/env -S %s --test

print("Running test with shebang")
assert(1 + 1 == 2, "basic math")
print("Test completed successfully")
]], cosmic))

  -- Make file executable
  unix.chmod(test_file, tonumber("755", 8))

  -- Execute directly via shebang
  local ok, out = spawn({test_file}):read()
  assert(ok, "shebang test should exit 0 for passing test")
  assert((out as string):find("pass"), "output should contain 'pass' status")
  assert((out as string):find("Running test with shebang"), "stdout should be captured")
  assert((out as string):find("Test completed successfully"), "test should complete")
end
test_shebang_passing()

-- Test shebang with --test option (failing test)
local function test_shebang_failing()
  local test_file = path.join(tmpdir, "shebang_failing.lua")
  cosmo.Barf(test_file, string.format([[#!/usr/bin/env -S %s --test

print("Test started via shebang")
assert(false, "intentional shebang failure")
print("Should not reach here")
]], cosmic))

  -- Make file executable
  unix.chmod(test_file, tonumber("755", 8))

  -- Execute directly via shebang
  local ok, out = spawn({test_file}):read()
  assert(ok, "shebang test should exit 0 even for failing test")
  assert((out as string):find("fail"), "output should contain 'fail' status")
  assert((out as string):find("Test started via shebang"), "stdout before failure should be captured")
  assert((out as string):find("intentional shebang failure"), "error message should be in output")
end
test_shebang_failing()

-- Test shebang with test that prints to stderr
local function test_shebang_stderr()
  local test_file = path.join(tmpdir, "shebang_stderr.lua")
  cosmo.Barf(test_file, string.format([[#!/usr/bin/env -S %s --test

print("stdout message")
io.stderr:write("stderr message\n")
assert(true, "test passes")
]], cosmic))

  -- Make file executable
  unix.chmod(test_file, tonumber("755", 8))

  -- Execute
  local ok, out = spawn({test_file}):read()
  assert(ok, "shebang test should succeed")
  assert((out as string):find("pass"), "test should pass")
  assert((out as string):find("## stdout"), "should have stdout section")
  assert((out as string):find("## stderr"), "should have stderr section")
  assert((out as string):find("stdout message"), "stdout should be captured")
  assert((out as string):find("stderr message"), "stderr should be captured")
end
test_shebang_stderr()

-- Test shebang execution is equivalent to direct --test call
local function test_shebang_equivalence()
  local test_file = path.join(tmpdir, "shebang_equiv.lua")
  local test_content = [[
print("equivalence test")
assert(1 + 1 == 2)
print("done")
]]

  -- Create version with shebang
  cosmo.Barf(test_file, string.format([[#!/usr/bin/env -S %s --test
%s]], cosmic, test_content))
  unix.chmod(test_file, tonumber("755", 8))

  -- Create version without shebang
  local test_file_no_shebang = path.join(tmpdir, "no_shebang_equiv.lua")
  cosmo.Barf(test_file_no_shebang, test_content)

  -- Execute via shebang
  local ok1, out1 = spawn({test_file}):read()
  assert(ok1, "shebang execution should succeed")

  -- Execute via explicit --test
  local ok2, out2 = spawn({cosmic, "--test", test_file_no_shebang}):read()
  assert(ok2, "explicit --test should succeed")

  -- Both should have pass status
  assert((out1 as string):find("pass"), "shebang version should pass")
  assert((out2 as string):find("pass"), "explicit version should pass")

  -- Both should capture same output
  assert((out1 as string):find("equivalence test"), "shebang should capture stdout")
  assert((out2 as string):find("equivalence test"), "explicit should capture stdout")
end
test_shebang_equivalence()

print("All shebang tests passed")
