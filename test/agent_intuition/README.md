### Agent Intuition Test Harness

This directory contains the automated test harness for verifying Goal 2: Agent Intuition.

## What It Tests

The harness validates that fresh AI agents with **no codebase access** can learn cosmic-lua using only:
- `cosmic-lua --help`
- `cosmic-lua --docs <query>`

## How It Works

1. Creates isolated sandbox directories for 6 tasks
2. Copies only the `cosmic-lua` binary to each sandbox
3. Spawns fresh subagents with restricted tool access:
   - **Allowed**: Bash (for running cosmic-lua), Write, Edit, Read (in sandbox only)
   - **Blocked**: Grep, Glob, Read (of source code outside sandbox)
4. Agents must complete tasks using only embedded documentation
5. Results are collected and analyzed

## Running the Harness

### Option 1: From Claude Code Session (Automated)

From a Claude Code session, say:

```
Run the agent intuition test harness. Spawn 6 fresh subagents to verify they can complete the tasks using only cosmic-lua --help and --docs.
```

The agents will be spawned automatically using the Task tool, running in parallel.

### Option 2: Setup Sandboxes for Manual Testing

```bash
# Build cosmic first
make cosmic

# Create isolated sandboxes
./test_agent_intuition.sh --manual

# This creates /tmp/cosmic-agent-test-$$/task{1-6}/
# Each contains cosmic-lua binary and TASK.md instructions
```

Then manually spawn agents or test in each sandbox.

### Option 3: Run Single Task

```bash
./test_agent_intuition.sh --task 1 --manual
# Then manually test in /tmp/cosmic-agent-test-$$/task1/
```

## The 6 Tasks

1. **Fetch URL and parse JSON** - HTTP client and JSON parsing
2. **Spawn subprocess** - Process spawning and output capture
3. **Walk directory tree** - Directory traversal with pattern matching
4. **SQLite operations** - Database creation, queries
5. **Parse arguments** - Command-line argument parsing
6. **Create ZIP archive** - Archive creation and verification

## Test Results

Previous test runs:
- **2026-01-27**: 6/6 tasks passed (100%)
  - All agents successfully completed tasks using only `--help` and `--docs`
  - See: `AGENT_INTUITION_TEST_RESULTS.md` for detailed results
  - Agent IDs: a0c59dc, a058951, a8462e3, a95e7dc, abce4a2, a7fe004

## Files

- `README.md` (this file) - Documentation
- `run_agent_harness.tl` - Task definitions for programmatic spawning
- `../../test_agent_intuition.sh` - Setup script for sandboxes
- `../../AGENT_INTUITION_TEST_RESULTS.md` - Detailed test results
- `../../AGENT_INTUITION_PLAN.md` - Plan for completing remaining work

## What Success Looks Like

A successful test run shows:
- ✅ All 6 agents complete their tasks
- ✅ Agents discover APIs using `--help` and `--docs`
- ✅ Scripts work on first try or after documentation-guided iteration
- ✅ Agents don't need to read source code or guess APIs

## What Failure Indicates

If agents fail, it suggests:
- ❌ Documentation is missing or unclear
- ❌ APIs are not discoverable
- ❌ Error messages are not helpful
- ❌ Examples are insufficient

These failures point to specific documentation improvements needed.

## Re-running After Changes

To verify documentation improvements:

1. Make documentation changes
2. Rebuild: `make cosmic`
3. Re-run harness (see options above)
4. Compare new agent success rate to previous runs
5. Document results in `AGENT_INTUITION_TEST_RESULTS.md`

This creates a continuous validation loop for documentation quality.
