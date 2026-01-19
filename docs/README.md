# Cosmic Lua Documentation Strategy

This directory contains documentation strategy and design documents for the cosmic-lua project.

## Documentation Philosophy

The cosmic-lua documentation system is designed to:

1. **Stay in sync with code** - Generated from source, not manually maintained
2. **Serve multiple audiences** - Both humans and LLM agents
3. **Bundle with binary** - Documentation embedded in the distributed executable
4. **Provide multiple access patterns** - CLI, programmatic, extractable

## Strategy Documents

### Core Strategy
- **[DOCUMENTATION_STRATEGY.md](DOCUMENTATION_STRATEGY.md)** - Comprehensive documentation strategy covering generation, maintenance, and delivery for both human and agent consumption

### Design Specifications
- **[BUNDLED_DOCUMENTATION_DESIGN.md](BUNDLED_DOCUMENTATION_DESIGN.md)** - Detailed design for embedding documentation in the cosmic-lua binary with CLI access methods

### Generated Documentation
- **[modules/](modules/)** - Module-specific documentation (e.g., `cosmic.spawn.txt`)
- **[../llm.txt](../llm.txt)** - Agent-optimized documentation in llm.txt format at repository root

## Quick Start

### For Documentation Developers

1. **Read the strategy**: Start with `DOCUMENTATION_STRATEGY.md` for the big picture
2. **Understand bundling**: Read `BUNDLED_DOCUMENTATION_DESIGN.md` for implementation details
3. **Review examples**: Check `modules/cosmic.spawn.txt` for documentation format examples
4. **Examine prototypes**: See `lib/cosmic/docs.tl` for the documentation access module

### For Documentation Users

```bash
# View module documentation
cosmic --help cosmic.spawn

# Extract all documentation
cosmic --docs-extract ./docs

# Search documentation
cosmic --help-search "spawn"

# Get agent-optimized docs
cosmic --llm-txt
```

## Documentation Architecture

```
┌─────────────────────────────────────────┐
│ Source Code (lib/cosmic/*.tl)          │
│ - Structured docstrings                │
│ - Type annotations                     │
│ - Inline examples                      │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ Documentation Generator                 │
│ - Parses Teal source                   │
│ - Extracts metadata                    │
│ - Formats for different outputs        │
└──────────────┬──────────────────────────┘
               │
       ┌───────┴───────┐
       ▼               ▼
┌─────────────┐  ┌────────────┐
│ Human Docs  │  │ Agent Docs │
│ - Markdown  │  │ - llm.txt  │
│ - Plain txt │  │ - JSON     │
└─────────────┘  └────────────┘
       │               │
       └───────┬───────┘
               ▼
┌─────────────────────────────────────────┐
│ Bundled in Binary (/zip/.lua/docs/)    │
│ - Accessible via CLI                   │
│ - Programmatic access via cosmic.docs  │
│ - Extractable for offline use         │
└─────────────────────────────────────────┘
```

## Key Components

### 1. Source Documentation Format

Structured docstrings in Teal source files:

```lua
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

### 2. Documentation Generators

**Planned tools** (to be implemented):

- `lib/build/tldoc.tl` - Parse Teal source and extract documentation
- `lib/build/gen-docs-md.tl` - Generate markdown documentation
- `lib/build/gen-docs-txt.tl` - Generate plain text manual pages
- `lib/build/gen-docs-llm.tl` - Generate llm.txt for agents
- `lib/build/check-docs.tl` - Validate documentation coverage

### 3. Documentation Access

**CLI access** (via `lib/cosmic/main.tl`):
- `--help [module]` - Show module help
- `--help-guide <topic>` - Show topic guide
- `--docs` - Browse full documentation
- `--llm-txt` - Output agent documentation
- `--docs-extract <dir>` - Extract docs to directory
- `--help-search <query>` - Search documentation
- `--help-list` - List available documentation

**Programmatic access** (via `lib/cosmic/docs.tl`):
```lua
local docs = require("cosmic.docs")

