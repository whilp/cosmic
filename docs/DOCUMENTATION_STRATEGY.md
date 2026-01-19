# Cosmic Lua Documentation Strategy

**Author**: Claude
**Date**: 2026-01-19
**Status**: Proposed

## Executive Summary

This document outlines a comprehensive strategy for documenting the cosmic-lua project, focusing on generating consistent, maintainable documentation from Teal source code that serves both human developers and LLM agents.

## Current State Analysis

### What We Have

1. **Type Definitions** (`lib/types/*.d.tl`):
   - Complete API signatures for cosmo and submodules
   - Bundled in binary at `.lua/types/`
   - ~6KB of type information

2. **Source Code** (`lib/cosmic/*.tl`):
   - Teal implementation with type annotations
   - Variable inline documentation quality
   - Rich examples in test files

3. **Basic Documentation**:
   - README.md with getting started info
   - Some module-level comments
   - Test files as implicit examples

4. **Bundled Resources** (in binary):
   - Type definitions for Teal standard library
   - Third-party type definitions (~180+ libraries)
   - Compiled cosmic modules
   - Base Cosmopolitan definitions.lua (338KB)

### What's Missing

1. **Comprehensive API Reference**: No systematic documentation of all functions, parameters, return values
2. **Usage Guides**: Limited how-to documentation beyond README
3. **Agent-Optimized Formats**: No llm.txt or similar structured format
4. **Architecture Documentation**: System design and patterns not documented
5. **Change Management**: No process for keeping docs synchronized with code
6. **Discoverability**: Documentation not easily searchable or navigable

## Documentation Goals

### Primary Objectives

1. **Consistency**: All modules documented to same standard
2. **Accuracy**: Documentation always matches implementation
3. **Accessibility**: Easy to find and understand for both humans and agents
4. **Maintainability**: Documentation updates automated as part of build
5. **Comprehensiveness**: Cover API, usage patterns, architecture, examples

### Target Audiences

#### Human Developers
- Need: Tutorials, guides, API reference, examples, troubleshooting
- Format: Markdown, HTML, interactive examples
- Discovery: Search, navigation, cross-references

#### LLM Agents
- Need: Structured API data, type signatures, usage patterns, context
- Format: llm.txt, JSON schemas, embedded metadata
- Discovery: Hierarchical structure, keyword indexing

## Proposed Documentation Architecture

### Three-Tier System

```
┌─────────────────────────────────────────────────────┐
│ TIER 1: Source Documentation                       │
│ - Inline comments in .tl files                     │
│ - Structured docstrings (new format)               │
│ - Type annotations (existing)                      │
└─────────────────┬───────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────┐
│ TIER 2: Generated Documentation                    │
│ - API reference (markdown)                         │
│ - Type documentation (HTML)                        │
│ - llm.txt (agent-optimized)                       │
└─────────────────┬───────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────┐
│ TIER 3: Curated Documentation                      │
│ - Guides and tutorials                             │
│ - Architecture docs                                │
│ - Migration guides                                 │
└─────────────────────────────────────────────────────┘
```

## Implementation Strategy

### Phase 1: Documentation Format Standards

#### 1.1 Structured Docstring Format

Adopt a Teal-friendly docstring format similar to LuaLS:

```lua
--- Module description (one line)
---
--- Detailed description of the module's purpose and capabilities.
--- Can span multiple lines.
---
---@module cosmic.spawn

--- Spawns a subprocess with the given command and arguments.
---
--- Resolves commands via PATH if not absolute. Creates pipes for
--- stdin/stdout/stderr unless file descriptors are provided.
---
---@param argv {string} Command and arguments (argv[1] is command)
---@param opts? SpawnOpts Configuration options
---@return SpawnHandle|nil Process handle
---@return string? Error message if spawn failed
---@usage
---   local spawn = require("cosmic.spawn")
---   local handle = spawn({"echo", "hello"})
---   local ok, output = handle:read()
local function spawn(argv: {string}, opts?: SpawnOpts): SpawnHandle, string
```

**Rationale**:
- Compatible with LuaLS tooling
- Machine-parseable
- Doesn't interfere with Teal syntax
- Provides all needed metadata (params, returns, examples)

#### 1.2 Module-Level Documentation

Each module should have:

```lua
--- cosmic.spawn: Process spawning utilities
---
--- Provides a safe, typed interface for spawning subprocesses with
--- full control over stdin/stdout/stderr. Built on cosmo.unix primitives.
---
---@module cosmic.spawn
---@version 0.1.0
---@author Cosmic Lua Contributors
---@license Apache-2.0
---@since 0.1.0
```

#### 1.3 Type Documentation

Record types should document their fields:

