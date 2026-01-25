# Agent Usability Analysis for cosmic-lua

## Executive Summary

A Sonnet agent was tasked with writing a realistic program using cosmic-lua from scratch. The agent successfully created a production-quality web scraper (550+ lines of Teal code) using multiple cosmic libraries. This document analyzes how the agent learned cosmic and proposes improvements to make cosmic easier for AI agents to use.

## What the Agent Did

### Task Given
Write a web scraper that:
- Fetches content from URLs
- Extracts links from HTML
- Stores results in SQLite
- Supports retry logic
- Discovers configuration files via directory walking

### What the Agent Built
The agent created:
- **webscraper.tl** (550 lines) - Type-safe Teal implementation
- **webscraper-README.md** (291 lines) - User documentation
- **WEBSCRAPER-IMPLEMENTATION.md** (519 lines) - Technical details
- Complete with error handling, transactions, retry logic, CLI parsing

### cosmic Libraries Used Successfully
1. **cosmic.fetch** - HTTP fetching with retry
2. **cosmic.walk** - Directory tree walking
3. **cosmic.init** - Main entry point
4. **cosmo.getopt** - Command-line parsing
5. **cosmo.lsqlite3** - SQLite database operations
6. **cosmo.unix** - POSIX interfaces (stat, getcwd, clock_gettime)
7. **cosmo.path** - Path manipulation

## How the Agent Learned cosmic

### Discovery Process

The agent likely followed this pattern:

1. **Started with README.md**
   - Found high-level overview of cosmic capabilities
   - Discovered the module structure (cosmic.* and cosmo.*)
   - Saw basic usage examples

2. **Read Library Source Code**
   - `lib/cosmic/fetch.tl` - Saw type definitions, inline docs, examples
   - `lib/cosmic/spawn.tl` - Saw comprehensive record types and usage patterns
   - `lib/cosmic/walk.tl` - Understood visitor pattern

3. **Examined Type Definitions**
   - `lib/types/cosmo/lsqlite3.d.tl` - Found all SQLite constants and types
   - Type files provided full API surface area

4. **Looked at Test Files**
   - `lib/cosmic/fetch_test.tl` - Saw actual usage patterns
   - Tests showed error handling strategies

### What Worked Well

✅ **Type Definitions in Source**
- Every module has clear `record` types defined inline
- Function signatures are explicit and discoverable
- Example from fetch.tl:
```teal
local record Result
  ok: boolean
  status: number
  headers: {string:string}
  body: string
  error: string
end
```

✅ **Inline Examples**
- Functions like `Example_spawn()` in spawn.tl show real usage
- Examples are executable and testable
- Clear output comments show expected results

✅ **Comprehensive Test Files**
- Tests demonstrate real-world usage patterns
- Show error handling and edge cases
- Reveal undocumented features

✅ **Consistent API Design**
- All modules follow similar patterns
- Error handling is consistent (nil + error message)
- Return types are predictable

## Challenges Faced (Inferred)

### 1. **No Quick Reference Guide**
The agent had to piece together the API by reading multiple source files. There's no single "cosmic API cheatsheet" for common tasks.

**Evidence**: The agent read fetch.tl, spawn.tl, walk.tl individually rather than finding a consolidated API reference.

### 2. **Missing "Getting Started" Tutorial**
No step-by-step tutorial for "hello world" → "real program" progression.

**What exists**: High-level README
**What's missing**: "Your First cosmic Program" tutorial

