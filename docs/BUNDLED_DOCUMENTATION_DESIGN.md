# Bundled Documentation Design

**Author**: Claude
**Date**: 2026-01-19
**Status**: Proposed

## Overview

Documentation should be accessible directly from the cosmic-lua binary without requiring internet access or external files. This document describes how to bundle, access, and maintain documentation within the distributed binary.

## Current State

The cosmic-lua binary already includes:
- **Type definitions** at `.lua/types/*.d.tl`
- **Compiled modules** at `.lua/cosmic/*.lua`
- **Third-party types** at `.lua/teal-types/`
- **Help system** via `cosmic --help [module]` that displays module metadata (`_VERSION`, `_DESCRIPTION`, `_USAGE`)

The help system works by requiring modules and displaying their exported metadata fields.

## Proposed Bundled Documentation System

### 1. Documentation Bundle Structure

Add documentation files to the binary's embedded ZIP:

```
.lua/
├── cosmic/           # Existing: compiled modules
├── types/            # Existing: type definitions
├── teal-types/       # Existing: third-party types
└── docs/             # NEW: bundled documentation
    ├── llm.txt       # Agent-optimized documentation
    ├── README.txt    # Getting started guide
    ├── modules/      # Module-specific docs
    │   ├── cosmo.txt
    │   ├── cosmic.spawn.txt
    │   ├── cosmic.fetch.txt
    │   ├── cosmic.walk.txt
    │   └── cosmic.teal.txt
    ├── guides/       # Topic-based guides
    │   ├── processes.txt
    │   ├── http.txt
    │   ├── teal.txt
    │   └── building.txt
    └── api/          # Full API reference
        └── reference.txt
```

### 2. CLI Access Methods

#### 2.1 Module Help (Enhanced)

```bash
# Current: Basic help from module metadata
cosmic --help cosmic.spawn

# Enhanced: Show full documentation from bundled docs
cosmic --help cosmic.spawn
```

**Implementation**: Check for `.lua/docs/modules/<module>.txt` first, fall back to module metadata.

#### 2.2 Topic-Based Help

```bash
# Show guide about process management
cosmic --help-guide processes

# Show guide about HTTP fetching
cosmic --help-guide http
```

**New option**: `--help-guide <topic>` loads from `.lua/docs/guides/`

#### 2.3 Full Documentation

```bash
# Show all documentation (paged)
cosmic --docs

# Extract documentation to current directory
cosmic --docs-extract [output-dir]

# Show llm.txt for agent consumption
cosmic --llm-txt
```

#### 2.4 Search Documentation

```bash
# Search all documentation
cosmic --help-search "spawn process"

# List all available help topics
cosmic --help-list
```

### 3. Documentation Format

#### 3.1 Plain Text with Structure

Use plain text with minimal formatting for maximum compatibility:

```
COSMIC.SPAWN - Process Spawning Utilities

VERSION
  0.1.0

DESCRIPTION
  Provides a typed interface for spawning subprocesses with automatic
  pipe management. Built on cosmo.unix primitives.

SYNOPSIS
  local spawn = require("cosmic.spawn")
  local handle = spawn(argv, opts?)

FUNCTIONS
  spawn(argv, opts?) -> SpawnHandle, string
    Spawns a subprocess with the given command and arguments.

    Parameters:
      argv      {string}     Command and arguments (argv[1] is command)
      opts      SpawnOpts?   Optional configuration
        .stdin    string | number   Input data or file descriptor
        .stdout   number            Output file descriptor
        .stderr   number            Error file descriptor
        .env      {string}          Environment variables

    Returns:
      handle    SpawnHandle   Process handle with pid and pipes
      error     string        Error message if spawn failed

  SpawnHandle:wait() -> number, string
    Waits for process to complete.

    Returns:
      code      number        Exit code (0-255)
      error     string        Error if abnormal termination

  SpawnHandle:read(size?) -> boolean | string, string, number
    Reads stdout and waits for completion.

    Parameters:
      size      number?       Bytes to read (nil = read all)

    Returns:
      ok        boolean       true if exit code was 0
      output    string        Stdout contents
      code      number        Exit code

EXAMPLES
  Basic command execution:

    local spawn = require("cosmic.spawn")
    local handle = spawn({"git", "status"})
    local ok, output, code = handle:read()
    if not ok then
      error("Command failed with code: " .. code)
    end
    print(output)

  Passing input:

    local handle = spawn({"grep", "error"}, {
      stdin = "line 1\nerror here\nline 3\n"
    })
    local ok, output = handle:read()
    print(output)  -- "error here\n"

  Streaming output:

    local handle = spawn({"npm", "install"}, {
      stdout = 1,  -- Inherit stdout
      stderr = 2   -- Inherit stderr
    })
    local code = handle:wait()

ERROR HANDLING
  spawn() returns nil, error_message on failure:
    - "command not found: <cmd>" if command not in PATH
    - "fork failed" if unable to create process

  SpawnHandle:wait() returns nil, error_message if process crashes

  SpawnHandle:read() returns nil, error_message if stdout not captured

SEE ALSO
  cosmo.unix - Low-level Unix system calls
  cosmic.fetch - HTTP client
  /zip/.lua/types/cosmo/unix.d.tl - Type definitions

SOURCE
  /zip/.lua/cosmic/spawn.lua
```

