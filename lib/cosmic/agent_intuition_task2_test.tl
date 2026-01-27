#!/usr/bin/env cosmic
--- Agent Intuition Test: Task 2 - Spawn Subprocess
--- Tests whether a fresh agent can learn process spawning using only --help and --docs

local cosmo = require("cosmo")
local path = require("cosmo.path")
local spawn = require("cosmic.spawn")

-- Skip unless RUN_AGENT_TESTS is set
if not os.getenv("RUN_AGENT_TESTS") then
  print("SKIP: Agent intuition tests require RUN_AGENT_TESTS=1")
  os.exit(0)
end

-- Check if claude is available
local claude_check = spawn.spawn({"claude", "--version"})
local ok, output = claude_check:read()
if not ok then
  print("SKIP: claude CLI not found")
  os.exit(0)
end

local TEST_TMPDIR = os.getenv("TEST_TMPDIR") or "/tmp"
local TEST_BIN = os.getenv("TEST_BIN") or "o/bin"
local cosmic_bin = path.join(TEST_BIN, "cosmic")

print("=== Agent Intuition Test: Task 2 - Spawn Subprocess ===")

-- Create isolated sandbox
local sandbox = path.join(TEST_TMPDIR, "agent_task2_" .. os.time())
os.execute("mkdir -p " .. sandbox)
os.execute("cp " .. cosmic_bin .. " " .. sandbox .. "/cosmic-lua")
os.execute("chmod +x " .. sandbox .. "/cosmic-lua")

-- Task prompt
local task_prompt = [[
You are in an isolated sandbox testing agent intuition.

CONSTRAINTS:
- Learn using: ./cosmic-lua --help and ./cosmic-lua --docs <query>
- CANNOT read source code or use Grep/Glob
- CAN write .lua files and run them

TASK:
Write "solution.lua" that:
1. Spawns the command: echo "Hello from subprocess"
2. Captures the output
3. Prints exactly: "Output: Hello from subprocess"

Create solution.lua and verify it works.
]]

print("Sandbox: " .. sandbox)
print("Spawning agent...")

-- Run agent
local agent_handle = spawn.spawn({
  "claude", "-p", task_prompt, "-w", sandbox
})
local agent_ok, agent_output, agent_exit = agent_handle:read()

if not agent_ok or agent_exit ~= 0 then
  print("ERROR: Agent failed")
  os.exit(1)
end

-- Check solution exists
local solution_file = path.join(sandbox, "solution.lua")
local f = io.open(solution_file, "r")
if not f then
  print("ERROR: No solution.lua created")
  os.exit(1)
end
f:close()

print("Testing solution...")

-- Run solution
local sol_handle = spawn.spawn({
  path.join(sandbox, "cosmic-lua"), "solution.lua"
}, {cwd = sandbox})
local sol_ok, sol_output, sol_exit = sol_handle:read()

if not sol_ok or sol_exit ~= 0 then
  print("ERROR: Solution failed")
  print("Output: " .. tostring(sol_output))
  os.exit(1)
end

print("Solution output:")
print(sol_output)

-- Grade
local grader_prompt = [[
Grade this solution:

TASK: Spawn "echo Hello from subprocess" and print the output.
EXPECTED: Line containing "Hello from subprocess"
ACTUAL OUTPUT:
]] .. sol_output .. [[

Respond: PASS - reason  OR  FAIL - reason
]]

local grader_handle = spawn.spawn({"claude", "-p", grader_prompt})
local grader_ok, grader_output = grader_handle:read()

if not grader_ok then
  print("ERROR: Grader failed")
  os.exit(1)
end

print("\nGrader: " .. grader_output)

-- Cleanup
os.execute("rm -rf " .. sandbox)

-- Determine result
if grader_output:match("^PASS") then
  print("\n✓ Test PASSED")
  os.exit(0)
else
  print("\n✗ Test FAILED")
  os.exit(1)
end
