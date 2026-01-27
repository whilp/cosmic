#!/bin/bash
# Agent Intuition Test Harness
# Re-runs the agent intuition tests by spawning fresh agents for each task
#
# This script creates isolated sandboxes and spawns fresh subagents that can
# ONLY use cosmic-lua --help and --docs (no codebase access).
#
# Usage:
#   ./test_agent_intuition.sh              # Run all tasks
#   ./test_agent_intuition.sh --task 1     # Run specific task
#   ./test_agent_intuition.sh --manual     # Setup sandboxes for manual testing

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COSMIC_BIN="$SCRIPT_DIR/o/bin/cosmic"
SANDBOX_BASE="${SANDBOX_BASE:-/tmp/cosmic-agent-test-$$}"
TASK_NUM=""
MANUAL_MODE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --task)
      TASK_NUM="$2"
      shift 2
      ;;
    --manual)
      MANUAL_MODE=true
      shift
      ;;
    --help)
      echo "Usage: $0 [options]"
      echo ""
      echo "Options:"
      echo "  --task N     Run only task N (1-6)"
      echo "  --manual     Setup sandboxes but don't spawn agents (manual testing)"
      echo "  --help       Show this help"
      echo ""
      echo "Environment:"
      echo "  SANDBOX_BASE   Directory for test sandboxes (default: /tmp/cosmic-agent-test-\$\$)"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if cosmic binary exists
if [[ ! -x "$COSMIC_BIN" ]]; then
    echo -e "${RED}ERROR: cosmic binary not found at $COSMIC_BIN${NC}"
    echo "Run 'make cosmic' first"
    exit 1
fi

echo -e "${BLUE}=========================================="
echo "Agent Intuition Test Harness"
echo "==========================================${NC}"
echo "Binary: $COSMIC_BIN"
echo "Sandbox: $SANDBOX_BASE"
echo ""

# Create sandbox base
mkdir -p "$SANDBOX_BASE"

# Task definitions
declare -A TASKS=(
    [1]="Fetch URL and parse JSON"
    [2]="Spawn subprocess and capture output"
    [3]="Walk directory tree matching pattern"
    [4]="SQLite database operations"
    [5]="Parse command-line arguments"
    [6]="Create ZIP archive"
)

declare -A TASK_PROMPTS=(
    [1]="Write a Lua script that fetches https://api.github.com/repos/jart/cosmopolitan and prints the repository name and star count from the JSON response. Use ONLY ./cosmic-lua --help and ./cosmic-lua --docs to learn the API. You CANNOT read source code."

    [2]="Write a Lua script that spawns 'echo Hello World' as a subprocess and prints the captured output. Use ONLY ./cosmic-lua --help and ./cosmic-lua --docs to learn the API. You CANNOT read source code."

    [3]="Write a Lua script that creates some .txt files in the current directory, then walks the directory tree and prints all .txt files found. Use ONLY ./cosmic-lua --help and ./cosmic-lua --docs to learn the API. You CANNOT read source code."

    [4]="Write a Lua script that creates an in-memory SQLite database, creates a table with 2 columns, inserts 2 rows, and queries them back. Use ONLY ./cosmic-lua --help and ./cosmic-lua --docs to learn the API. You CANNOT read source code."

    [5]="Write a Lua script that parses command-line arguments including -h (help), -v (verbose), and -o <file> (output) flags and prints the parsed options. Test it with: ./cosmic-lua script.lua -h -v -o output.txt file1 file2. Use ONLY ./cosmic-lua --help and ./cosmic-lua --docs to learn the API. You CANNOT read source code."

    [6]="Write a Lua script that creates a ZIP file with two text files in it, then reads it back to verify the contents. Use ONLY ./cosmic-lua --help and ./cosmic-lua --docs to learn the API. You CANNOT read source code."
)

setup_task_sandbox() {
    local task_id="$1"
    local task_name="${TASKS[$task_id]}"
    local task_sandbox="$SANDBOX_BASE/task$task_id"

    echo -e "${BLUE}Setting up Task $task_id: $task_name${NC}"

    # Create task directory
    mkdir -p "$task_sandbox"

    # Copy cosmic binary
    cp "$COSMIC_BIN" "$task_sandbox/cosmic-lua"
    chmod +x "$task_sandbox/cosmic-lua"

    # Create task instruction file
    cat > "$task_sandbox/TASK.md" <<EOF
# Task $task_id: $task_name

## Prompt
${TASK_PROMPTS[$task_id]}

## Constraints
- Working directory: $task_sandbox
- Only tool available: ./cosmic-lua
- Learn using: ./cosmic-lua --help and ./cosmic-lua --docs <query>
- CANNOT read source code from $SCRIPT_DIR
- CANNOT use Grep/Glob on the codebase

## Success Criteria
Create a working .lua script that accomplishes the task using only the --help and --docs documentation.

## To Run This Task Manually
From this directory, spawn a Claude Code agent with:
  - Allowed tools: Bash, Write, Edit, Read (only in this directory)
  - Blocked tools: Grep, Glob, Read (of files outside this directory)
  - Prompt: See above

Or use: cd $task_sandbox && claude -p "\$(cat TASK.md)"
EOF

    echo "  Created: $task_sandbox"
    echo "  Binary: $task_sandbox/cosmic-lua"
    echo "  Instructions: $task_sandbox/TASK.md"
    echo ""
}

run_task_with_agent() {
    local task_id="$1"
    local task_name="${TASKS[$task_id]}"
    local task_sandbox="$SANDBOX_BASE/task$task_id"

    echo -e "${YELLOW}Task $task_id: $task_name${NC}"
    echo "  This requires spawning a subagent from Claude Code"
    echo "  See: $task_sandbox/TASK.md"
    echo ""
    echo "  To test this task:"
    echo "    cd $task_sandbox"
    echo "    # Then spawn an agent with the Task tool or manually"
    echo ""
}

# Main execution
if [[ -n "$TASK_NUM" ]]; then
    # Single task
    if [[ ! -v TASKS[$TASK_NUM] ]]; then
        echo -e "${RED}ERROR: Invalid task number: $TASK_NUM${NC}"
        echo "Valid tasks: ${!TASKS[@]}"
        exit 1
    fi
    setup_task_sandbox "$TASK_NUM"
    if [[ "$MANUAL_MODE" == false ]]; then
        run_task_with_agent "$TASK_NUM"
    fi
else
    # All tasks
    for task_id in {1..6}; do
        setup_task_sandbox "$task_id"
    done

    if [[ "$MANUAL_MODE" == false ]]; then
        echo -e "${BLUE}=========================================="
        echo "Sandbox Setup Complete"
        echo "==========================================${NC}"
        echo ""
        echo "To run the agent tests, use one of these methods:"
        echo ""
        echo "Method 1: From Claude Code session, run this script as a Teal task:"
        echo "  See: test/agent_intuition/run_agent_harness.tl"
        echo ""
        echo "Method 2: Manually spawn agents for each task:"
        for task_id in {1..6}; do
            echo "  Task $task_id: cd $SANDBOX_BASE/task$task_id && (spawn agent)"
        done
        echo ""
        echo "Method 3: Re-run this test from a Claude Code session that can spawn Task agents"
        echo ""
        echo "Sandbox ready at: $SANDBOX_BASE"
    fi
fi

echo -e "${GREEN}Setup complete${NC}"
