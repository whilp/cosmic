#!/usr/bin/env cosmic
local cosmo = require("cosmo")
local path = require("cosmo.path")
local spawn = require("cosmic.spawn")

local lua_bin = path.join(os.getenv("TEST_BIN"), "cosmic")
local TEST_TMPDIR = os.getenv("TEST_TMPDIR")

local function test_simple_command()
  local handle = spawn({lua_bin, "-e", "print('hello')"})
  assert(handle ~= nil, "handle should not be nil")
  local ok, out = handle:read()
  assert(ok, "command should succeed")
  assert(out == "hello\n", "expected 'hello\\n', got '" .. tostring(out) .. "'")
end
test_simple_command()

local function test_command_not_found()
  local handle, err = spawn({"nonexistent_command_12345"})
  assert(handle == nil, "handle should be nil for nonexistent command")
  assert(err:find("command not found", 1, true), "expected 'command not found' in error: " .. tostring(err))
end
test_command_not_found()

local function test_wait_returns_exit_code()
  local handle = spawn({lua_bin, "-e", "os.exit(0)"})
  assert(handle ~= nil, "handle should not be nil")
  local exit_code = handle:wait()
  assert(exit_code == 0, "expected exit code 0, got " .. tostring(exit_code))

  handle = spawn({lua_bin, "-e", "os.exit(1)"})
  assert(handle ~= nil, "handle should not be nil")
  exit_code = handle:wait()
  assert(exit_code == 1, "expected exit code 1, got " .. tostring(exit_code))
end
test_wait_returns_exit_code()

local function test_wait_drains_stdout_to_avoid_sigpipe()
  local tmp_file = path.join(TEST_TMPDIR, "checkfile")
  local tmp_target = path.join(TEST_TMPDIR, "target")

  local f = io.open(tmp_target, "w")
  f:write("test content\n")
  f:close()

  -- compute sha256 using cosmo (returns hex)
  local content = "test content\n"
  local expected_sha = cosmo.EncodeHex(cosmo.Sha256(content))

  f = io.open(tmp_file, "w")
  f:write(expected_sha .. "  " .. tmp_target .. "\n")
  f:close()

  -- verify using lua script that reads file and computes hash
  local script = string.format([[
    local cosmo = require("cosmo")
    local f = io.open(%q, "r")
    local content = f:read("*a")
    f:close()
    local hash = cosmo.EncodeHex(cosmo.Sha256(content))
    f = io.open(%q, "r")
    local expected = f:read("*l"):match("^(%%x+)")
    f:close()
    if hash == expected then os.exit(0) else os.exit(1) end
  ]], tmp_target, tmp_file)

  local handle = spawn({lua_bin, "-e", script})
  assert(handle ~= nil, "handle should not be nil")

  local exit_code, err = handle:wait()
  assert(exit_code == 0, "sha check should exit 0, got: " .. tostring(err))
end
test_wait_drains_stdout_to_avoid_sigpipe()

local function test_stdin_string()
  local handle = spawn({lua_bin, "-e", "io.write(io.read('*a'))"}, {stdin = "hello from stdin"})
  assert(handle ~= nil, "handle should not be nil")
  local ok, out = handle:read()
  assert(ok, "command should succeed")
  assert(out == "hello from stdin", "expected 'hello from stdin', got '" .. tostring(out) .. "'")
end
test_stdin_string()

local function test_read_captures_output()
  local handle = spawn({lua_bin, "-e", [[io.write("line1\nline2\n")]]})
  assert(handle ~= nil, "handle should not be nil")
  local ok, out = handle:read()
  assert(ok, "command should succeed")
  assert(out == "line1\nline2\n", "expected 'line1\\nline2\\n', got '" .. tostring(out) .. "'")
end
test_read_captures_output()

local function test_fd_passthrough_stdout()
  -- passing stdout=1 means "inherit parent's stdout, don't capture"
  -- this tests the fix for close(1); dup(1) which fails when fd equals target
  local tmp_file = path.join(TEST_TMPDIR, "passthrough_test")
  local script = string.format([[
    local f = io.open(%q, "w")
    f:write("written")
    f:close()
  ]], tmp_file)

  local handle = spawn({lua_bin, "-e", script}, {stdout = 1})
  assert(handle ~= nil, "handle should not be nil")
  local exit_code = handle:wait()
  assert(exit_code == 0, "expected exit code 0, got " .. tostring(exit_code))

  -- verify the script actually ran by checking the file it wrote
  local f = io.open(tmp_file, "r")
  assert(f ~= nil, "script should have created file")
  local content = f:read("*a")
  f:close()
  assert(content == "written", "expected 'written', got '" .. tostring(content) .. "'")
end
test_fd_passthrough_stdout()

local function test_fd_passthrough_stderr()
  -- passing stderr=2 means "inherit parent's stderr, don't capture"
  local tmp_file = path.join(TEST_TMPDIR, "passthrough_stderr_test")
  local script = string.format([[
    local f = io.open(%q, "w")
    f:write("written")
    f:close()
  ]], tmp_file)

  local handle = spawn({lua_bin, "-e", script}, {stderr = 2})
  assert(handle ~= nil, "handle should not be nil")
  local exit_code = handle:wait()
  assert(exit_code == 0, "expected exit code 0, got " .. tostring(exit_code))

  local f = io.open(tmp_file, "r")
  assert(f ~= nil, "script should have created file")
  local content = f:read("*a")
  f:close()
  assert(content == "written", "expected 'written', got '" .. tostring(content) .. "'")
end
test_fd_passthrough_stderr()

local function test_cwd_option()
  -- test that cwd option changes the working directory of spawned process
  -- Use pwd command to verify the working directory
  local handle = spawn({"pwd"}, {cwd = TEST_TMPDIR})
  assert(handle ~= nil, "handle should not be nil")
  local ok, out, exit_code = handle:read()
  assert(ok, "command should succeed, exit code: " .. tostring(exit_code) .. ", output: '" .. tostring(out) .. "'")
  -- pwd output includes a trailing newline
  local pwd_output = out:gsub("\n$", "")
  assert(pwd_output == TEST_TMPDIR, "expected pwd to be '" .. TEST_TMPDIR .. "', got '" .. tostring(pwd_output) .. "'")
end
test_cwd_option()