```lua
--- Handle for a spawned process.
---
--- Provides methods to interact with the running process and
--- wait for completion.
local record SpawnHandle
  --- Process ID
  pid: number

  --- Standard input pipe (writable)
  stdin: Pipe

  --- Standard output pipe (readable)
  stdout: Pipe

  --- Standard error pipe (readable)
  stderr: Pipe

  --- Wait for process to complete.
  ---@return number Exit code (0-255)
  ---@return string? Error message if abnormal termination
  wait: function(self: SpawnHandle): number, string
end
```

### Phase 2: Documentation Generation Tools

#### 2.1 Teal Documentation Parser (`lib/build/tldoc.tl`)

Create a Teal parser that extracts:
- Module metadata
- Function signatures with docstrings
- Type definitions with field docs
- Usage examples
- Cross-references

**Input**: `.tl` source files
**Output**: Structured JSON representation

```json
{
  "module": "cosmic.spawn",
  "version": "0.1.0",
  "description": "Process spawning utilities",
  "functions": [
    {
      "name": "spawn",
      "signature": "function(argv: {string}, opts?: SpawnOpts): SpawnHandle, string",
      "params": [
        {"name": "argv", "type": "{string}", "description": "Command and arguments"},
        {"name": "opts", "type": "SpawnOpts", "optional": true, "description": "Configuration options"}
      ],
      "returns": [
        {"type": "SpawnHandle|nil", "description": "Process handle"},
        {"type": "string", "optional": true, "description": "Error message if spawn failed"}
      ],
      "examples": ["local handle = spawn({\"echo\", \"hello\"})"]
    }
  ],
  "types": [...]
}
```

#### 2.2 Markdown Generator (`lib/build/gen-docs-md.tl`)

Converts JSON to human-readable markdown:

```markdown
# cosmic.spawn

Process spawning utilities.

## Functions

### spawn(argv, opts?)

Spawns a subprocess with the given command and arguments.

**Parameters:**
- `argv` ({string}): Command and arguments
- `opts` (SpawnOpts, optional): Configuration options

**Returns:**
- (SpawnHandle|nil): Process handle
- (string, optional): Error message if spawn failed

**Example:**
```lua
local spawn = require("cosmic.spawn")
local handle = spawn({"echo", "hello"})
local ok, output = handle:read()
```
```

#### 2.3 LLM.txt Generator (`lib/build/gen-docs-llm.tl`)

Converts JSON to agent-optimized format following llm.txt conventions:

```
# cosmic-lua

> A single-file, self-contained Lua interpreter built on Cosmopolitan Libc

## Quick Start

cosmic-lua is a portable Lua 5.4 interpreter with Teal support that runs
on Linux, macOS, Windows, and BSD systems without installation.

## Core Modules

### cosmic.spawn - Process spawning utilities

```lua
spawn(argv: {string}, opts?: SpawnOpts): SpawnHandle, string
```

Spawns a subprocess with command and arguments. Resolves via PATH if not absolute.

Parameters:
- argv: Command and arguments (argv[1] is command)
- opts: Optional configuration (stdin, stdout, stderr, env)

Returns:
- handle: SpawnHandle with pid and pipes (stdin/stdout/stderr)
- error: Error message if spawn failed

Example:
```lua
local spawn = require("cosmic.spawn")
local handle = spawn({"git", "status"})
local ok, output, code = handle:read()
if not ok then
  print("Failed with exit code: " .. code)
end
```

Common patterns:
- Capture output: handle:read() returns ok, stdout, exit_code
- Stream output: Don't capture stdout with opts.stdout = 1
- Pipe data: opts.stdin = "data" or opts.stdin = file_descriptor
- Custom environment: opts.env = {"PATH=/bin", "HOME=/tmp"}
```

**Key Features of llm.txt Format**:
1. **Flat hierarchy**: Minimal nesting for easy parsing
2. **Context-rich**: Each section self-contained
3. **Example-heavy**: Code samples for every function
4. **Pattern-oriented**: Common usage patterns documented
5. **Type-aware**: Full signatures with type information
6. **Search-optimized**: Keywords and variations included

### Phase 3: Build System Integration

#### 3.1 New Make Targets

```makefile
# Documentation generation
.PHONY: docs docs-md docs-llm docs-check

# Generate all documentation
docs: docs-md docs-llm

# Generate markdown API reference
docs-md: $(o)/docs/api/
	@$(cosmic) lib/build/gen-docs-md.tl

# Generate llm.txt
docs-llm: $(o)/docs/llm.txt
	@$(cosmic) lib/build/gen-docs-llm.tl

# Check documentation coverage
docs-check:
	@$(cosmic) lib/build/check-docs.tl

# Add docs to CI pipeline
ci: teal test build docs-check
```

#### 3.2 Documentation Validation

