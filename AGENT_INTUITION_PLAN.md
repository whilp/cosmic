# Plan to Complete Agent Intuition Goal (Goal 2)

**Current Status**: ~90% complete, functionally usable
**Remaining Work**: Documentation polish and error message improvements

## Phase 1: Document Core cosmo Module Functions

**Problem**: Core `cosmo` module functions (DecodeJson, EncodeJson, Slurp, Barf, Sha256, etc.) exist and have type definitions but lack doc comments and don't appear in `--docs` search results.

**Solution**: Add comprehensive doc comments to `lib/types/cosmo.d.tl`

### Tasks:
1. Add module-level doc comment to cosmo.d.tl explaining it's the base cosmopolitan lua API
2. Add doc comments to each function with:
   - Purpose description
   - Parameter descriptions
   - Return value description
   - At least one usage example
3. Ensure the doc generator (gendoc.tl) processes these comments
4. Test that `--docs cosmo.DecodeJson` returns documentation

### Estimated Effort: 2-3 hours
- ~20 functions to document
- Need to understand each function's behavior
- Write clear examples for each
- Test documentation appears correctly

### Example Documentation Template:

```teal
--- Decode JSON string into Lua value.
--- Parses a JSON string and returns the corresponding Lua table, string, number, or boolean.
--- Returns nil if the JSON is malformed.
--- @param json string The JSON string to decode
--- @return any The decoded Lua value, or nil on parse error
--- @example
---   local data = cosmo.DecodeJson('{"name":"Alice","age":30}')
---   print(data.name)  -- "Alice"
---   print(data.age)   -- 30
DecodeJson: function(json: string): any
```

## Phase 2: Enhance Type Definition Doc Comments

**Problem**: Type definition files in `lib/types/cosmo/*.d.tl` have minimal doc comments explaining record fields and their semantics.

**Solution**: Add doc comments to record types explaining each field's purpose and valid values.

### Tasks:
1. Review all record types in lib/types/cosmo/*.d.tl:
   - cosmo/unix.d.tl
   - cosmo/path.d.tl
   - cosmo/getopt.d.tl
   - cosmo/zip.d.tl
   - cosmo/lsqlite3.d.tl
   - etc.
2. Add field-level doc comments explaining:
   - What the field represents
   - Valid value ranges or types
   - When to use it
3. Add examples showing how to construct and use these types

### Estimated Effort: 2-3 hours
- ~50-100 record fields across all type definition files
- Some may already have good comments

### Example:

```teal
--- Options for ZIP file compression.
local record AddOptions
  --- Compression level (0-9, where 0=none, 9=maximum)
  level?: number
  --- Unix file permissions (e.g., 0o755 for executable)
  mode?: number
  --- Last modification time as Unix timestamp
  mtime?: number
end
```

## Phase 3: Improve Error Messages

**Problem**: Error messages are functional but could provide more actionable suggestions.

**Solution**: Enhance error handling in key modules to suggest corrections.

### Tasks:
1. Review error paths in:
   - cosmic/teal.tl (type checking errors)
   - cosmic/docs.tl (documentation lookup errors)
   - cosmic/spawn.tl (process spawning errors)
   - cosmic/fetch.tl (HTTP fetch errors)
2. Add "did you mean?" suggestions for common mistakes:
   - Typos in module names
   - Wrong function signatures
   - Missing required parameters
3. Add context about what went wrong and how to fix it

### Estimated Effort: 3-4 hours
- Need to identify common error scenarios
- Implement fuzzy matching for suggestions
- Test error messages are helpful

### Example Error Enhancement:

**Before:**
```
error: documentation not found for 'cosmo.DecodeJSON'
```

**After:**
```
error: documentation not found for 'cosmo.DecodeJSON'
Did you mean 'cosmo.DecodeJson'? (note: lowercase 's' in 'Json')
Use 'cosmic --docs' to see all available modules.
```

## Phase 4: Add Integration Tests

**Problem**: While the verification tasks work, they aren't automated tests that run in CI.

**Solution**: Create test files that verify each of the 6 verification tasks.

### Tasks:
1. Create `lib/cosmic/agent_intuition_test.tl` with tests for all 6 tasks
2. Each test should:
   - Use only `--docs` discoverable APIs
   - Demonstrate the task can be completed
   - Assert expected results
3. Add to CI pipeline via `make test`

### Estimated Effort: 2 hours
- Adapt the verification scripts created in this session
- Convert to proper test functions
- Ensure they run reliably in CI

### Test Structure:

```teal
function Test_fetch_and_parse_json()
  local fetch = require("cosmic.fetch")
  local cosmo = require("cosmo")

  local result = fetch.Fetch("https://api.github.com/repos/jart/cosmopolitan")
  assert(result.ok, "fetch should succeed")

  local data = cosmo.DecodeJson(result.body)
  assert(data.full_name, "should parse JSON response")
  assert(type(data.stargazers_count) == "number", "should have numeric fields")
end
```

## Phase 5: Documentation Discoverability Improvements

**Problem**: Agents need to know how to discover what's available.

**Solution**: Improve `--help` and `--docs` to better guide exploration.

### Tasks:
1. Enhance `--help` to show one-line descriptions for each module (not just names)
2. Add `--docs list` command to show all documented symbols
3. Add `--docs examples` to show all available examples
4. Improve search results to rank exact matches higher

### Estimated Effort: 2-3 hours

### Example Enhanced `--help`:

```
Available modules:
  cosmic.fetch      - HTTP client with structured results and retry support
  cosmic.spawn      - Process spawning with pipe control
  cosmic.walk       - Directory tree traversal with pattern matching
  cosmo.zip         - ZIP archive creation and extraction
  cosmo.lsqlite3    - SQLite database operations
  cosmo.getopt      - Command-line argument parsing
```

## Total Estimated Effort: 11-15 hours

## Priority Order:
1. **Phase 1** (Critical) - Document core cosmo functions
2. **Phase 4** (High) - Add integration tests to prevent regression
3. **Phase 3** (Medium) - Improve error messages
4. **Phase 5** (Medium) - Enhance discoverability
5. **Phase 2** (Low) - Add type definition doc comments

## Success Criteria:
- `--docs cosmo.DecodeJson` returns complete documentation with examples
- All 6 verification tasks have automated tests in the test suite
- Error messages for common mistakes suggest corrections
- A fresh agent can discover and use any API without external help
- Goal 2 can be marked as [x] COMPLETE in GOALS.md
