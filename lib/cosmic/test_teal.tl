#!/usr/bin/env run-test.lua
-- test cosmic teal compilation and checking (--compile and --check)

local unix = require("cosmo.unix")
local path = require("cosmo.path")
local spawn = require("cosmic.spawn")
local cosmo = require("cosmo")

local cosmic = path.join(os.getenv("TEST_BIN"), "cosmic")
local tmpdir = os.getenv("TEST_TMPDIR")

-- Helper to create a temp file with content
local function write_temp(name: string, content: string): string
  local filepath = path.join(tmpdir, name)
  cosmo.Barf(filepath, content)
  return filepath
end

-- Helper to read a file
local function read_file(filepath: string): string
  return cosmo.Slurp(filepath)
end

-- ============================================================
-- --compile tests
-- ============================================================

-- Test basic compilation of valid Teal file
local function test_compile_basic()
  local input = write_temp("basic.tl", [[
local x: number = 42
print(x)
]])

  local ok, out = spawn({cosmic, "--compile", input}):read()
  assert(ok, "cosmic --compile should succeed")
  -- Output should be valid Lua (no type annotations)
  assert(not (out as string):find(": number"), "output should not contain type annotations")
  assert((out as string):find("local x = 42"), "output should contain compiled Lua")
end
test_compile_basic()

-- Test compilation of file with syntax error
local function test_compile_syntax_error()
  local input = write_temp("syntax_error.tl", [[
if if if
]])

  local ok, out = spawn({cosmic, "--compile", input}):read()
  assert(not ok, "cosmic --compile should fail on syntax error")
end
test_compile_syntax_error()

-- Test compilation of file with type error (compile also type checks)
local function test_compile_type_error()
  local input = write_temp("compile_type_error.tl", [[
local x: number = "wrong type"
]])

  local ok, out = spawn({cosmic, "--compile", input}):read()
  assert(not ok, "cosmic --compile should fail on type error")
end
test_compile_type_error()

-- Test compilation outputs to stdout by default
local function test_compile_stdout()
  local input = write_temp("stdout.tl", [[
local msg: string = "hello stdout"
print(msg)
]])

  local ok, out = spawn({cosmic, "--compile", input}):read()
  assert(ok, "cosmic --compile should succeed")
  assert((out as string):find('local msg = "hello stdout"'), "stdout should contain compiled code")
end
test_compile_stdout()

-- Test compilation with records
local function test_compile_record()
  local input = write_temp("record.tl", [[
local record Point
  x: number
  y: number
end

local p: Point = { x = 10, y = 20 }
print(p.x, p.y)
]])

  local ok, out = spawn({cosmic, "--compile", input}):read()
  assert(ok, "cosmic --compile should succeed with records")
  -- Records compile to tables in Lua
  assert((out as string):find("local p = {"), "should compile record to table")
end
test_compile_record()

-- Test compilation with generics
local function test_compile_generics()
  local input = write_temp("generics.tl", [[
local function identity<T>(x: T): T
  return x
end
print(identity(42))
print(identity("hello"))
]])

  local ok, out = spawn({cosmic, "--compile", input}):read()
  assert(ok, "cosmic --compile should succeed with generics")
  -- Generics are erased in output
  assert((out as string):find("local function identity%(x%)"), "generics should be erased")
end
test_compile_generics()

-- Test missing input file
local function test_compile_missing_file()
  local ok, out = spawn({cosmic, "--compile", "/nonexistent/file.tl"}):read()
  assert(not ok, "cosmic --compile should fail on missing file")
end
test_compile_missing_file()

-- ============================================================
-- --check tests
-- ============================================================

-- Test check on valid Teal file
local function test_check_valid()
  local input = write_temp("valid.tl", [[
local x: number = 42
local y: string = "hello"
print(x, y)
]])

  local ok, out = spawn({cosmic, "--check", input}):read()
  assert(ok, "cosmic --check should succeed on valid file")