#### 3.2 LLM.txt Format

Keep existing llm.txt format (markdown-based, optimized for agents):
- Hierarchical structure
- Rich examples
- Type signatures
- Common patterns
- No manual pages-style formatting

### 4. Documentation Generation

#### 4.1 Build-Time Generation

Add to Makefile:

```makefile
# Generate bundled documentation
$(o)/.lua/docs/modules/%.txt: lib/cosmic/%.tl lib/build/gen-doc-txt.tl
	@mkdir -p $(dir $@)
	@$(cosmic) lib/build/gen-doc-txt.tl $< > $@

# Generate llm.txt
$(o)/.lua/docs/llm.txt: $(cosmic_tl_files) lib/build/gen-docs-llm.tl
	@$(cosmic) lib/build/gen-docs-llm.tl > $@

# Add to binary dependencies
cosmic_doc_files := \
  $(o)/.lua/docs/llm.txt \
  $(o)/.lua/docs/README.txt \
  $(patsubst lib/cosmic/%.tl,$(o)/.lua/docs/modules/%.txt,$(cosmic_tl_files))

$(o)/bin/cosmic: $(cosmic_doc_files)
```

#### 4.2 Documentation Extractor (`gen-doc-txt.tl`)

Parser that extracts from Teal source:
- Module-level docstrings
- Function signatures and docstrings
- Type definitions
- Usage examples from comments
- Cross-references

Outputs plain text manual pages.

### 5. Enhanced Help System Implementation

#### 5.1 Main Dispatcher Updates

Update `lib/cosmic/main.tl`:

```lua
-- New options
local record Opts
  -- ... existing fields ...
  help_guide: string      -- --help-guide <topic>
  docs: boolean           -- --docs
  docs_extract: string    -- --docs-extract [dir]
  llm_txt: boolean        -- --llm-txt
  help_search: string     -- --help-search <query>
  help_list: boolean      -- --help-list
end

local longopts: {LongOpt} = {
  -- ... existing ...
  { "help-guide", "required", nil },
  { "docs", "none", nil },
  { "docs-extract", "optional", nil },
  { "llm-txt", "none", nil },
  { "help-search", "required", nil },
  { "help-list", "none", nil },
}
```

#### 5.2 Documentation Access Module (`cosmic.docs`)

Create `lib/cosmic/docs.tl`:

```lua
local cosmo = require("cosmo")
local record docs
  get: function(path: string): string, string
  list: function(): {string}
  search: function(query: string): {{path: string, line: number, text: string}}
  extract_all: function(dest_dir: string): boolean, string
end

-- Get documentation from embedded zip
function docs.get(path: string): string, string
  local full_path = "/zip/.lua/docs/" .. path
  local content = cosmo.Slurp(full_path)
  if content then
    return content
  end
  return nil, "documentation not found: " .. path
end

-- List all available documentation files
function docs.list(): {string}
  local walk = require("cosmic.walk")
  local files = walk.collect_all("/zip/.lua/docs")
  local result: {string} = {}
  for path in pairs(files) do
    table.insert(result, path)
  end
  return result
end

-- Search documentation content
function docs.search(query: string): {{path: string, line: number, text: string}}
  local results = {}
  for _, doc_path in ipairs(docs.list()) do
    local content = docs.get(doc_path)
    if content then
      local line_num = 0
      for line in content:gmatch("[^\n]+") do
        line_num = line_num + 1
        if line:lower():find(query:lower(), 1, true) then
          table.insert(results, {
            path = doc_path,
            line = line_num,
            text = line
          })
        end
      end
    end
  end
  return results
end

-- Extract all documentation to directory
function docs.extract_all(dest_dir: string): boolean, string
  local unix = require("cosmo.unix")

  if not unix.makedirs(dest_dir) then
    return nil, "failed to create directory: " .. dest_dir
  end

  for _, doc_path in ipairs(docs.list()) do
    local content = docs.get(doc_path)
    local dest_path = dest_dir .. "/" .. doc_path
    local dir = dest_path:match("(.+)/[^/]+$")
    if dir then
      unix.makedirs(dir)
    end
    cosmo.Barf(dest_path, content)
  end

  return true
end

return docs
```

