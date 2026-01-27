#!/bin/bash
# Test harness for Agent Intuition goal
# Spawns isolated subagents to verify they can complete tasks using only cosmic-lua docs

set -e

COSMIC_BIN="$(pwd)/o/bin/cosmic"
SANDBOX_BASE="/tmp/cosmic-agent-test-$$"

# Ensure cosmic binary exists
if [[ ! -x "$COSMIC_BIN" ]]; then
    echo "ERROR: cosmic binary not found at $COSMIC_BIN"
    echo "Run 'make cosmic' first"
    exit 1
fi

# Create sandbox
mkdir -p "$SANDBOX_BASE"

# Task definitions
declare -A TASKS=(
    ["task1"]="Fetch a URL and parse JSON response"
    ["task2"]="Spawn a subprocess and capture output"
    ["task3"]="Walk a directory tree matching a glob pattern"
    ["task4"]="Read/write a SQLite database"
    ["task5"]="Parse command-line arguments"
    ["task6"]="Create a ZIP archive"
)

declare -A TASK_PROMPTS=(
    ["task1"]="Using only 'cosmic-lua --help' and 'cosmic-lua --docs', write a Lua script that fetches https://api.github.com/repos/jart/cosmopolitan and prints the repository name and star count from the JSON response."
    ["task2"]="Using only 'cosmic-lua --help' and 'cosmic-lua --docs', write a Lua script that spawns 'echo Hello World' as a subprocess and prints the captured output."
    ["task3"]="Using only 'cosmic-lua --help' and 'cosmic-lua --docs', write a Lua script that walks the current directory and prints all .txt files."
    ["task4"]="Using only 'cosmic-lua --help' and 'cosmic-lua --docs', write a Lua script that creates an in-memory SQLite database, creates a table, inserts 2 rows, and queries them back."
    ["task5"]="Using only 'cosmic-lua --help' and 'cosmic-lua --docs', write a Lua script that parses command-line arguments including -h (help) and -v (verbose) flags and prints the parsed options."
    ["task6"]="Using only 'cosmic-lua --help' and 'cosmic-lua --docs', write a Lua script that creates a ZIP file with two text files in it."
)

echo "========================================"
echo "Agent Intuition Test Harness"
echo "========================================"
echo "This harness spawns fresh subagents with no access to the codebase."
echo "Each agent can only use 'cosmic-lua --help' and 'cosmic-lua --docs'."
echo ""
echo "Sandbox: $SANDBOX_BASE"
echo "Cosmic binary: $COSMIC_BIN"
echo ""

# Store results
RESULTS_FILE="$SANDBOX_BASE/results.txt"
touch "$RESULTS_FILE"

# Function to run a single task
run_task() {
    local task_id="$1"
    local task_name="${TASKS[$task_id]}"
    local task_prompt="${TASK_PROMPTS[$task_id]}"

    echo "========================================"
    echo "Task: $task_name"
    echo "========================================"

    # Create task-specific sandbox
    local task_sandbox="$SANDBOX_BASE/$task_id"
    mkdir -p "$task_sandbox"

    # Copy cosmic binary to sandbox
    cp "$COSMIC_BIN" "$task_sandbox/cosmic-lua"

    echo "Sandbox: $task_sandbox"
    echo "Prompt: $task_prompt"
    echo ""
    echo "This task requires manual agent spawning via Claude Code Task tool."
    echo "The agent should:"
    echo "  - Work in directory: $task_sandbox"
    echo "  - Have access to: Bash, Write, Edit, Read (only in sandbox)"
    echo "  - NOT have access to: Grep, Glob, Read (outside sandbox)"
    echo "  - Use only: ./cosmic-lua --help and ./cosmic-lua --docs"
    echo ""

    # Write instructions for manual agent spawning
    cat > "$task_sandbox/TASK.md" <<EOF
# Task: $task_name

## Instructions
$task_prompt

## Constraints
- You are in an isolated sandbox directory: $task_sandbox
- You have access to the 'cosmic-lua' binary in this directory
- You can ONLY learn about cosmic-lua using: ./cosmic-lua --help and ./cosmic-lua --docs
- You CANNOT read source code or grep the codebase
- Create a Lua script to solve this task
- Run it with ./cosmic-lua to verify it works

## Success Criteria
Create a working script that accomplishes the task using only the information from --help and --docs.
EOF

    echo "Task setup complete. See $task_sandbox/TASK.md"
    echo ""
}

# Main execution
echo "Setting up all tasks..."
echo ""

for task_id in task1 task2 task3 task4 task5 task6; do
    run_task "$task_id"
done

echo "========================================"
echo "Setup Complete"
echo "========================================"
echo ""
echo "To run each task, spawn a subagent with:"
echo "  - Working directory: $SANDBOX_BASE/taskN"
echo "  - Allowed tools: Bash, Write, Edit, Read (in sandbox only)"
echo "  - Task prompt from: $SANDBOX_BASE/taskN/TASK.md"
echo ""
echo "Results will be collected and analyzed."
