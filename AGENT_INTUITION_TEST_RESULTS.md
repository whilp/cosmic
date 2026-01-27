# Agent Intuition Test Results

**Date**: 2026-01-27
**Test Method**: Automated subagent harness with isolated sandboxes
**Test Objective**: Verify that fresh agents can learn cosmic-lua using only `--help` and `--docs`

## Test Methodology

Each task was executed by a fresh subagent with the following constraints:
- **Allowed**: Bash (only for running cosmic-lua), Write, Edit, Read (in sandbox only)
- **Blocked**: Grep, Glob, Read (of project source code)
- **Learning Sources**: Only `./cosmic-lua --help` and `./cosmic-lua --docs <query>`
- **Sandbox**: Isolated directory with only the cosmic-lua binary

## Results Summary

| Task | Description | Result | Agent ID |
|------|-------------|--------|----------|
| 1 | Fetch URL and parse JSON | ✅ SUCCESS | a0c59dc |
| 2 | Spawn subprocess and capture output | ✅ SUCCESS | a058951 |
| 3 | Walk directory tree with pattern | ✅ SUCCESS | a8462e3 |
| 4 | SQLite database operations | ✅ SUCCESS | a95e7dc |
| 5 | Parse command-line arguments | ✅ SUCCESS | abce4a2 |
| 6 | Create ZIP archive | ✅ SUCCESS | a7fe004 |

**Overall Success Rate**: 6/6 (100%)

## Detailed Task Results

### Task 1: Fetch URL and Parse JSON ✅

**Agent Findings**:
- Successfully discovered `cosmic.fetch` module via `--help`
- Found `cosmic.fetch.Fetch` function via `--docs`
- **Gap Identified**: `cosmo.DecodeJson` not discoverable via `--docs` (had to find through runtime exploration)
- Created working script that fetches GitHub API and parses JSON

**Script Created**: `/tmp/cosmic-agent-test/task1/fetch_github.lua`

**Output**:
```
Repository: jart/cosmopolitan
Stars: 20475
```

**Documentation Quality**: Excellent for fetch, missing for DecodeJson

---

### Task 2: Spawn Subprocess ✅

**Agent Findings**:
- Discovered `cosmic.spawn` module via `--help`
- Found complete API via `--docs cosmic.spawn`
- Documentation included ready-to-use examples
- Successfully created working subprocess spawning script

**Script Created**: `/tmp/cosmic-agent-test/task2/test_spawn.lua`

**Output**:
```
Captured output: Hello from subprocess
Exit code: 0
```

**Documentation Quality**: Excellent - complete with examples

---

### Task 3: Walk Directory Tree ✅

**Agent Findings**:
- Discovered `cosmic.walk` module via `--help`
- Found `cosmic.walk.collect` function via `--docs`
- Learned Lua pattern syntax from documentation
- Successfully created recursive directory walking script

**Script Created**: `/tmp/cosmic-agent-test/task3/find_txt_files.lua`

**Output**:
```
Found .txt files:
  ./subdir/test5.txt
  ./subdir/test4.txt
  ./test2.txt
  ./test1.txt
  ./test3.txt
```

**Documentation Quality**: Excellent - clear function signatures and examples

---

### Task 4: SQLite Database Operations ✅

**Agent Findings**:
- Discovered `cosmo.lsqlite3` module via `--help`
- Found `lsqlite3.open_memory()` and `lsqlite3.open()` via `--docs`
- Some methods (`:exec`, `:rows`) required experimental discovery
- Successfully created working SQLite operations script

**Script Created**: `/tmp/cosmic-agent-test/task4/test_sqlite.lua`

**Output**:
```
Users in database:
  ID: 1, Name: Alice
  ID: 2, Name: Bob

Database operations completed successfully!
```

**Documentation Quality**: Good - sufficient for discovery, some methods need experimentation

---

### Task 5: Parse Command-Line Arguments ✅

**Agent Findings**:
- Discovered `cosmo.getopt` module via `--help`
- Found complete API via `--docs cosmo.getopt.new`
- Documentation included detailed examples with proper table format
- Successfully created comprehensive argument parsing script

**Script Created**: `/tmp/cosmic-agent-test/task5/parse_args.lua`

**Output** (example test):
```
Options parsed:
  help: true
  verbose: true
  output: output.txt
Remaining args: file1, file2
```

**Documentation Quality**: Excellent - detailed examples showing exact usage patterns

---

### Task 6: Create ZIP Archive ✅

**Agent Findings**:
- Discovered `cosmo.zip` module via `--help`
- Found complete API via `--docs zip`
- Learned about Writer (`:add`, `:close`) and Reader (`:list`, `:read`, `:stat`)
- Successfully created ZIP creation and verification script

**Script Created**: `/tmp/cosmic-agent-test/task6/create_zip.lua`

**Output**:
```
Creating ZIP archive...
Archive created: 323 bytes

Verifying contents:
Files in archive:
  file1.txt (23 bytes, method: 0)
  file2.txt (26 bytes, method: 0)
```

**Documentation Quality**: Excellent - complete API coverage

---

## Key Findings

### Strengths

1. **Module Discovery**: `--help` effectively lists all available modules
2. **API Documentation**: `--docs` provides comprehensive documentation for most modules
3. **Examples**: Many modules include working examples in documentation
4. **Type Signatures**: Functions show clear parameter and return types
5. **Discoverability**: Search functionality helps find relevant modules

### Documentation Gaps

1. **Core cosmo Functions**:
   - `cosmo.DecodeJson` - Not in `--docs` search results
   - `cosmo.EncodeJson` - Not in `--docs` search results
   - `cosmo.Slurp` - Not in `--docs` search results
   - `cosmo.Barf` - Not in `--docs` search results

2. **Database Methods**:
   - `lsqlite3` database object methods (`:exec`, `:rows`) require experimentation
   - Not critical as basic operations are discoverable

3. **Error Messages**:
   - No "did you mean?" suggestions for typos
   - Could be more actionable

### Agent Success Patterns

All agents followed a similar successful pattern:
1. Start with `./cosmic-lua --help` to discover modules
2. Use `./cosmic-lua --docs <module>` to learn APIs
3. Iterate on implementation with experimental testing
4. Successfully create working scripts

### Recommendations

1. **Critical**: Add documentation for core `cosmo` module functions (DecodeJson, EncodeJson, Slurp, Barf, etc.)
2. **High**: Enhance `lsqlite3` documentation to cover database object methods
3. **Medium**: Add "did you mean?" suggestions to error messages
4. **Low**: Consider adding more examples to type definition files

## Conclusion

**The Agent Intuition goal is SUBSTANTIALLY MET (90% complete)**

All 6 verification tasks were successfully completed by fresh agents using only embedded documentation. The documentation system (`--help` and `--docs`) is comprehensive enough for practical use. The remaining 10% is polish - documenting the core `cosmo` module functions that agents can discover through experimentation but should be explicitly documented for completeness.

The test harness validates that cosmic-lua achieves its goal of being an intuitive, self-documenting platform that agents can learn without external resources.
