-- cosmic.test: Test runner for cosmic-lua
-- Provides --test functionality

local cosmo = require("cosmo")
local path = require("cosmo.path")

local record TestResult
  ok: boolean        -- true if test ran (even if assertions failed)
  status: string     -- "pass" or "fail"
  message: string    -- error message if failed
  stdout: string     -- captured stdout
  stderr: string     -- captured stderr
end

-- Capture output during function execution
local function capture_output(func: function(): boolean, string): boolean, string, string, string
  -- Create temporary files for capturing stdout/stderr
  local tmpdir = os.getenv("TMPDIR") or "/tmp"
  local stdout_file = path.join(tmpdir, "test_stdout_" .. os.time() .. "_" .. math.random(99999))
  local stderr_file = path.join(tmpdir, "test_stderr_" .. os.time() .. "_" .. math.random(99999))

  -- Save original stdout/stderr and print function
  local orig_stdout = io.output()
  local orig_stderr = io.stderr
  local orig_print = print

  -- Redirect to temp files
  local out_f = io.open(stdout_file, "w")
  local err_f = io.open(stderr_file, "w")

  if not out_f or not err_f then
    return false, "failed to create temp files", "", ""
  end

  io.output(out_f)
  io.stderr = err_f

  -- Override print to use redirected stdout
  _G.print = function(...: any)
    local args = {...}
    local strs: {string} = {}
    for i, v in ipairs(args) do
      strs[i] = tostring(v)
    end
    out_f:write(table.concat(strs, "\t"))
    out_f:write("\n")
  end

  -- Execute function
  local ok, result = pcall(func)

  -- Restore original streams and print
  _G.print = orig_print
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

-- Run a test file
-- Returns: TestResult with ok, status, message, stdout, stderr
local function run(input_path: string): TestResult
  -- Load the test file
  local chunk, err = loadfile(input_path)
  if not chunk then
    return {
      ok = false,
      status = "fail",
      message = "failed to load test: " .. err,
      stdout = "",
      stderr = err,
    }
  end

  -- Execute the test with output capture
  local ok, result, stdout, stderr = capture_output(chunk as function(): boolean, string)

  if ok then
    -- Test passed
    return {
      ok = true,
      status = "pass",
      message = "",
      stdout = stdout,
      stderr = stderr,
    }
  else
    -- Test failed (assertions failed, but test ran)
    local error_msg = tostring(result)
    return {
      ok = true,  -- Test infrastructure worked, even though assertions failed
      status = "fail",
      message = "test assertion failed",
      stdout = stdout,
      stderr = error_msg,
    }
  end
end

-- Format test result for output
local function format_result(result: TestResult): string
  local lines: {string} = {}

  if result.message and result.message ~= "" then
    table.insert(lines, result.status .. ": " .. result.message)
  else
    table.insert(lines, result.status)
  end

  table.insert(lines, "")
  table.insert(lines, "## stdout")
  table.insert(lines, "")
  table.insert(lines, result.stdout or "")
  table.insert(lines, "## stderr")
  table.insert(lines, "")
  table.insert(lines, result.stderr or "")

  return table.concat(lines, "\n")
end

return {
  run = run,
  format_result = format_result,
}
