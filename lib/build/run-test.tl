#!/usr/bin/env lua
-- Test runner wrapper that executes a test and reports pass/fail status

local common = require("checker.common")
local cosmo = require("cosmo")
local path = require("cosmo.path")

local function capture_output(func: function(): boolean, string): boolean, string, string, string
  -- Create temporary files for capturing stdout/stderr
  local tmpdir = os.getenv("TMPDIR") or "/tmp"
  local stdout_file = path.join(tmpdir, "test_stdout_" .. os.time() .. "_" .. math.random(99999))
  local stderr_file = path.join(tmpdir, "test_stderr_" .. os.time() .. "_" .. math.random(99999))

  -- Save original stdout/stderr
  local orig_stdout = io.output()
  local orig_stderr = io.stderr

  -- Redirect to temp files
  local out_f = io.open(stdout_file, "w")
  local err_f = io.open(stderr_file, "w")

  if not out_f or not err_f then
    return false, "failed to create temp files", "", ""
  end

  io.output(out_f)
  io.stderr = err_f

  -- Execute function
  local ok, result = pcall(func)

  -- Restore original streams
  io.output(orig_stdout)
  io.stderr = orig_stderr
  out_f:close()
  err_f:close()

  -- Read captured output
  local stdout_content = cosmo.Slurp(stdout_file) or ""
  local stderr_content = cosmo.Slurp(stderr_file) or ""

  -- Clean up temp files
  os.remove(stdout_file)
  os.remove(stderr_file)

  return ok, result, stdout_content, stderr_content
end

local function main(...: string): number
  local args = {...}
  if #args == 0 then
    io.stderr:write("usage: run-test.lua TEST_FILE\n")
    return 1
  end

  local test_file = args[1]

  -- Load the test file
  local chunk, err = loadfile(test_file)
  if not chunk then
    common.write_result("fail", "failed to load test: " .. err, "", err, test_file)
    return 1
  end

  -- Execute the test with output capture
  local ok, result, stdout, stderr = capture_output(chunk as function(): boolean, string)

  if ok then
    -- Test passed
    common.write_result("pass", "", stdout, stderr, test_file)
    return 0
  else
    -- Test failed
    local error_msg = tostring(result)
    common.write_result("fail", "test assertion failed", stdout, error_msg, test_file)
    return 1
  end
end

if cosmo.is_main() then
  os.exit(main(...))
end
