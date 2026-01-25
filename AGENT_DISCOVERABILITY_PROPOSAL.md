# Cosmic Agent Discoverability Proposal

## Executive Summary

After tasking a Sonnet agent with writing a realistic cosmic program from scratch in an isolated environment (with only the cosmic-lua binary), we observed both successes and challenges in discoverability. This document proposes concrete improvements to make cosmic easier for both agents and humans to learn and use.

## Experiment Results

### What the Agent Accomplished

The agent successfully:
- Created 3 working programs (1,310 lines of code)
- Discovered 70+ functions across cosmo and unix modules
- Implemented production patterns (caching, logging, retry logic, visualization)
- Created comprehensive documentation (971 lines)
- Built a complete weather application suite

**Files created:**
- `weather.lua` - Basic weather app with API integration
- `weather-advanced.lua` - Enhanced version with caching and logging
- `demo-cosmic-features.lua` - Comprehensive feature showcase
- `README.md`, `COSMIC-QUICKREF.md`, `PROJECT-SUMMARY.md` - Documentation

### How the Agent Learned Cosmic

The agent discovered cosmic through:

1. **`--help` flag** - Showed basic cosmic options (compile, check, embed, etc.)
2. **Module introspection** - `pairs(require('cosmo'))` to list functions
3. **Source code reading** - Read embedded Lua files in `/zip/.lua/`
4. **Trial and error** - Tested function signatures and learned from errors
5. **Error messages** - Used error output to understand APIs

### Discovery Commands Used

```bash
# List package modules
./cosmic-lua -e "for k,v in pairs(package.loaded) do print(k) end"

# Explore module functions
./cosmic-lua -e "local m = require('cosmo'); for k,v in pairs(m) do print(k, type(v)) end"

# Read embedded source code
./cosmic-lua -e "io.open('/zip/.lua/cosmic/fetch.lua'):read('*a')"

# Test module existence
./cosmic-lua -e "local ok = pcall(require, 'cosmic.fetch'); print(ok)"
```

## Current Discoverability Gaps

### 1. **`--help [module]` Feature Exists But Is Underutilized**

**Current state:**
- The `--help [module]` feature is implemented in `lib/cosmic/main.tl:258-277`
- It looks for `_VERSION`, `_DESCRIPTION`, and `_USAGE` fields in modules
- However, most modules don't define these fields

**Evidence:**
```bash
# These commands show basic help, not module-specific help
./cosmic-lua --help cosmo
./cosmic-lua --help cosmic.fetch
```

The feature exists but modules lack the metadata to make it useful.

### 2. **No Function Signature Documentation**

**Problem:** Agents can see that `cosmo.Fetch` exists, but not:
- What parameters it takes
- What it returns
- What the parameter types should be
- Example usage

**Current workaround:** Read source code in `/zip/.lua/` or trial-and-error

### 3. **No Discovery Hints in --help Output**

**Problem:** The basic `--help` output doesn't tell users:
- How to list available modules
- How to inspect module contents
- Where to find embedded documentation
- Discovery commands

**Current state:**
```
cosmic-lua: cosmopolitan lua with bundled libraries

Usage: cosmic-lua [options] [script [args]]

Cosmic options:
  --compile <file.tl>      compile Teal file to Lua, lax mode (stdout)
  --check <file.tl>        type-check a Teal file, strict mode
  --embed <file>           embed file(s) into cosmic (use multiple times)
  --output <file>          output file for --embed (default: cosmic)
  --example <file.tl>      run Example_* functions, check output
  --benchmark <file.tl[:pattern]>  run Benchmark_* functions, report timing
  --doc <file.tl>          generate markdown documentation
  --help [module]          show help for cosmic or a module

Standard lua options:
  -e <stat>                execute string 'stat'
  -l <name>                require library 'name'
  -i                       enter interactive mode
  -v                       show version information
  -E                       ignore environment variables
  -W                       turn warnings into errors
```

Missing: Discovery guidance, module list, quick start examples

### 4. **No Built-in Module/Function Listing**

**Problem:** Users must know to use:
```lua
local m = require('cosmo')
for k, v in pairs(m) do print(k, type(v)) end
```

**Better approach:** Built-in command like:
```bash
./cosmic-lua --list-modules
./cosmic-lua --list-functions cosmo
```

### 5. **Embedded Documentation Not Advertised**

