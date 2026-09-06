--- The file-length cap `--max-lines` names, carried from the dispatcher
--- to `_cli.lint` as a module-level setting rather than as a new
--- parameter on `check.run` -> `handle_check_style` -> `lint_file`.
---
--- Why a setting and not a parameter: generation 1 of a cold build runs
--- the tree's `_cli` modules under the pinned release's own type
--- snapshot (AGENTS.md, "the cold-build rule"), so widening the arity
--- of a call between two modules the release already ships fails the
--- `build` lane until a release carries the new signature -- a new
--- module, which the snapshot has never seen, is checked from the tree
--- alone. `nil` means "the default": `_tool.lint.DEFAULT_FILE_LINES`
--- stays the one place that holds the 500.

local record LintLimit
  --- Record the cap the command line named; nil clears it.
  set: function(n?: integer)
  --- The cap on record, or nil for the default.
  get: function(): integer | nil
end

local max_lines: integer = nil

local function set(n?: integer)
  max_lines = n
end

local function get(): integer | nil
  return max_lines
end

local M: LintLimit = {
  set = set,
  get = get,
}

return M