Create `lib/build/check-docs.tl` to verify:
- All public functions have docstrings
- All parameters documented
- All return values documented
- Examples provided for complex functions
- No broken cross-references

Fail the build if coverage < threshold (e.g., 90%).

#### 3.3 Continuous Documentation

```makefile
# Watch mode for development
docs-watch:
	@while true; do \
		$(MAKE) docs; \
		inotifywait -qre modify lib/cosmic/*.tl lib/types/*.tl; \
	done
```

### Phase 4: Documentation Delivery

#### 4.1 For Humans

**Local Development**:
- `docs/api/` - Generated markdown API reference
- `docs/guides/` - Curated tutorials and guides
- `docs/examples/` - Standalone example scripts

**Website** (future):
- Static site generator (e.g., mkdocs, docusaurus)
- Searchable API reference
- Interactive examples
- Version switcher

**In Binary**:
```bash
cosmic --help cosmic.spawn  # Show module help
cosmic --help               # Show general help
```

#### 4.2 For LLM Agents

**Primary Format**: `llm.txt` at repository root

```
cosmic-lua/
├── llm.txt                    # Main agent documentation
├── llm-files.txt              # Directory of related files
└── docs/
    ├── llm/
    │   ├── api-schema.json    # Structured API schema
    │   └── patterns.md        # Common patterns and recipes
    └── api/
```

**llm.txt Structure**:
```
# Project Overview (300-500 words)
# Quick Start (with examples)
# Core Concepts
# API Reference
  ## cosmo (base APIs)
  ## cosmic.spawn
  ## cosmic.fetch
  ## cosmic.walk
  ## cosmic.teal
  ## CLI Usage
# Common Patterns
# Troubleshooting
# Build System Integration
```

**llm-files.txt**: Lists relevant source files with brief descriptions

```
> Key source files for cosmic-lua

lib/cosmic/spawn.tl: Process spawning with pipes
lib/cosmic/fetch.tl: HTTP fetching with retries
lib/cosmic/walk.tl: Directory tree traversal
lib/cosmic/teal.tl: Teal compiler integration
lib/cosmic/main.tl: CLI argument parsing and dispatch
lib/types/cosmo.d.tl: Type definitions for base cosmo APIs
lib/types/cosmo/unix.d.tl: Unix system call types
Makefile: Build orchestration
```

**Discoverability**:
- Link from README.md
- GitHub repository description: "See llm.txt for documentation"
- `.well-known/llm.txt` (if hosting documentation site)

### Phase 5: Documentation Standards & Guidelines

#### 5.1 Writing Guidelines

**Documentation Principles**:
1. **Show, don't just tell**: Every function should have at least one example
2. **Context matters**: Explain why, not just what
3. **Be specific**: "Returns process exit code (0-255)" not "Returns a number"
4. **Handle errors**: Document error conditions and error messages
5. **Link related items**: Cross-reference related functions and types

**Example Quality Standards**:
```lua
-- ❌ BAD: No context, minimal explanation
--- Spawn a process
---@param cmd string Command to run
---@return number Exit code
local function spawn(cmd: string): number

-- ✅ GOOD: Context, types, error handling, example
--- Spawns a subprocess and waits for completion.
---
--- Resolves the command via PATH if not an absolute path.
--- Creates pipes for stdout/stderr capture.
---
---@param argv {string} Command and arguments (argv[1] is the command)
---@param opts? SpawnOpts Optional configuration
---@return SpawnHandle|nil Process handle, or nil on error
---@return string? Error message if spawn failed
---@usage
---   local handle, err = spawn({"git", "status"})
---   if not handle then
---     error("Failed to spawn: " .. err)
---   end
local function spawn(argv: {string}, opts?: SpawnOpts): SpawnHandle, string
```

#### 5.2 Review Checklist

Before committing code with new APIs:

- [ ] Module-level docstring present
- [ ] All public functions documented
- [ ] All parameters explained with types
- [ ] Return values documented (including error cases)
- [ ] At least one usage example provided
- [ ] Related functions cross-referenced
- [ ] Edge cases and limitations noted
- [ ] `make docs-check` passes

### Phase 6: Maintaining Documentation Quality

#### 6.1 Automated Checks

**Pre-commit Hook**:
```bash
#!/bin/bash
# .git/hooks/pre-commit

# Check documentation coverage
if ! bin/make docs-check; then
  echo "Documentation check failed. Please document new/changed functions."
  exit 1
fi
```

**CI Integration**:
```yaml
# .github/workflows/pr.yml
- name: Check documentation
  run: bin/make docs-check

- name: Generate documentation
  run: bin/make docs

- name: Upload llm.txt artifact
  uses: actions/upload-artifact@v3
  with:
    name: llm-txt
    path: llm.txt
```

#### 6.2 Documentation Versioning