**Problem:** The agent discovered that `/zip/.lua/` contains source code, but this wasn't documented or suggested anywhere.

**Discovery was accidental** through exploration, not guided.

## Proposed Improvements

### Priority 1: Add Module Metadata (Quick Win)

**Action:** Add `_VERSION`, `_DESCRIPTION`, and `_USAGE` to all modules.

**Example for cosmic.fetch:**

```lua
-- In lib/cosmic/fetch.tl
local M = {
  _VERSION = "1.0.0",
  _DESCRIPTION = "Structured HTTP fetch with optional retry",
  _USAGE = [[
Usage:
  local fetch = require("cosmic.fetch")

  -- Simple GET request
  local result = fetch.get("https://api.example.com/data")
  if result.ok then
    print(result.body)
  end

  -- With retry
  local result = fetch.get("https://api.example.com/data", {
    max_retries = 3,
    retry_delay = 2.0
  })

Functions:
  get(url, opts?) -> {ok: boolean, status: number, headers: table, body: string, error: string?}
  post(url, body, opts?) -> {ok: boolean, status: number, headers: table, body: string, error: string?}
]],
  get = get,
  post = post,
}
```

**Impact:**
- `./cosmic-lua --help cosmic.fetch` would immediately show usage
- Zero runtime cost
- Low implementation effort
- High value for discoverability

**Modules to update:**
- `cosmo` (core module)
- `unix` (core module)
- `cosmic.fetch`
- `cosmic.spawn`
- `cosmic.walk`
- All other cosmic.* modules

### Priority 2: Enhanced --help Output

**Action:** Improve the basic `--help` output to include discovery guidance.

**Proposed new help output:**

```
cosmic-lua: cosmopolitan lua with bundled libraries

Usage: cosmic-lua [options] [script [args]]

Cosmic options:
  --compile <file.tl>      compile Teal file to Lua, lax mode (stdout)
  --check <file.tl>        type-check a Teal file, strict mode
  --embed <file>           embed file(s) into cosmic (use multiple times)
  --output <file>          output file for --embed (default: cosmic)
  --example <file.tl>      run Example_* functions, check output
  --benchmark <file.tl[:pattern]>  run Benchmark_* functions, report timing
  --doc <file.tl>          generate markdown documentation
  --help [module]          show help for cosmic or a module
  --list-modules           list all available modules
  --list-functions <mod>   list functions in a module

Standard lua options:
  -e <stat>                execute string 'stat'
  -l <name>                require library 'name'
  -i                       enter interactive mode
  -v                       show version information
  -E                       ignore environment variables
  -W                       turn warnings into errors

Quick Start:
  # List available modules
  cosmic-lua --list-modules

  # Get help on a module
  cosmic-lua --help cosmo
  cosmic-lua --help cosmic.fetch

  # Run a simple script
  cosmic-lua -e 'print(require("cosmo").GetTime())'

  # Explore module functions
  cosmic-lua -e 'for k,v in pairs(require("cosmo")) do print(k, type(v)) end'

Main Modules:
  cosmo          - Core Cosmopolitan Libc bindings (HTTP, crypto, compression, JSON)
  unix           - POSIX system calls (files, processes, networking)
  cosmic.fetch   - HTTP client with retry logic
  cosmic.spawn   - Process spawning utilities
  cosmic.walk    - Directory tree walking
  cosmic.doc     - Documentation extraction
  cosmic.example - Executable example testing

For detailed module help: cosmic-lua --help <module>
```

**Implementation:**
- Update `lib/cosmic/main.tl:279-301` to include this extended help
- Add module descriptions to a central registry

### Priority 3: Add --list-modules and --list-functions

**Action:** Add new CLI options for module/function discovery.

**Proposed implementation:**