#### 5.3 Enhanced Help Handler

Update help handling in `main.tl`:

```lua
-- Handle --help [module]
if opts.help then
  if type(opts.help) == "string" then
    -- Try bundled documentation first
    local docs = require("cosmic.docs")
    local doc_path = "modules/" .. (opts.help as string) .. ".txt"
    local content, err = docs.get(doc_path)

    if content then
      io.write(content)
      return 0
    end

    -- Fall back to module metadata
    local ok, mod = pcall(require, opts.help as string)
    if ok and type(mod) == "table" then
      -- ... existing metadata display ...
    else
      io.stderr:write("No documentation found for: " .. (opts.help as string) .. "\n")
      return 1
    end
  else
    -- General help - show from bundled README
    local docs = require("cosmic.docs")
    local content = docs.get("README.txt")
    if content then
      io.write(content)
    else
      -- Fallback to inline help
      io.write("cosmic-lua: cosmopolitan lua with bundled libraries\n")
      -- ... existing inline help ...
    end
    return 0
  end
end

-- Handle --help-guide <topic>
if opts.help_guide then
  local docs = require("cosmic.docs")
  local content, err = docs.get("guides/" .. opts.help_guide .. ".txt")
  if content then
    io.write(content)
    return 0
  else
    io.stderr:write(err .. "\n")
    return 1
  end
end

-- Handle --llm-txt
if opts.llm_txt then
  local docs = require("cosmic.docs")
  local content, err = docs.get("llm.txt")
  if content then
    io.write(content)
    return 0
  else
    io.stderr:write(err .. "\n")
    return 1
  end
end

-- Handle --docs
if opts.docs then
  local docs = require("cosmic.docs")
  local content = docs.get("api/reference.txt") or docs.get("llm.txt")
  if content then
    -- Pipe through pager if available
    local spawn = require("cosmic.spawn")
    local pager = unix.commandv("less") or unix.commandv("more")
    if pager then
      local handle = spawn({pager}, {stdin = content, stdout = 1})
      handle:wait()
    else
      io.write(content)
    end
    return 0
  end
end

-- Handle --docs-extract [dir]
if opts.docs_extract then
  local dest = opts.docs_extract ~= true and opts.docs_extract or "./cosmic-docs"
  local docs = require("cosmic.docs")
  local ok, err = docs.extract_all(dest as string)
  if ok then
    io.write("Documentation extracted to: " .. (dest as string) .. "\n")
    return 0
  else
    io.stderr:write(err .. "\n")
    return 1
  end
end

-- Handle --help-search <query>
if opts.help_search then
  local docs = require("cosmic.docs")
  local results = docs.search(opts.help_search)

  if #results == 0 then
    io.write("No matches found for: " .. opts.help_search .. "\n")
    return 0
  end

  io.write("Found " .. #results .. " matches:\n\n")
  for _, result in ipairs(results) do
    io.write(result.path .. ":" .. result.line .. ": " .. result.text .. "\n")
  end
  return 0
end

-- Handle --help-list
if opts.help_list then
  local docs = require("cosmic.docs")
  io.write("Available documentation:\n\n")
  io.write("Modules:\n")
  for _, path in ipairs(docs.list()) do
    if path:match("^modules/") then
      local name = path:match("modules/(.+)%.txt$")
      if name then
        io.write("  cosmic --help " .. name .. "\n")
      end
    end
  end
  io.write("\nGuides:\n")
  for _, path in ipairs(docs.list()) do
    if path:match("^guides/") then
      local name = path:match("guides/(.+)%.txt$")
      if name then
        io.write("  cosmic --help-guide " .. name .. "\n")
      end
    end
  end
  return 0
end
```

### 6. Module Metadata Enhancement

Modules should continue to export metadata for lightweight help:

```lua
local record cosmic_spawn
  _VERSION: string
  _DESCRIPTION: string
  _USAGE: string
  _DOCS_PATH: string  -- NEW: path to full documentation

  spawn: function(...)
  -- ... other exports ...
end

local M: cosmic_spawn = {
  _VERSION = "0.1.0",
  _DESCRIPTION = "Process spawning with pipe management",
  _USAGE = "local spawn = require('cosmic.spawn'); spawn({'cmd', 'args'})",
  _DOCS_PATH = "modules/cosmic.spawn.txt",
  spawn = spawn,
}
```

### 7. Documentation Update Workflow

#### Development
```bash
# Edit source with docstrings
vim lib/cosmic/spawn.tl

# Regenerate documentation
make docs

# Test help system
o/bin/cosmic --help cosmic.spawn

# Review bundled docs
o/bin/cosmic --docs-extract /tmp/docs
cat /tmp/docs/modules/cosmic.spawn.txt
```

