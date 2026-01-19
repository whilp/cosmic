# Doctest System for cosmic-lua

This directory contains the doctest extraction system for cosmic-lua. It provides tools to extract executable examples from source code comments and documentation files.

## Components

### 1. `example.tl` - Core Data Structures

Provides type-safe data structures for representing code examples:

- **Example**: Individual code example with metadata
  - `id`: Unique identifier (file:line:kind)
  - `source_file`: Where the example came from
  - `source_line`: Line number in source
  - `kind`: "example", "setup", or "teardown"
  - `code`: The executable code
  - `expected_output`: Expected output (for text examples)
  - `tags`: Optional tags for categorization

- **ExampleCollection**: Collection of examples with indexing
  - Indexed by ID and source file
  - Separate lists for setup/teardown examples
  - Statistics (total count, file count)

### 2. `extractor.tl` - Extraction Engine

Extracts examples from source files and saves them as JSON.

**Supported formats:**

#### Teal Source Files (.tl)

Extract examples from `---` comments with `@example` tags:

```teal
--- Adds two numbers.
---
---@example
--- local result = add(2, 3)
--- assert(result == 5, "2 + 3 should equal 5")

---@example:setup
--- -- Setup code run before examples
--- local test_value = 42

---@example:teardown
--- -- Cleanup code run after examples
--- test_value = nil
```

#### Text Documentation Files (.txt)

Extract examples using Python doctest-style `>>>` format:

```
You can add numbers:

>>> local x = 1 + 1
>>> print(x)
2

The line after the code is the expected output.
```

## Usage

### Extract Examples from a Directory

```bash
# Using compiled version
cosmic o/lib/build/doctest/extractor.lua <directory> <output.json>

# Example
cosmic o/lib/build/doctest/extractor.lua lib lib/.doctest.extracted
```

### Extract from Specific Files

The extractor automatically processes:
- All `.tl` files for @example annotations
- All `.txt` files for >>> examples

### Output Format

Examples are saved as JSON:

```json
{
  "examples": {
    "spawn.tl:42:example": {
      "id": "spawn.tl:42:example",
      "source_file": "lib/cosmic/spawn.tl",
      "source_line": 42,
      "kind": "example",
      "code": "local handle = spawn({\"echo\", \"hello\"})\nassert(handle ~= nil)",
      "expected_output": "",
      "requires_setup": false,
      "requires_teardown": false,
      "tags": []
    }
  },
  "total_count": 1,
  "file_count": 1
}
```

## Validation

The extractor validates examples:

- **Required fields**: code, source_file, source_line
- **Valid kinds**: example, setup, teardown
- **Warnings**: Examples without assertions

Exit codes:
- `0`: Success, all examples valid
- `1`: Warnings or errors found

## Example Guidelines

### Good Examples

```teal
---@example
--- -- Test basic addition
--- local result = add(2, 3)
--- assert(result == 5, "expected 5")
```

**Why good:**
- Has clear description
- Includes assertion
- Tests one thing

### Bad Examples

```teal
---@example
--- local result = add(2, 3)
```

**Problems:**
- No assertion (can't verify correctness)
- No description

### Setup/Teardown

Use setup for shared test data:

```teal
---@example:setup
--- local test_data = {1, 2, 3}

---@example
--- local sum = array_sum(test_data)
--- assert(sum == 6)
```

## Integration with Build System

The doctest files are compiled as part of the build system via `lib/build/cook.mk`:

```makefile
build_doctest_example := $(o)/lib/build/doctest/example.lua
build_doctest_extractor := $(o)/lib/build/doctest/extractor.lua
```

## Future Work

- **Runner**: Execute extracted examples and verify assertions
- **Coverage**: Report which functions have examples
- **Integration**: Add to CI/CD pipeline
- **Web Interface**: Browse examples interactively

## API Reference

### example.tl

```lua
local example = require("build.doctest.example")

-- Create collection
local collection = example.new_collection()

-- Create example
local ex = example.new_example({
  source_file = "test.tl",
  source_line = 10,
  kind = "example",
  code = "assert(true)",
  expected_output = "",
  tags = {},
})

-- Validate
local valid, err = example.validate_example(ex)

-- Check assertions
local has_asserts = example.has_assertions(ex)

-- Add to collection
example.add_example(collection, ex)
```

### extractor.tl

```lua
local extractor = require("build.doctest.extractor")

-- Extract from file
local examples, errors = extractor.extract_from_file("lib/cosmic/spawn.tl")

-- Extract from directory
local result = extractor.extract_from_directory("lib", "%.tl$")
-- result.collection, result.errors, result.warnings

-- Save/load JSON
extractor.save_collection_json(collection, "output.json")
local loaded = extractor.load_collection_json("output.json")
```

## Testing

Run the example module tests:

```bash
cosmic lib/build/doctest/test_example.tl
```

This validates:
- Collection creation
- Example validation
- Assertion detection
- Dedentation logic