```teal
-- In lib/cosmic/main.tl

-- Add to Opts record:
local record Opts
  -- ... existing fields ...
  list_modules: boolean
  list_functions: string
end

-- Add to longopts:
local longopts: {LongOpt} = {
  -- ... existing options ...
  { "list-modules", "none", nil },
  { "list-functions", "required", nil },
}

-- Handle in main():
if opts.list_modules then
  -- List all available modules
  local modules = {
    {name = "cosmo", desc = "Core Cosmopolitan Libc bindings"},
    {name = "unix", desc = "POSIX system calls"},
    {name = "cosmic.fetch", desc = "HTTP client with retry"},
    {name = "cosmic.spawn", desc = "Process spawning"},
    {name = "cosmic.walk", desc = "Directory walking"},
    {name = "cosmic.doc", desc = "Documentation extraction"},
    {name = "cosmic.example", desc = "Example testing"},
    {name = "cosmic.embed", desc = "File embedding"},
    {name = "cosmic.teal", desc = "Teal compilation"},
  }

  io.write("Available modules:\n\n")
  for _, mod in ipairs(modules) do
    io.write(string.format("  %-20s %s\n", mod.name, mod.desc))
  end
  io.write("\nUse --help <module> for detailed information\n")
  return 0
end

if opts.list_functions then
  local ok, mod = pcall(require, opts.list_functions)
  if not ok or type(mod) ~= "table" then
    return 1, "error: module '" .. opts.list_functions .. "' not found"
  end

  io.write("Functions in " .. opts.list_functions .. ":\n\n")
  local items = {}
  for k, v in pairs(mod as {string:any}) do
    if not k:match("^_") then  -- Skip internal fields
      items[#items + 1] = {name = k, type = type(v)}
    end
  end
  table.sort(items, function(a, b) return a.name < b.name end)

  for _, item in ipairs(items) do
    io.write(string.format("  %-30s (%s)\n", item.name, item.type))
  end
  return 0
end
```

**Impact:**
- Makes discovery trivial: `cosmic-lua --list-modules`
- Shows available functions: `cosmic-lua --list-functions cosmo`
- No need to know Lua to discover capabilities

### Priority 4: Interactive Discovery Mode

**Action:** Add a `--discover` or `--explore` mode for interactive discovery.

**Proposed feature:**

```bash
cosmic-lua --discover
```

**Interactive menu:**
```
Cosmic-Lua Discovery Mode
=========================

Available modules:
  1. cosmo          - Core Cosmopolitan Libc bindings
  2. unix           - POSIX system calls
  3. cosmic.fetch   - HTTP client with retry
  4. cosmic.spawn   - Process spawning
  5. cosmic.walk    - Directory walking
  [more...]

Select a module (1-9) or 'q' to quit: 1

Module: cosmo
=============

Functions (30+):
  Fetch(url)                    - Make HTTP request
  DecodeJson(str)               - Parse JSON string
  EncodeJson(tbl)               - Encode table as JSON
  Sha256(data)                  - SHA-256 hash
  EncodeBase64(data)            - Base64 encode
  [more...]

Select function for details, 'b' for back, 'q' to quit: Fetch

Function: cosmo.Fetch
=====================
Signature: status, headers, body = Fetch(url)

Parameters:
  url (string) - HTTP or HTTPS URL to fetch

Returns:
  status (number) - HTTP status code (200, 404, etc.) or nil on error
  headers (table)  - Response headers table or error string on failure
  body (string)    - Response body

Example:
  local status, headers, body = cosmo.Fetch("https://example.com")
  if status == 200 then
    print(body)
  else
    print("Error:", headers)
  end

Press Enter to continue...
```

**Alternative:** AI-powered help via `--ask` flag:

```bash
cosmic-lua --ask "How do I make an HTTP request?"
```

Uses embedded knowledge to answer common questions.

### Priority 5: Add --docs CLI Option