#### CI/CD
```yaml
# .github/workflows/pr.yml
- name: Generate documentation
  run: make docs

- name: Check documentation coverage
  run: make docs-check

- name: Test help system
  run: |
    o/bin/cosmic --help cosmic.spawn
    o/bin/cosmic --llm-txt > /dev/null
    o/bin/cosmic --help-list
```

### 8. Documentation Size Considerations

**Target Sizes**:
- llm.txt: ~150-200KB (agent-optimized, comprehensive)
- Module docs: ~5-10KB each (5 modules = 25-50KB)
- Guides: ~10-20KB each (4 guides = 40-80KB)
- Total: ~250-350KB bundled documentation

**Current binary size**: 5.9MB
**Documentation overhead**: ~6% increase
**Verdict**: Acceptable for improved usability

### 9. Progressive Enhancement

#### Phase 1: Basic Bundling
- Bundle existing README.md as README.txt
- Bundle llm.txt
- Add `--llm-txt` and `--docs-extract` options

#### Phase 2: Module Documentation
- Generate module docs from source
- Enhance `--help <module>` to use bundled docs
- Add `--help-list`

#### Phase 3: Guides and Search
- Write topic-based guides
- Implement `--help-guide`
- Add `--help-search`

#### Phase 4: Rich Formatting
- Optional: Add markdown rendering for terminals with color support
- Optional: Generate HTML docs that can be opened in browser

### 10. Usage Examples

#### For Users

```bash
# Quick help
cosmic --help cosmic.spawn

# Browse all documentation
cosmic --docs

# Extract docs for offline reading
cosmic --docs-extract ~/cosmic-docs
cd ~/cosmic-docs
cat modules/cosmic.spawn.txt

# Search for specific topic
cosmic --help-search "retry"

# Get agent-optimized docs
cosmic --llm-txt > cosmic-context.txt
# Feed to LLM agent

# List all available help
cosmic --help-list
```

#### For Agents

```lua
-- Access documentation programmatically
local docs = require("cosmic.docs")

-- Get specific module documentation
local spawn_docs = docs.get("modules/cosmic.spawn.txt")

-- Get agent-optimized documentation
local llm_docs = docs.get("llm.txt")

-- Search documentation
local results = docs.search("spawn process")
for _, result in ipairs(results) do
  print(result.path, result.line, result.text)
end
```

### 11. Benefits

1. **Offline Access**: No internet required to read documentation
2. **Version Consistency**: Docs always match binary version
3. **Portability**: Single file includes everything
4. **Discoverability**: Built-in search and listing
5. **Multi-Format**: Plain text for humans, llm.txt for agents
6. **Extractable**: Can export docs for external tooling
7. **Scriptable**: Programmatic access via cosmic.docs module

### 12. Alternatives Considered

#### Alternative 1: Man Pages
**Pros**: Standard Unix format, tooling support
**Cons**: Requires installation, not portable with binary, platform-specific
**Verdict**: Rejected - breaks single-file portability

#### Alternative 2: Web-Only Documentation
**Pros**: Easy to update, rich formatting
**Cons**: Requires internet, can go out of sync with binary
**Verdict**: Rejected as primary method, but complement bundled docs with website

#### Alternative 3: Separate Documentation Package
**Pros**: Smaller binary
**Cons**: Two files to distribute, easy to lose docs
**Verdict**: Rejected - defeats single-file philosophy

### 13. Implementation Checklist

- [ ] Create `lib/cosmic/docs.tl` module
- [ ] Create `lib/build/gen-doc-txt.tl` generator
- [ ] Update `lib/cosmic/main.tl` with new options
- [ ] Add documentation generation to Makefile
- [ ] Write initial module documentation
- [ ] Write topic guides
- [ ] Update llm.txt generation
- [ ] Test help system
- [ ] Update README with documentation access instructions
- [ ] Add to CI pipeline

### 14. Open Questions

1. **Pagination**: Should `--help` output be automatically paged for long docs?
2. **Formatting**: Support ANSI colors for better readability in terminals?
3. **Localization**: Plan for multiple languages in bundled docs?
4. **Compression**: Should docs be gzip compressed within the zip? (Zip already compresses)
5. **Updates**: Mechanism for users to update docs without replacing binary?

## Conclusion

Bundling documentation directly in the cosmic-lua binary enhances usability while maintaining the single-file distribution philosophy. The proposed system provides multiple access methods for both humans and agents, with progressive enhancement allowing incremental implementation.

The combination of:
- Built-in help system (`--help`)
- Topic guides (`--help-guide`)
- Full reference (`--docs`)
- Agent format (`--llm-txt`)
- Extraction (`--docs-extract`)
- Search (`--help-search`)

...creates a comprehensive documentation experience that works offline and stays synchronized with code.