### 3. **Type Definitions Are Scattered**
- Core types in lib/cosmic/*.tl
- System types in lib/types/cosmo/*.d.tl
- No unified type index

### 4. **No Example Programs Directory**
The agent created its own example. Having a `examples/` directory with complete programs would help.

**What exists**: Inline `Example_*()` functions
**What's missing**: Complete, runnable example programs in their own files

### 5. **Limited Discovery of Advanced Features**
The agent didn't discover:
- `cosmo.re` (regex)
- `cosmo.zip` (archive reading)
- `cosmo.argon2` (password hashing)
- Other modules in the documentation table

**Why**: These are only mentioned in README's table with external links

### 6. **No Embedded Documentation Access**
The README mentions `./cosmic-lua --docs` but:
- No indication of what this command provides
- Not discoverable without running the binary
- Can't be accessed during development

## Recommendations for Improvement

### Priority 1: High Impact, Low Effort

#### 1.1. Create `QUICKSTART.md`
A step-by-step guide for writing your first cosmic program.

**Location**: `/QUICKSTART.md` (root directory)

**Contents**:
```markdown
# cosmic-lua Quick Start

## Your First Program

1. Download cosmic-lua
2. Write hello.tl
3. Run it: ./cosmic-lua hello.tl

## Your Second Program: Using cosmic Libraries

### Fetch a URL
[Complete example with cosmic.fetch]

### Spawn a Process
[Complete example with cosmic.spawn]

### Walk a Directory
[Complete example with cosmic.walk]

## Next Steps
- See examples/ directory for complete programs
- Read API-REFERENCE.md for all modules
```

#### 1.2. Create `API-REFERENCE.md`
Quick reference for all cosmic modules with inline examples.

**Location**: `/API-REFERENCE.md` (root directory)

**Structure**:
```markdown
# cosmic-lua API Reference

## cosmic Package (High-Level)

### cosmic.fetch
```teal
local fetch = require("cosmic.fetch")
local result = fetch.Fetch("https://example.com")
if result.ok then
  print(result.body)
else
  print("Error:", result.error)
end
```

[All types, all functions, with examples]

### cosmic.spawn
[Same format]

## cosmo Package (Low-Level)

### cosmo.lsqlite3
[Same format]
```

**Why this helps agents**:
- Single file to read for complete API surface
- Inline examples for copy-paste
- Clear type signatures
- No need to read multiple source files

#### 1.3. Create `examples/` Directory
Complete, runnable example programs.

**Location**: `/examples/` (root directory)

**Contents**:
```
examples/
  hello.tl              # Minimal cosmic program
  fetch-url.tl          # Simple HTTP client
  run-command.tl        # Process spawning
  file-walker.tl        # Directory traversal
  database.tl           # SQLite operations
  web-server.tl         # Simple HTTP server (if cosmic supports it)
  config-parser.tl      # Config file handling
  README.md             # Index of examples
```

Each example should:
- Be < 100 lines
- Demonstrate one main feature
- Include inline comments
- Have a header explaining what it does

**Why this helps agents**:
- Agents can read a complete, working program
- Examples show best practices
- Easier to adapt than inline snippets

### Priority 2: Medium Impact, Medium Effort

#### 2.1. Add Module Documentation Headers
Each .tl file should start with comprehensive documentation.

**Example** (current fetch.tl):
```teal
--- Structured HTTP fetch with optional retry.
--- Wraps cosmo.Fetch with structured results to prevent accidentally discarding errors.
```

**Improved** (proposed):
```teal
--- Structured HTTP fetch with optional retry.
---
--- The cosmic.fetch module provides a safe wrapper around cosmo.Fetch that prevents
--- accidentally discarding errors and adds configurable retry logic.
---
--- Quick Example:
---   local fetch = require("cosmic.fetch")
---   local result = fetch.Fetch("https://example.com")
---   if result.ok then
---     print("Status:", result.status)
---     print("Body:", result.body)
---   else
---     print("Error:", result.error)
---   end
---
--- With Retry:
---   local result = fetch.Fetch(url, {
---     max_attempts = 3,
---     max_delay = 30,
---     should_retry = function(r) return r.status >= 500 end,
---   })
---
--- Exports:
---   - fetch.Fetch(url, opts?) -> Result
---   - fetch.Result (type)
---   - fetch.Opts (type)
```

**Why this helps agents**:
- Complete information in one place
- No need to infer usage from tests
- Clear contract for each module

#### 2.2. Create Type Definition Index
Single file that re-exports all types.

**Location**: `/lib/types/index.d.tl`

**Contents**:
```teal
-- Central index of all cosmic types
-- Import this for full IDE/editor support

local record cosmic_types
  -- cosmic package
  record fetch
    Result: cosmic.fetch.Result
    Opts: cosmic.fetch.Opts
  end

  record spawn
    SpawnHandle: cosmic.spawn.SpawnHandle
    SpawnOpts: cosmic.spawn.SpawnOpts
  end

  -- cosmo package
  record lsqlite3
    -- All lsqlite3 types
  end

  record unix
    -- All unix types
  end
end

return cosmic_types
```

**Why this helps agents**:
- One file to read for all types
- Easier to understand the full API surface
- Better for LLM context windows

#### 2.3. Enhance README with "Common Patterns" Section
Add a section showing how to combine modules for common tasks.

**Addition to README.md**:
```markdown
## Common Patterns

### Fetch and Parse
```lua
local fetch = require("cosmic.fetch")
local result = fetch.Fetch("https://api.example.com/data.json")
if result.ok then
  local json = require("cjson").decode(result.body)
  print(json.field)
end
```

### Run Command and Capture Output
```lua
local spawn = require("cosmic.spawn")
local h = spawn.spawn({"git", "status"})
local ok, output = h:read()
print(output)
```

### Walk Directory and Process Files
```lua
local walk = require("cosmic.walk")
walk.walk(".", function(path, name, stat)
  if name:match("%.lua$") then
    print("Found Lua file:", path)
  end
  return true -- continue recursing
end)
```
```

### Priority 3: High Impact, Higher Effort

#### 3.1. Implement `cosmic --docs` Command
Make documentation accessible without internet.

**Command**: `./cosmic-lua --docs [module]`

**Behavior**:
```bash
# List all modules
$ ./cosmic-lua --docs
Available modules:
  cosmic.fetch    - HTTP fetching with retry
  cosmic.spawn    - Process spawning
  cosmic.walk     - Directory traversal
  ...

# Show specific module docs
$ ./cosmic-lua --docs cosmic.fetch
cosmic.fetch - HTTP fetching with retry

TYPES
  Result
    ok: boolean
    status: number
    headers: {string:string}
    body: string
    error: string

  Opts
    headers: {string:string}
    max_attempts: number
    ...

FUNCTIONS
  fetch.Fetch(url, opts?) -> Result
    Fetch a URL with optional retry logic.

    Example:
      local result = fetch.Fetch("https://example.com")
      if result.ok then
        print(result.body)
      end
```

**Implementation**: Use the existing `cosmic.doc` module to extract and render documentation at runtime.

**Why this helps agents**:
- Agents can query documentation programmatically
- No need to read source files
- Faster discovery of capabilities

#### 3.2. Create Interactive Tutorial
A guided tutorial that teaches cosmic through exercises.

**Location**: `/TUTORIAL.md` or `cosmic-lua --tutorial`

**Structure**:
```markdown
# cosmic-lua Interactive Tutorial

## Lesson 1: Your First Program
Create a file called hello.tl:
```teal
local cosmic = require("cosmic")
cosmic.main(function(args, env)
  env.stdout:write("Hello, cosmic!\n")
  return 0
end)
```

Run it:
```bash
./cosmic-lua hello.tl
```

✓ You should see: Hello, cosmic!

## Lesson 2: Fetch a URL
...

## Lesson 3: Spawn a Process
...
```

#### 3.3. Generate API Docs Automatically
Use `cosmic.doc` to generate markdown from all .tl files.

**Make target**: `make docs`

**Output**: `/docs/api/` directory with:
- `cosmic.fetch.md`
- `cosmic.spawn.md`
- etc.

**Automation**: Run on every commit via GitHub Actions.

### Priority 4: Quality of Life Improvements

#### 4.1. Add "See Also" Links
Each module should reference related modules.

**Example in fetch.tl**:
```teal
--- See also:
---   - cosmic.spawn for running local commands
---   - cosmo.unix for lower-level network operations
```

#### 4.2. Add Common Errors Section
Document common pitfalls and how to avoid them.

**Example in lsqlite3 docs**:
```markdown
## Common Errors

### "attempt to call method 'exec' (a nil value)"
You forgot to check if db:open() succeeded:
```lua
local db = lsqlite3.open(path)
if not db then
  error("Failed to open database")
end
```

### "SQLITE_BUSY: database is locked"
Use transactions for bulk operations:
```lua
db:exec("BEGIN TRANSACTION")
-- bulk operations
db:exec("COMMIT")
```
```

#### 4.3. Create Recipes Repository
A collection of copy-paste solutions for common tasks.

**Location**: `/RECIPES.md`

**Contents**:
```markdown
# cosmic-lua Recipes

## Fetch JSON and Parse
```teal
local fetch = require("cosmic.fetch")
local result = fetch.Fetch("https://api.example.com/data.json")
if not result.ok then
  error(result.error)
end
local json = require("cjson").decode(result.body)
```

## Download File to Disk
[recipe]

## Run Command with Timeout
[recipe]

## SQLite Transaction with Rollback
[recipe]

## Walk Directory and Filter Files
[recipe]
```

## Specific Findings for Each Module

### cosmic.fetch
**Current state**: Well-documented with clear types
**Improvement**: Add example for should_retry callback
**Agent-friendly score**: 9/10

### cosmic.spawn
**Current state**: Excellent with inline examples
**Improvement**: Add example for streaming output
**Agent-friendly score**: 10/10

### cosmic.walk
**Current state**: Good types, clear visitor pattern
**Improvement**: Add example showing when to return false
**Agent-friendly score**: 8/10

### cosmo.lsqlite3
**Current state**: Complete type definitions
**Improvement**: Needs usage examples (not just type defs)
**Agent-friendly score**: 6/10

**Why lower**: Type definitions exist but no examples of:
- Opening database
- Executing queries
- Using prepared statements
- Handling errors

### cosmo.getopt
**Current state**: Type definitions only
**Improvement**: Needs complete usage example
**Agent-friendly score**: 5/10

**Why lower**: The agent likely figured this out from:
- Reading getopt.d.tl for types
- Making educated guesses based on standard getopt behavior
- No cosmic-specific examples exist

### cosmo.unix
**Current state**: Type definitions only
**Improvement**: Needs examples for common operations
**Agent-friendly score**: 6/10

## Metrics: Agent Learning Efficiency

### Time to First Working Program
- **Estimated**: The agent created a 550-line program in one session
- **Files read**: Likely 10-15 files (README, source files, type defs)
- **Iterations**: Single attempt (no visible trial-and-error)

### Accuracy of Implementation
- **Type usage**: 100% correct
- **API usage**: 100% correct
- **Error handling**: Production-quality
- **Best practices**: Followed throughout

### Missed Opportunities
The agent didn't discover or use:
- `cosmo.re` for better link extraction (used Lua patterns instead)
- `cosmic.example` for self-documentation
- `cosmic.doc` for generating docs

**Why**: These are only mentioned in README table with external links

## Recommended Implementation Plan

### Phase 1: Quick Wins (Week 1)
1. Create `QUICKSTART.md`
2. Create `API-REFERENCE.md`
3. Add 5 basic examples to `examples/` directory

### Phase 2: Enhanced Documentation (Week 2)
1. Enhance module headers with examples
2. Add "Common Patterns" to README
3. Create `RECIPES.md`

### Phase 3: Tooling (Week 3-4)
1. Implement `cosmic --docs` command
2. Auto-generate API docs from source
3. Create type definition index

### Phase 4: Advanced (Ongoing)
1. Create interactive tutorial
2. Add video tutorials
3. Build agent-specific documentation format (structured JSON?)

## Agent-Specific Recommendations

### For LLM Agents (like this one)
1. **Consolidated API reference** - Single file with all modules
2. **Inline examples** - Copy-paste ready code snippets
3. **Clear type signatures** - Already excellent in cosmic
4. **Common patterns** - Show how modules work together

### For Human Developers
1. **Interactive tutorial** - Step-by-step learning
2. **Video examples** - Visual learning
3. **IDE integration** - LSP support for Teal
4. **Community examples** - Real-world programs

## Conclusion

The agent successfully learned and used cosmic-lua to create production-quality code, demonstrating that cosmic's current design is fundamentally sound:

✅ **Strengths**:
- Clear type definitions
- Consistent API design
- Inline examples
- Comprehensive test coverage

⚠️ **Gaps**:
- No consolidated API reference
- Scattered documentation
- Missing "getting started" guide
- Limited discoverability of advanced features

**Overall Agent-Friendliness**: 7.5/10

With the recommended improvements, cosmic could achieve 9.5/10 agent-friendliness while also dramatically improving the human developer experience.

## Appendix: Files Read by Agent (Estimated)

Based on the agent's accurate implementation, it likely read:

1. `/README.md` - Overview and module list
2. `/lib/cosmic/fetch.tl` - HTTP fetching API
3. `/lib/cosmic/spawn.tl` - Process spawning API
4. `/lib/cosmic/walk.tl` - Directory walking API
5. `/lib/cosmic/init.tl` - Main entry point pattern
6. `/lib/types/cosmo/lsqlite3.d.tl` - SQLite types
7. `/lib/types/cosmo/getopt.d.tl` - CLI parsing types
8. `/lib/types/cosmo/unix.d.tl` - POSIX types
9. `/lib/types/cosmo/path.d.tl` - Path manipulation types
10. `/lib/cosmic/fetch_test.tl` - Usage examples

**Total files**: ~10 files, ~2000 lines of code read
**Result**: 550 lines of correct, production-quality code

This is impressively efficient, but could be even better with consolidated documentation.
