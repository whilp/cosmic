--- The `--min`/`--min-file` percentages `--make coverage` was invoked
--- with, carried from the argv scan in `_make/init.tl` to
--- `_make/policy.tl`'s `run_coverage` as a module-level setting rather
--- than as a new parameter on that call.
---
--- Why a setting and not a parameter: generation 1 of a cold build runs
--- the tree's `_make` modules under the pinned release's own type
--- snapshot (AGENTS.md, "the cold-build rule"), so widening the arity
--- of a call between two modules the release already ships fails the
--- `build` lane until a release carries the new signature -- the same
--- reason `_cli/lint_limit.tl` exists for `--max-lines`. A new module,
--- which the snapshot has never seen, is checked from the tree alone.
--- `nil` means "not given": `_tool.coverage.minimum.gate` already
--- treats a `nil` floor as "do not check this one".

local record CoverageLimit
  --- Record the floors the command line named; nil clears either.
  set: function(min?: number, min_file?: number)
  --- The floors on record.
  --- @return number|nil The overall floor
  --- @return number|nil The per-file floor
  get: function(): number | nil, number | nil
end

local min: number = nil
local min_file: number = nil

local function set(new_min?: number, new_min_file?: number)
  min = new_min
  min_file = new_min_file
end

local function get(): number | nil, number | nil
  return min, min_file
end

local M: CoverageLimit = {
  set = set,
  get = get,
}

return M
