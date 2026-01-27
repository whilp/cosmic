## Agent Intuition Tests

These tests validate Goal 2 (Agent Intuition) by spawning fresh agents that learn cosmic-lua using only embedded documentation.

### Test Files

- `agent_intuition_task1_test.tl` - Fetch URL and parse JSON
- `agent_intuition_task2_test.tl` - Spawn subprocess
- `agent_intuition_task4_test.tl` - SQLite database operations

### How They Work

Each test:
1. Creates an isolated sandbox with only the `cosmic-lua` binary
2. Spawns a fresh agent using `claude -p` with the task prompt
3. Agent must complete the task using only `--help` and `--docs`
4. Runs the solution to verify it works
5. Uses another `claude -p` call to grade the solution
6. Reports PASS/FAIL

### Prerequisites

- `claude` CLI must be installed and in PATH
- Tests skip automatically if `claude` is not found

### Running the Tests

**Skip by default** - These tests are SKIPPED unless you set `RUN_AGENT_TESTS=1`:

```bash
# This will skip agent tests
make test

# This will run agent tests
RUN_AGENT_TESTS=1 make test

# Run just one agent test
RUN_AGENT_TESTS=1 o/bin/cosmic lib/cosmic/agent_intuition_task1_test.tl

# Run specific test file pattern
RUN_AGENT_TESTS=1 make test TESTS='*agent_intuition*'
```

### Why Skip by Default?

Agent tests:
- Spawn actual AI agents (expensive/slow)
- Require `claude` CLI
- Are non-deterministic
- Are meant for validating documentation quality, not CI

### Interpreting Results

**PASS**: Agent successfully learned and used the API from docs alone
**FAIL**: Agent couldn't complete task OR solution doesn't work

Failures indicate:
- Documentation is missing or unclear
- APIs are not discoverable via `--help` or `--docs`
- Error messages are not helpful

### Adding New Tests

Follow the pattern in existing `agent_intuition_*_test.tl` files:

```teal
#!/usr/bin/env cosmic

-- Skip unless RUN_AGENT_TESTS is set
if not os.getenv("RUN_AGENT_TESTS") then
  print("SKIP: Agent intuition tests require RUN_AGENT_TESTS=1")
  os.exit(0)
end

-- Check for claude CLI
local claude_check = spawn.spawn({"claude", "--version"})
if not claude_check:read() then
  print("SKIP: claude CLI not found")
  os.exit(0)
end

-- 1. Create sandbox
-- 2. Copy cosmic-lua binary
-- 3. Run: claude -p <task_prompt> -w <sandbox>
-- 4. Verify solution.lua exists
-- 5. Run solution
-- 6. Grade with: claude -p <grading_prompt>
-- 7. Parse PASS/FAIL from grader output
-- 8. Cleanup and exit with appropriate code
```

### Test Coverage

Current tests cover 3 of 6 verification tasks from GOALS.md Goal 2:
- ✅ Task 1: Fetch URL and parse JSON
- ✅ Task 2: Spawn subprocess
- ⏭️ Task 3: Walk directory (TODO)
- ✅ Task 4: SQLite operations
- ⏭️ Task 5: Parse arguments (TODO)
- ⏭️ Task 6: Create ZIP archive (TODO)

To add remaining tasks, create new files following the naming pattern:
`agent_intuition_task<N>_test.tl`

### Example Run

```bash
$ RUN_AGENT_TESTS=1 o/bin/cosmic lib/cosmic/agent_intuition_task2_test.tl
=== Agent Intuition Test: Task 2 - Spawn Subprocess ===
Sandbox: /tmp/agent_task2_1738032445
Spawning agent...
Testing solution...
Solution output:
Output: Hello from subprocess

Grader: PASS - Solution correctly spawns subprocess and captures output

✓ Test PASSED
```

### Continuous Validation

Re-run these tests after documentation improvements to measure impact:

```bash
# Before: Document cosmo.DecodeJson
RUN_AGENT_TESTS=1 make test > before.log

# Make improvements
vim lib/types/cosmo.d.tl  # Add doc comments

# After
make cosmic
RUN_AGENT_TESTS=1 make test > after.log

# Compare: Did agents complete tasks faster? With fewer errors?
diff before.log after.log
```

This creates a feedback loop for documentation quality.