end
test_check_valid()

-- Test check detects type error
local function test_check_type_error()
  local input = write_temp("type_error.tl", [[
local x: number = "not a number"
]])

  local ok, out = spawn({cosmic, "--check", input}):read()
  assert(not ok, "cosmic --check should fail on type error")
end
test_check_type_error()

-- Test check on file with undefined variable
local function test_check_undefined_variable()
  local input = write_temp("undefined.tl", [[
local x: number = undefined_var
]])

  local ok, out = spawn({cosmic, "--check", input}):read()
  assert(not ok, "cosmic --check should fail on undefined variable")
end
test_check_undefined_variable()

-- Test check reports warnings (but succeeds)
local function test_check_warnings()
  local input = write_temp("warnings.tl", [[
local x: number = 42
-- x is unused, should generate warning but not fail
]])

  -- Warnings don't cause failure - only errors do
  local ok, out = spawn({cosmic, "--check", input}):read()
  -- Should succeed even with warnings
  assert(ok, "cosmic --check should succeed with only warnings")
end
test_check_warnings()

-- Test check on missing file
local function test_check_missing_file()
  local ok, out = spawn({cosmic, "--check", "/nonexistent/file.tl"}):read()
  assert(not ok, "cosmic --check should fail on missing file")
end
test_check_missing_file()

-- ============================================================
-- Edge cases and integration tests
-- ============================================================

-- Test that compiled output is executable (via shell redirection)
local function test_compiled_output_runs()
  local input = write_temp("runnable.tl", [[
local function add(a: number, b: number): number
  return a + b
end
print("result=" .. add(2, 3))
]])
  local output = path.join(tmpdir, "runnable.lua")

  -- Compile to stdout and capture it
  local ok, lua_code = spawn({cosmic, "--compile", input}):read()
  assert(ok, "compilation should succeed")

  -- Write compiled code to file
  cosmo.Barf(output, lua_code as string)

  -- Now run the compiled output
  local run_ok, run_out = spawn({cosmic, output}):read()
  assert(run_ok, "compiled output should run")
  assert((run_out as string):find("result=5"), "compiled code should produce correct output")
end
test_compiled_output_runs()

-- Test compile and check don't interfere with regular script execution
local function test_no_interference_with_scripts()
  local script = write_temp("regular.lua", [[
print("regular script")
]])

  local ok, out = spawn({cosmic, script}):read()
  assert(ok, "regular script should still work")
  assert((out as string):find("regular script"), "regular script should run")
end
test_no_interference_with_scripts()

-- Test help mentions compile and check
local function test_help_shows_options()
  local ok, out = spawn({cosmic, "--help"}):read()
  assert(ok, "cosmic --help should succeed")
  assert((out as string):find("%-%-compile") or (out as string):find("compile"),
    "help should mention --compile")
  assert((out as string):find("%-%-check") or (out as string):find("check"),
    "help should mention --check")
end
test_help_shows_options()

-- Test compile with require of cosmic module types
local function test_compile_with_cosmic_types()
  local input = write_temp("cosmic_types.tl", [[
local cosmo = require("cosmo")
local data: string = cosmo.Slurp("/dev/null") or ""
print("read " .. #data .. " bytes")
]])

  -- This tests that type definitions are available during compilation
  local ok, out = spawn({cosmic, "--compile", input}):read()
  assert(ok, "compile with cosmic types should succeed")
end
test_compile_with_cosmic_types()

-- Test check with cosmic module types
local function test_check_with_cosmic_types()
  local input = write_temp("cosmic_check.tl", [[
local cosmo = require("cosmo")
local path = require("cosmo.path")
local result: string = path.join("a", "b")
print(result)
]])

  local ok, out = spawn({cosmic, "--check", input}):read()
  assert(ok, "check with cosmic types should succeed")
end
test_check_with_cosmic_types()

print("All teal tests passed!")
