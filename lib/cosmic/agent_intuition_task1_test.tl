#!/usr/bin/env cosmic
--- Agent Intuition Test: Task 1 - Fetch URL and Parse JSON
--- Tests whether a fresh agent can learn HTTP and JSON APIs using only --help and --docs

local cosmo = require("cosmo")
local path = require("cosmo.path")
local spawn = require("cosmic.spawn")

-- Skip unless RUN_AGENT_TESTS is set
if not os.getenv("RUN_AGENT_TESTS") then
  print("SKIP: Agent intuition tests require RUN_AGENT_TESTS=1")
  print("      These tests spawn fresh agents with claude -p")
  print("      Set RUN_AGENT_TESTS=1 to run them")
  os.exit(0)
end

-- Check if claude is available
local claude_check = spawn.spawn({"claude", "--version"})
local ok, output = claude_check:read()
if not ok then
  print("SKIP: claude CLI not found (required for agent tests)")
  os.exit(0)
end

local TEST_TMPDIR = os.getenv("TEST_TMPDIR") or "/tmp"
local TEST_BIN = os.getenv("TEST_BIN") or "o/bin"
local cosmic_bin = path.join(TEST_BIN, "cosmic")

-- Ensure cosmic binary exists
local f = io.open(cosmic_bin, "r")
if not f then
  print("ERROR: cosmic binary not found at " .. cosmic_bin)
  os.exit(1)
end
f:close()

print("=== Agent Intuition Test: Task 1 - Fetch URL and Parse JSON ===")

-- Create isolated sandbox
local sandbox = path.join(TEST_TMPDIR, "agent_task1_" .. os.time())
os.execute("mkdir -p " .. sandbox)

-- Copy cosmic binary to sandbox
os.execute("cp " .. cosmic_bin .. " " .. sandbox .. "/cosmic-lua")
os.execute("chmod +x " .. sandbox .. "/cosmic-lua")

-- Task prompt for the agent
local task_prompt = [[
You are in an isolated sandbox testing agent intuition.

CRITICAL CONSTRAINTS:
1. You can ONLY learn about cosmic-lua by running:
   - ./cosmic-lua --help
   - ./cosmic-lua --docs <query>
2. You CANNOT read source code or use Grep/Glob
3. You CAN write .lua files and run them with ./cosmic-lua

TASK:
Write a Lua script called "solution.lua" that:
1. Fetches https://api.github.com/repos/jart/cosmopolitan
2. Parses the JSON response
3. Prints ONLY these two lines (no extra output):
   Repository: <full_name>
   Stars: <stargazers_count>

Example expected output:
Repository: jart/cosmopolitan
Stars: 20475

Start by exploring with --help and --docs to discover HTTP and JSON capabilities.
Create solution.lua and test it works.
]]

-- Write task prompt to file
local prompt_file = path.join(sandbox, "task_prompt.txt")
local f = io.open(prompt_file, "w")
f:write(task_prompt)
f:close()

print("Sandbox: " .. sandbox)
print("Spawning agent with claude -p...")

-- Run agent with claude -p
local agent_handle = spawn.spawn({
  "claude",
  "-p", task_prompt,
  "-w", sandbox
})

local agent_ok, agent_output, agent_exit = agent_handle:read()

if not agent_ok or agent_exit ~= 0 then
  print("ERROR: Agent failed to complete task")
  print("Exit code: " .. tostring(agent_exit))
  print("Output: " .. tostring(agent_output))
  os.exit(1)
end

print("Agent completed. Output length: " .. #agent_output .. " bytes")

-- Check if solution.lua was created
local solution_file = path.join(sandbox, "solution.lua")
local sol_f = io.open(solution_file, "r")
if not sol_f then
  print("ERROR: Agent did not create solution.lua")
  os.exit(1)
end
sol_f:close()

print("solution.lua created, testing it...")

-- Run the solution
local solution_handle = spawn.spawn({
  path.join(sandbox, "cosmic-lua"),
  "solution.lua"
}, {cwd = sandbox})

local sol_ok, sol_output, sol_exit = solution_handle:read()

if not sol_ok or sol_exit ~= 0 then
  print("ERROR: Solution failed to run")
  print("Exit code: " .. tostring(sol_exit))
  print("Output: " .. tostring(sol_output))
  os.exit(1)
end

print("Solution output:")
print(sol_output)

-- Grade the solution with another claude -p call
local grader_prompt = [[
Grade this agent's solution to the task:

TASK: Fetch https://api.github.com/repos/jart/cosmopolitan and print repository name and stars.

EXPECTED OUTPUT FORMAT:
Repository: jart/cosmopolitan
Stars: <number>

ACTUAL OUTPUT:
]] .. sol_output .. [[

GRADING CRITERIA:
1. Does output include "Repository: jart/cosmopolitan"?
2. Does output include "Stars: " followed by a number?
3. Was the agent able to complete this using only cosmic-lua documentation?

Respond with exactly one line:
PASS - <brief reason>
or
FAIL - <brief reason>
]]

print("\nGrading with claude -p...")

local grader_handle = spawn.spawn({
  "claude",
  "-p", grader_prompt
})

local grader_ok, grader_output, grader_exit = grader_handle:read()

if not grader_ok or grader_exit ~= 0 then
  print("ERROR: Grader failed")
  print("Exit code: " .. tostring(grader_exit))
  os.exit(1)
end

print("Grader output:")
print(grader_output)

-- Parse grader output
local grade_line = grader_output:match("^(PASS[^\n]*)")
if not grade_line then
  grade_line = grader_output:match("^(FAIL[^\n]*)")
end

if not grade_line then
  print("ERROR: Could not parse grader output")
  os.exit(1)
end

-- Cleanup
os.execute("rm -rf " .. sandbox)

if grade_line:match("^PASS") then
  print("\n✓ Test PASSED: " .. grade_line)
  os.exit(0)
else
  print("\n✗ Test FAILED: " .. grade_line)
  os.exit(1)
end
