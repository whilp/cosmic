#!/usr/bin/env cosmic
--- Run a command and capture its output using cosmic.spawn.
---
--- Demonstrates:
--- - Spawning a process with arguments
--- - Capturing stdout
--- - Checking exit codes
--- - Error handling
---
--- Usage:
---   ./cosmic-lua examples/run-command.tl ls -la
---   ./cosmic-lua examples/run-command.tl git status

local cosmic = require("cosmic")
local spawn = require("cosmic.spawn")

cosmic.main(function(args: {string}, env: cosmic.Env): number, string
  -- Need at least one argument (the command to run)
  if #args < 2 then
    env.stderr:write("Usage: run-command.tl <command> [args...]\n")
    return 1
  end

  -- Build command array (skip args[1] which is the script name)
  local cmd: {string} = {}
  for i = 2, #args do
    table.insert(cmd, args[i])
  end

  env.stdout:write("Running: " .. table.concat(cmd, " ") .. "\n")
  env.stdout:write(string.rep("-", 60) .. "\n")

  -- Spawn the process
  local handle, err = spawn.spawn(cmd)

  if not handle then
    return 1, "Failed to spawn process: " .. (err or "unknown error")
  end

  -- Read output and wait for process to exit
  local ok, output, exit_code = handle:read()

  -- Print the output
  env.stdout:write(output)

  -- Check exit status
  if ok then
    env.stdout:write(string.rep("-", 60) .. "\n")
    env.stdout:write("Command succeeded (exit code: " .. exit_code .. ")\n")
    return 0
  else
    env.stdout:write(string.rep("-", 60) .. "\n")
    return exit_code, "Command failed with exit code: " .. tostring(exit_code)
  end
end)