-- Get documentation content
local content = docs.get("modules/cosmic.spawn.txt")

-- List all docs
local files = docs.list()

-- Search documentation
local results = docs.search("spawn process")

-- Extract all docs
docs.extract_all("/tmp/docs")
```

### 4. Bundled Documentation Structure

```
/zip/.lua/docs/
├── llm.txt                  # Agent-optimized documentation
├── README.txt               # Getting started guide
├── modules/                 # Module-specific documentation
│   ├── cosmic.spawn.txt
│   ├── cosmic.fetch.txt
│   ├── cosmic.walk.txt
│   └── cosmic.teal.txt
├── guides/                  # Topic-based guides
│   ├── processes.txt
│   ├── http.txt
│   ├── teal.txt
│   └── building.txt
└── api/                     # Full API reference
    └── reference.txt
```

## Implementation Status

### ✅ Completed

- [x] Documentation strategy defined
- [x] Bundled documentation design specified
- [x] Prototype `cosmic.docs` module created
- [x] Example module documentation (cosmic.spawn.txt)
- [x] Agent-optimized llm.txt created
- [x] Existing help system documented

### 🚧 In Progress

- [ ] Documentation generator tools
- [ ] Enhanced CLI help system
- [ ] Module documentation for all modules
- [ ] Topic guides

### 📋 Planned

- [ ] Build system integration
- [ ] CI/CD documentation checks
- [ ] Documentation coverage validation
- [ ] Markdown generation for website
- [ ] Additional module examples

## Contributing to Documentation

### Adding Documentation for New Modules

1. Add structured docstrings to your `.tl` source file
2. Export metadata in your module:
   ```lua
   local M = {
     _VERSION = "0.1.0",
     _DESCRIPTION = "Brief description",
     _USAGE = "Quick usage example",
   }
   ```
3. Run documentation generator (once implemented): `make docs`
4. Review generated documentation: `cosmic --help your.module`

### Writing Topic Guides

1. Create markdown file in `docs/guides/`
2. Convert to plain text for bundling
3. Add to build system
4. Test with: `cosmic --help-guide your-topic`

### Improving llm.txt

1. Edit `llm.txt` at repository root
2. Ensure all modules are documented
3. Include practical examples
4. Keep total size under 200KB
5. Test with LLM agents

## Documentation Quality Standards

### Required for All Public APIs

- [ ] Module-level docstring
- [ ] Function signatures with types
- [ ] Parameter descriptions
- [ ] Return value descriptions
- [ ] At least one usage example
- [ ] Error conditions documented
- [ ] Cross-references to related functions

### Recommended

- [ ] Multiple examples showing different use cases
- [ ] Common patterns documented
- [ ] Edge cases explained
- [ ] Performance considerations noted
- [ ] Security considerations mentioned

## Tools and Utilities

### Existing Tools

- `cosmic --help` - Built-in help system
- `cosmic --compile` - Teal to Lua compiler
- `cosmic --check` - Teal type checker

### Planned Tools

- `cosmic --docs-validate` - Check documentation coverage
- `cosmic --docs-lint` - Check documentation quality
- `cosmic --docs-stats` - Documentation statistics

## References

- [llm.txt specification](https://llmstxt.org/) - Format for LLM-optimized documentation
- [LuaLS annotations](https://github.com/LuaLS/lua-language-server/wiki/Annotations) - Lua documentation annotations
- [Teal language](https://github.com/teal-language/tl) - Typed Lua dialect
- [Cosmopolitan Libc](https://justine.lol/cosmopolitan/) - APE executable format

## Questions or Feedback?

- Open an issue: https://github.com/cosmopolitan-lang/cosmic/issues
- Review the strategy documents in this directory
- Examine the prototype implementations in `lib/cosmic/` and `lib/build/`

---

**Next Steps**: Implement the documentation generators and integrate with the build system. See DOCUMENTATION_STRATEGY.md for the detailed implementation plan.
