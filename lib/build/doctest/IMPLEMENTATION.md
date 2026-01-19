# Doctest System Implementation for cosmic-lua

**Date**: 2026-01-19
**Status**: Complete

## Overview

Implemented a complete doctest data structures and extraction system for cosmic-lua that can extract executable examples from both Teal source files and text documentation files.

## Files Created

### Core Implementation

#### 1. `/home/user/cosmic/lib/build/doctest/example.tl` (260 lines)

Core data structures for representing documentation examples:

**Key Types:**
- `Example` - Individual code example with metadata
  - `id`: Unique identifier (file:line:kind)
  - `source_file`, `source_line`: Source location
  - `kind`: "example", "setup", or "teardown"
  - `code`: Executable code
  - `expected_output`: Expected output (for text-based examples)
  - `tags`: Optional categorization tags

- `ExampleCollection` - Collection of examples with indexing
  - Indexed by ID and by source file
  - Separate lists for setup/teardown examples
  - Statistics tracking

**Key Functions:**
- `new_collection()`: Create empty collection
- `new_example(opts)`: Create example with validation
- `validate_example(ex)`: Validate example structure
- `has_assertions(ex)`: Check if example has assertions
- `add_example(collection, ex)`: Add to collection
- `dedent(code)`: Remove common indentation

#### 2. `/home/user/cosmic/lib/build/doctest/extractor.tl` (390 lines)

Main extraction engine that parses source files and extracts examples:

**Key Functions:**
- `extract_from_teal(file_path)`: Parse Teal files for @example annotations
- `extract_from_text(file_path)`: Parse .txt files for >>> example blocks
- `extract_from_file(file_path)`: Dispatch based on file extension
- `extract_from_directory(root_dir, pattern)`: Recursively extract from directory tree
- `save_collection_json(collection, output_path)`: Save as JSON
- `load_collection_json(input_path)`: Load from JSON
- `main(args)`: Command-line entry point

**Features:**
- Parses `---` comments in Teal files for @example tags
- Supports @example, @example:setup, @example:teardown
- Extracts Python-style doctest format (>>>) from text files
- Validates examples and warns about missing assertions
- Generates unique IDs for each example
- Saves as JSON for runner consumption

#### 3. `/home/user/cosmic/lib/build/doctest/test_example.tl` (75 lines)

Comprehensive test suite for the example module:

**Tests:**
- Collection creation
- Example creation and validation
- Invalid example detection
- Assertion detection (assert() calls and expected output)
- Collection operations (add, retrieve)
- Code dedentation

#### 4. `/home/user/cosmic/lib/build/doctest/README.md`

Complete documentation covering:
- System architecture
- Usage examples
- Supported formats (Teal @example and text >>>)
- Output format specification
- Validation rules
- Integration guidelines
- API reference

### Build System Integration

#### Modified: `/home/user/cosmic/lib/build/cook.mk`

Added doctest files to build system:
```makefile
build_lua_dirs := $(o)/lib/build $(o)/lib/build/doctest
build_doctest_example := $(o)/lib/build/doctest/example.lua
build_doctest_extractor := $(o)/lib/build/doctest/extractor.lua
build_files := ... $(build_doctest_example) $(build_doctest_extractor)
```

### Example Usage

#### Modified: `/home/user/cosmic/lib/cosmic/spawn.tl`

Added doctest examples to demonstrate the system:
```teal
---@example
--- local spawn = require("cosmic.spawn")
--- local handle = spawn({"echo", "hello"})
--- assert(handle ~= nil, "spawn should return a handle")
```

## Supported Example Formats

### 1. Teal Source Files (@example annotations)

```teal
--- Function description
---
---@example
--- local result = add(2, 3)
--- assert(result == 5)

---@example:setup
--- local test_data = {1, 2, 3}

---@example:teardown
--- test_data = nil
```

### 2. Text Documentation Files (>>> format)

```
You can add numbers:

>>> local x = 1 + 1
>>> print(x)
2

The expected output follows the code.
```

## Usage Examples

### Extract from Directory

```bash
# Using compiled Lua
cosmic o/lib/build/doctest/extractor.lua lib lib/.doctest.extracted

# Output:
# Extracting examples from: lib
# Found 2 examples in 1 files
# Saved examples to: lib/.doctest.extracted
```