**For Major Releases**:
- Generate versioned documentation: `docs/v0.1/`
- Archive llm.txt with version tag: `llm-v0.1.0.txt`
- Maintain changelog of API changes

**For Development**:
- Always regenerate from latest source
- Include commit SHA in generated docs
- Mark unstable APIs clearly

## Documentation Content Plan

### Immediate Priorities (Phase 1)

1. **API Reference**:
   - Document all cosmic.* modules
   - Document CLI usage comprehensively
   - Document build system for contributors

2. **Getting Started Guide**:
   - Installation (binary download)
   - First script (hello world)
   - Running Teal code
   - Using cosmic libraries
   - Building from source

3. **LLM.txt v1**:
   - Complete API reference
   - Common patterns
   - Type system guide
   - Build system overview

### Medium Term (Phase 2)

4. **Guides**:
   - Process management patterns
   - HTTP client best practices
   - Teal type checking workflows
   - Testing strategies
   - Packaging applications

5. **Architecture Documentation**:
   - System design overview
   - Build system architecture
   - Module dependency graph
   - Binary structure (APE + ZIP)
   - Sandboxing with Landlock

6. **Contributing Guide**:
   - Development setup
   - Code style guidelines
   - Testing requirements
   - Documentation requirements
   - PR process

### Long Term (Phase 3)

7. **Advanced Topics**:
   - Extending cosmic with C modules
   - Embedding cosmic-lua
   - Cross-compilation
   - Performance tuning

8. **Reference Implementations**:
   - Complete application examples
   - Common use cases (CLI tools, web servers, automation)
   - Integration patterns (CI/CD, deployment)

## Tool Implementation Plan

### Recommended Implementation Order

1. **Week 1-2**: Documentation format standards
   - Define docstring format
   - Create examples in 2-3 modules
   - Get team alignment

2. **Week 3-4**: Parser implementation
   - Build `tldoc.tl` parser
   - Extract metadata from Teal AST
   - Generate JSON intermediate format

3. **Week 5-6**: Generator implementation
   - Build markdown generator
   - Build llm.txt generator
   - Test with existing modules

4. **Week 7-8**: Build integration
   - Add make targets
   - Integrate with CI
   - Create validation tools

5. **Week 9-10**: Content creation
   - Document all modules
   - Write getting started guide
   - Create llm.txt v1

6. **Week 11-12**: Polish and deployment
   - Review and refine
   - Setup documentation site
   - Announce and gather feedback

## Success Metrics

### Quantitative

- **Coverage**: 100% of public APIs documented
- **Examples**: ≥1 example per public function
- **Build Time**: Documentation generation <5s
- **File Size**: llm.txt <200KB (agent-friendly)
- **Update Lag**: Documentation always current (generated on build)

### Qualitative

- **Developer Satisfaction**: Easy to find what they need
- **Agent Performance**: LLMs can accurately use APIs from llm.txt
- **Maintenance Burden**: Low effort to keep docs current
- **Onboarding Time**: New contributors productive faster

## Open Questions

1. **Static Site Hosting**: Where to host human-readable docs? GitHub Pages, ReadTheDocs, custom?

2. **Version Strategy**: Support multiple versions simultaneously or only latest?

3. **API Stability**: Should we mark APIs as stable/unstable in docs?

4. **Interactive Examples**: Worth investing in runnable web-based examples?

5. **Localization**: Support non-English documentation?

## Alternatives Considered

### Alternative 1: Manual Documentation

**Pros**: Full control, can be very polished
**Cons**: High maintenance burden, gets out of sync, inconsistent

**Verdict**: Rejected. Not sustainable for small team.

### Alternative 2: External Tool (LDoc, LuaDoc)

**Pros**: Mature tools, existing ecosystem
**Cons**: Limited Teal support, less customization, external dependency

**Verdict**: Rejected. Teal needs custom handling.

### Alternative 3: Minimal Docs

**Pros**: Low effort, focus on code
**Cons**: Poor discoverability, hard for newcomers, unusable by agents

**Verdict**: Rejected. Documentation is essential for adoption.

## Conclusion

This strategy balances automation with quality, ensuring documentation stays current while serving both human and agent audiences. The phased approach allows incremental implementation while delivering value early.

### Next Steps

1. **Review this proposal** with maintainers
2. **Create prototype** parser and generator
3. **Document one module** end-to-end as proof of concept
4. **Iterate based on feedback**
5. **Roll out incrementally** module by module

### References

- [llm.txt specification](https://llmstxt.org/)
- [LuaLS annotation format](https://github.com/LuaLS/lua-language-server/wiki/Annotations)
- [Teal language guide](https://github.com/teal-language/tl)
- [Documentation-as-Code principles](https://www.writethedocs.org/guide/docs-as-code/)
