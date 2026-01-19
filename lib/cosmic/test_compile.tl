#!/usr/bin/env cosmic-lua
-- test cosmic --compile option

local path = require("cosmo.path")
local spawn = require("cosmic.spawn")
local cosmo = require("cosmo")

local cosmic = path.join(os.getenv("TEST_BIN"), "cosmic")
local tmpdir = os.getenv("TEST_TMPDIR")

local function write_temp(name: string, content: string): string
  local filepath = path.join(tmpdir, name)
  cosmo.Barf(filepath, content)
  return filepath
end

-- Test basic compilation of valid Teal file
local function test_compile_basic()
  local input = write_temp("basic.tl", [[
local x: number = 42
print(x)
]])

  local ok, out = spawn({cosmic, "--compile", input}):read()
  assert(ok, "cosmic --compile should succeed")
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

-- Test compilation of file with type error
local function test_compile_type_error()
  local input = write_temp("compile_type_error.tl", [[
local x: number = "wrong type"
]])

  local ok, out = spawn({cosmic, "--compile", input}):read()
  assert(not ok, "cosmic --compile should fail on type error")
end
test_compile_type_error()

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
]])

  local ok, out = spawn({cosmic, "--compile", input}):read()
  assert(ok, "cosmic --compile should succeed with generics")
  assert((out as string):find("local function identity%(x%)"), "generics should be erased")
end
test_compile_generics()

-- Test missing input file
local function test_compile_missing_file()
  local ok, out = spawn({cosmic, "--compile", "/nonexistent/file.tl"}):read()
  assert(not ok, "cosmic --compile should fail on missing file")
end
test_compile_missing_file()

-- Test that compiled output is executable
local function test_compiled_output_runs()
  local input = write_temp("runnable.tl", [[
local function add(a: number, b: number): number
  return a + b
end
print("result=" .. add(2, 3))
]])
  local output = path.join(tmpdir, "runnable.lua")

  local ok, lua_code = spawn({cosmic, "--compile", input}):read()
  assert(ok, "compilation should succeed")

  cosmo.Barf(output, lua_code as string)

  local run_ok, run_out = spawn({cosmic, output}):read()
  assert(run_ok, "compiled output should run")
  assert((run_out as string):find("result=5"), "compiled code should produce correct output")
end
test_compiled_output_runs()

-- Test compile with cosmic module types
local function test_compile_with_cosmic_types()
  local input = write_temp("cosmic_types.tl", [[
local cosmo = require("cosmo")
local data: string = cosmo.Slurp("/dev/null") or ""
print("read " .. #data .. " bytes")
]])

  local ok, out = spawn({cosmic, "--compile", input}):read()
  assert(ok, "compile with cosmic types should succeed")
end
test_compile_with_cosmic_types()

print("All compile tests passed!")
