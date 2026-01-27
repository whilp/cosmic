#!/usr/bin/env cosmic-lua
--- Agent Intuition Test Harness - Agent Spawning Script
--- This script spawns fresh subagents to test the Agent Intuition goal.
---
--- Usage:
---   Run this from a Claude Code session that can use the Task tool:
---   1. Ensure o/bin/cosmic is built
---   2. From Claude Code: "Run the agent intuition harness at test/agent_intuition/run_agent_harness.tl"
---
--- What it does:
---   - Creates isolated sandboxes for 6 tasks
---   - Spawns fresh subagents with no codebase access
---   - Agents can only use cosmic-lua --help and --docs
---   - Collects and reports results

local record Task
  id: number
  name: string
  prompt: string
end

local tasks: {Task} = {
  {
    id = 1,
    name = "Fetch URL and parse JSON",
    prompt = [[
AGENT INTUITION TEST - TASK 1: Fetch URL and Parse JSON

CONTEXT:
You are testing whether cosmic-lua's documentation is sufficient for an agent to learn the API.
You are in an isolated sandbox directory: /tmp/cosmic-agent-test-v2/task1
You have access to a binary called "cosmic-lua" in this directory.

CRITICAL CONSTRAINTS:
1. You CANNOT read any source code or project files
2. You CANNOT use Grep or Glob to search the codebase
3. You can ONLY learn about cosmic-lua by running:
   - ./cosmic-lua --help
   - ./cosmic-lua --docs <query>
4. You CAN write .lua files and execute them with ./cosmic-lua
5. You CAN use Bash but ONLY to run cosmic-lua commands

TASK:
Write a Lua script that:
1. Fetches the URL: https://api.github.com/repos/jart/cosmopolitan
2. Parses the JSON response
3. Prints the repository's full_name and stargazers_count

SUCCESS CRITERIA:
- Create a working script using ONLY knowledge from --help and --docs
- The script must run successfully with ./cosmic-lua
- Print the repository name and star count

IMPORTANT: Start by exploring what's available using --help and --docs to discover the HTTP and JSON capabilities.
]],
  },
  {
    id = 2,
    name = "Spawn subprocess",
    prompt = [[
AGENT INTUITION TEST - TASK 2: Spawn Subprocess and Capture Output

CONTEXT:
You are testing whether cosmic-lua's documentation is sufficient for an agent to learn the API.
You are in an isolated sandbox directory: /tmp/cosmic-agent-test-v2/task2
You have access to a binary called "cosmic-lua" in this directory.

CRITICAL CONSTRAINTS:
1. You CANNOT read any source code or project files
2. You CANNOT use Grep or Glob to search the codebase
3. You can ONLY learn about cosmic-lua by running:
   - ./cosmic-lua --help
   - ./cosmic-lua --docs <query>
4. You CAN write .lua files and execute them with ./cosmic-lua
5. You CAN use Bash but ONLY to run cosmic-lua commands

TASK:
Write a Lua script that:
1. Spawns the command "echo Hello from subprocess"
2. Captures the stdout output
3. Prints the captured output

SUCCESS CRITERIA:
- Create a working script using ONLY knowledge from --help and --docs
- The script must run successfully with ./cosmic-lua
- Print the captured subprocess output

IMPORTANT: Start by exploring what's available using --help and --docs to discover process spawning capabilities.
]],
  },
  {
    id = 3,
    name = "Walk directory tree",
    prompt = [[
AGENT INTUITION TEST - TASK 3: Walk Directory Tree with Pattern

CONTEXT:
You are testing whether cosmic-lua's documentation is sufficient for an agent to learn the API.
You are in an isolated sandbox directory: /tmp/cosmic-agent-test-v2/task3
You have access to a binary called "cosmic-lua" in this directory.

CRITICAL CONSTRAINTS:
1. You CANNOT read any source code or project files
2. You CANNOT use Grep or Glob to search the codebase
3. You can ONLY learn about cosmic-lua by running:
   - ./cosmic-lua --help
   - ./cosmic-lua --docs <query>
4. You CAN write .lua files and execute them with ./cosmic-lua
5. You CAN use Bash but ONLY to run cosmic-lua commands

TASK:
Write a Lua script that:
1. Creates a few test .txt files in the current directory
2. Walks the directory tree
3. Finds and prints all .txt files

SUCCESS CRITERIA:
- Create a working script using ONLY knowledge from --help and --docs
- The script must run successfully with ./cosmic-lua
- Successfully find and list .txt files using pattern matching

IMPORTANT: Start by exploring what's available using --help and --docs to discover directory walking capabilities.
]],
  },
  {
    id = 4,
    name = "SQLite operations",
    prompt = [[
AGENT INTUITION TEST - TASK 4: SQLite Database Operations

CONTEXT:
You are testing whether cosmic-lua's documentation is sufficient for an agent to learn the API.
You are in an isolated sandbox directory: /tmp/cosmic-agent-test-v2/task4
You have access to a binary called "cosmic-lua" in this directory.

CRITICAL CONSTRAINTS:
1. You CANNOT read any source code or project files
2. You CANNOT use Grep or Glob to search the codebase
3. You can ONLY learn about cosmic-lua by running:
   - ./cosmic-lua --help
   - ./cosmic-lua --docs <query>
4. You CAN write .lua files and execute them with ./cosmic-lua
5. You CAN use Bash but ONLY to run cosmic-lua commands

TASK:
Write a Lua script that:
1. Creates an in-memory SQLite database
2. Creates a table with at least 2 columns
3. Inserts 2 rows of data
4. Queries and prints the data

SUCCESS CRITERIA:
- Create a working script using ONLY knowledge from --help and --docs
- The script must run successfully with ./cosmic-lua
- Successfully demonstrate SQLite operations

IMPORTANT: Start by exploring what's available using --help and --docs to discover database capabilities.
]],
  },
  {
    id = 5,
    name = "Parse arguments",
    prompt = [[
AGENT INTUITION TEST - TASK 5: Parse Command-Line Arguments

CONTEXT:
You are testing whether cosmic-lua's documentation is sufficient for an agent to learn the API.
You are in an isolated sandbox directory: /tmp/cosmic-agent-test-v2/task5
You have access to a binary called "cosmic-lua" in this directory.

CRITICAL CONSTRAINTS:
1. You CANNOT read any source code or project files
2. You CANNOT use Grep or Glob to search the codebase
3. You can ONLY learn about cosmic-lua by running:
   - ./cosmic-lua --help
   - ./cosmic-lua --docs <query>
4. You CAN write .lua files and execute them with ./cosmic-lua
5. You CAN use Bash but ONLY to run cosmic-lua commands

TASK:
Write a Lua script that:
1. Parses command-line arguments with -h (help), -v (verbose), and -o <file> (output) options
2. Prints the parsed options
3. Test it by running with various arguments like: ./cosmic-lua script.lua -h -v -o output.txt file1 file2

SUCCESS CRITERIA:
- Create a working script using ONLY knowledge from --help and --docs
- The script must run successfully with ./cosmic-lua
- Successfully parse both short flags and options with values

IMPORTANT: Start by exploring what's available using --help and --docs to discover argument parsing capabilities.
]],
  },
  {
    id = 6,
    name = "Create ZIP archive",
    prompt = [[
AGENT INTUITION TEST - TASK 6: Create ZIP Archive

CONTEXT:
You are testing whether cosmic-lua's documentation is sufficient for an agent to learn the API.
You are in an isolated sandbox directory: /tmp/cosmic-agent-test-v2/task6
You have access to a binary called "cosmic-lua" in this directory.

CRITICAL CONSTRAINTS:
1. You CANNOT read any source code or project files
2. You CANNOT use Grep or Glob to search the codebase
3. You can ONLY learn about cosmic-lua by running:
   - ./cosmic-lua --help
   - ./cosmic-lua --docs <query>
4. You CAN write .lua files and execute them with ./cosmic-lua
5. You CAN use Bash but ONLY to run cosmic-lua commands

TASK:
Write a Lua script that:
1. Creates a ZIP archive file
2. Adds at least 2 text files to it
3. Verifies the ZIP was created by reading it back and listing its contents

SUCCESS CRITERIA:
- Create a working script using ONLY knowledge from --help and --docs
- The script must run successfully with ./cosmic-lua
- Successfully create and verify a ZIP archive

IMPORTANT: Start by exploring what's available using --help and --docs to discover ZIP/archive capabilities.
]],
  },
}

print("Agent Intuition Test Harness")
print("=============================")
print("")
print("This script should be referenced from a Claude Code session.")
print("It defines the " .. #tasks .. " tasks that fresh agents should attempt.")
print("")
print("To run the harness:")
print("  1. From a Claude Code session, say:")
print("     'Spawn " .. #tasks .. " fresh subagents to test the agent intuition goal'")
print("  2. Reference this file for task definitions")
print("  3. For each task:")
print("     - Create sandbox at /tmp/cosmic-agent-test-v2/taskN")
print("     - Copy o/bin/cosmic to sandbox/cosmic-lua")
print("     - Spawn agent with Task tool using the prompt above")
print("     - Allow only: Bash, Write, Edit, Read (in sandbox only)")
print("     - Block: Grep, Glob, Read (outside sandbox)")
print("")
print("Task Definitions:")
print("")
for _, task in ipairs(tasks) do
  print(string.format("Task %d: %s", task.id, task.name))
end
print("")
print("See task prompts in this file for full specifications.")