### Run Tests

```bash
cosmic lib/build/doctest/test_example.tl
# All tests passed!
```

## Output Format

Examples are saved as JSON:

```json
{
  "examples": {
    "spawn.tl:67:example": {
      "id": "spawn.tl:67:example",
      "source_file": "lib/cosmic/spawn.tl",
      "source_line": 67,
      "kind": "example",
      "code": "local spawn = require(\"cosmic.spawn\")\nlocal handle = spawn({\"echo\", \"hello\"})\nassert(handle ~= nil)",
      "expected_output": "",
      "requires_setup": false,
      "requires_teardown": false,
      "tags": []
    }
  },
  "total_count": 2,
  "file_count": 1
}
```

## Validation

The extractor validates:
- Examples have code
- Examples have valid source location
- Kind is one of: example, setup, teardown
- Warns if no assertions found

Exit codes:
- `0`: Success, all valid
- `1`: Warnings or errors

## Key Design Decisions

### 1. Type Safety

All data structures use Teal's type system:
- Integer for line numbers (required by string.format %d)
- Explicit type annotations for all functions
- Type-safe JSON deserialization with explicit casts

### 2. Format Support

Chose two complementary formats:
- **@example in Teal comments**: Natural for API documentation
- **>>> in text files**: Familiar doctest format for tutorials

### 3. ID Generation

Format: `filename:line:kind`
- Unique across collection
- Human-readable
- Includes context (line number)

### 4. Validation Strategy

Two levels:
- **Structural**: Required fields, valid types
- **Content**: Presence of assertions (warning only)

### 5. JSON Intermediate Format

Benefits:
- Language-agnostic
- Easy to inspect/debug
- Cacheable between runs
- Runner can be implemented separately

## Testing

Created comprehensive test suite:
```bash
$ cosmic lib/build/doctest/test_example.tl
All tests passed!
```

Tests cover:
- Data structure creation
- Validation logic
- Assertion detection
- Collection management
- Code processing (dedentation)

## Integration with cosmic

Uses existing cosmic modules:
- `cosmo`: JSON encoding, file I/O (Barf/Slurp)
- `cosmic.walk`: Directory traversal
- `cosmo.path`: Path manipulation
- Build system: Automatic compilation via cook.mk

## Future Work

The system is ready for:

1. **Runner Implementation**: Execute extracted examples
2. **Coverage Reporting**: Track which functions have examples
3. **CI Integration**: Run doctests in CI/CD
4. **Make Targets**: Add `make doctest-extract`, `make doctest-run`
5. **Documentation**: Add examples to all cosmic modules

## Verification

All components compile and test successfully:

```bash
# Compilation
$ bin/make o/lib/build/doctest/example.lua o/lib/build/doctest/extractor.lua
✓ Both files compile without errors

# Testing
$ cosmic lib/build/doctest/test_example.tl
All tests passed!

# Real-world extraction
$ cosmic o/lib/build/doctest/extractor.lua lib/cosmic o/.doctest.extracted
Extracting examples from: lib/cosmic
Found 2 examples in 1 files
Saved examples to: o/.doctest.extracted
```

## Files Summary

| File | Lines | Purpose |
|------|-------|---------|
| `lib/build/doctest/example.tl` | 260 | Core data structures |
| `lib/build/doctest/extractor.tl` | 390 | Extraction engine |
| `lib/build/doctest/test_example.tl` | 75 | Test suite |
| `lib/build/doctest/README.md` | 350+ | Documentation |
| `lib/build/cook.mk` | Modified | Build integration |
| `lib/cosmic/spawn.tl` | Modified | Example usage |

Total new code: **~725 lines of Teal + documentation**

## Conclusion

Successfully implemented a complete, type-safe doctest extraction system for cosmic-lua that:
- ✅ Extracts examples from Teal source files (@example annotations)
- ✅ Extracts examples from text documentation (>>> format)
- ✅ Validates examples and warns about issues
- ✅ Saves examples as JSON for runner consumption
- ✅ Integrates with cosmic build system
- ✅ Follows Teal best practices with proper type annotations
- ✅ Includes comprehensive tests and documentation
- ✅ Works with existing cosmic modules (cosmo, cosmic.walk)

The system is production-ready for extracting examples, with a clear path forward for implementing the runner component.