**Status:** Already in development (issue #40)

**Action:** Complete the `--docs` feature to show embedded documentation.

**Proposed usage:**

```bash
# List all docs
cosmic-lua --docs

# Show specific module docs
cosmic-lua --docs cosmo

# Show specific function docs
cosmic-lua --docs cosmo.Fetch

# Search docs
cosmic-lua --docs --search "http"
```

**Implementation approach:**
1. Embed markdown docs from `docs/` directory into the binary
2. Add `--docs` handler to `lib/cosmic/main.tl`
3. Use `cosmic.doc` to read embedded docs
4. Format and display in terminal (with paging for long docs)

### Priority 6: Add Quick Reference Card

**Action:** Add a `--quick-ref` or `--cheatsheet` option.

**Output example:**

```bash
cosmic-lua --quick-ref
```

```
Cosmic-Lua Quick Reference
==========================

HTTP/Network:
  local status, headers, body = cosmo.Fetch(url)
  local parts = cosmo.ParseUrl(url)
  local encoded = cosmo.EscapeParam("hello world")

JSON:
  local data = cosmo.DecodeJson('{"key":"value"}')
  local json = cosmo.EncodeJson({key = "value"})

File I/O:
  local fd = unix.open(path, unix.O_RDONLY)
  local content = unix.read(fd, 1024)
  unix.write(fd, "data")
  unix.close(fd)

Hashing/Crypto:
  local hash = cosmo.Sha256(data)
  local hex = cosmo.EncodeHex(hash)
  local b64 = cosmo.EncodeBase64(data)

Time:
  local now = cosmo.GetTime()
  local ts = unix.clock_gettime(unix.CLOCK_REALTIME)

Process:
  local spawn = require("cosmic.spawn")
  local result = spawn.run({"ls", "-la"})

For full docs: cosmic-lua --docs
For module help: cosmic-lua --help <module>
```

**Implementation:**
- Hardcode common patterns in `lib/cosmic/main.tl`
- Or embed from a `QUICKREF.md` file

## Implementation Priority

### Phase 1: Quick Wins (< 1 day)
1. ✅ Add `_VERSION`, `_DESCRIPTION`, `_USAGE` to all modules
2. ✅ Enhance basic `--help` output with discovery guidance
3. ✅ Add module list to help output

### Phase 2: Core Features (1-2 days)
4. ✅ Implement `--list-modules`
5. ✅ Implement `--list-functions <module>`
6. ✅ Add quick start examples to help

### Phase 3: Documentation (2-3 days)
7. ✅ Complete `--docs` feature
8. ✅ Embed module documentation
9. ✅ Add `--quick-ref` cheatsheet

### Phase 4: Advanced Features (Optional)
10. ⏸ Interactive `--discover` mode
11. ⏸ AI-powered `--ask` helper
12. ⏸ Example browser `--examples`

## Success Metrics

After these improvements, an agent (or human) should be able to:

1. **Discover available modules** in < 30 seconds
   - Run `cosmic-lua --list-modules`

2. **Learn a module's API** in < 2 minutes
   - Run `cosmic-lua --help cosmo`
   - Run `cosmic-lua --list-functions cosmo`

3. **Write first program** in < 5 minutes
   - Use `--quick-ref` for common patterns
   - Use `--help` for specific module details

4. **Find advanced features** in < 10 minutes
   - Use `--docs` for comprehensive documentation
   - Browse embedded docs

## Agent-Specific Benefits

These improvements help AI agents because:

1. **Structured output** - Easy to parse and understand
2. **No trial-and-error** - Function signatures provided upfront
3. **Self-contained** - No need to access external docs
4. **Consistent format** - Standard help/list patterns
5. **Discoverable** - Clear path from `--help` to detailed docs

## Human Benefits

These improvements help human developers because:

1. **Faster onboarding** - Learn cosmic in minutes, not hours
2. **Better IDE integration** - LSP can use embedded metadata
3. **Offline-friendly** - Everything needed is in the binary
4. **Consistent UX** - Follows Unix conventions (`--help`, `--list`)
5. **Quick reference** - No need to search online docs

## Related Work

Other self-contained tools with good discoverability:

- **ripgrep** - Excellent `--help` with examples
- **jq** - Built-in manual via `jq --help`
- **sqlite3** - `.help` command in REPL
- **go** - `go doc` for package documentation
- **rustc** - `rustc --explain` for error codes

Cosmic should match or exceed these standards.

## Conclusion

The agent experiment showed that cosmic is **discoverable but not easily discoverable**. With targeted improvements to help text, module metadata, and discovery commands, we can make cosmic significantly easier for both agents and humans to learn and use.

**Key insight:** The infrastructure for good discoverability already exists (`--help [module]`, embedded docs, introspection). We just need to populate the metadata and expose it through better CLI options.

**Recommendation:** Implement Phase 1 and Phase 2 improvements immediately. These are low-effort, high-impact changes that will dramatically improve the developer experience.

---

**Appendix: Agent's Self-Generated Documentation**

The agent created these discovery documents during the experiment:
- `/tmp/cosmic-agent-test/README.md` - Project documentation
- `/tmp/cosmic-agent-test/COSMIC-QUICKREF.md` - Quick reference
- `/tmp/cosmic-agent-test/PROJECT-SUMMARY.md` - Learning summary

These show what documentation **should** be built into cosmic itself.
