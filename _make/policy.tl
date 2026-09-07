--- The policy verbs: `coverage` and `ci`.
---
--- Orchestration over the graph, never graph rules. `coverage` runs the
--- test lane with collection on and then gates the result against
--- `--min`/`--min-file`, when either was given; `ci` is a fixed order
--- of other verbs.
---
--- Both are gated by MATERIAL rather than by configuration: a project
--- with no tests has no coverage stage, and that is not an error. Zero
--- configuration, and a fresh project does not fail on a stage that had
--- nothing to do.

local coverage_limit = require("_make.coverage_limit")
local fs = require("cosmic.fs")
local minimum = require("_tool.coverage.minimum")
local project = require("_make.project")
local selection = require("_make.select")
local stage = require("_make.stage")
local types = require("_make.types")
local vcs = require("_make.vcs")

local type Kind = types.Kind
local type Project = types.Project
local type Verb = types.Verb

--- Where a coverage run's data lands.
local COVERAGE_DIR < const > = ".coverage"

--- Whether a project has any file of the given kinds — the "material"
--- test every stage of `ci` is gated by.
--- @param proj Project The scanned project
--- @param kinds {Kind} The kinds that count as material
--- @return boolean True when at least one file matches
local function has(proj: Project, kinds: {Kind}): boolean
  return #project.of_kind(proj, kinds) > 0
end

--- `coverage` — the test lane again, with collection, then
--- `--min`/`--min-file` when either was given (`_make.coverage_limit`,
--- set from the argv scan in `_make/init.tl`).
---
--- The gate is in process rather than a recipe line because it is a
--- POLICY: it reads the report inputs, computes, and decides. A recipe
--- would have to name the report directory and the source directories
--- in the constant rules, which is project facts in a file that is
--- supposed to have none.
--- @param v Verb The coverage verb
--- @param proj Project The scanned project
--- @param paths {string} Selection paths naming tests
--- @param cosmic string Absolute path to this binary
--- @return integer Exit code
local function run_coverage(v: Verb, proj: Project, paths: {string},
    cosmic: string): integer
  local ok, detail = stage.graph_stage(v, proj, paths, cosmic)
  if not ok then
    return stage.verdict(v.name, false, detail)
  end
  local min, min_file = coverage_limit.get()
  -- A narrowed run is partial data, and partial data reads as a huge
  -- decline against a whole-project floor: skip the check rather than
  -- fail it, so selecting a few tests cannot report a regression it did
  -- not measure. With neither option there is nothing to skip --
  -- `minimum.gate` just reports, on any selection.
  if (min or min_file) and #paths > 0 then
    io.write("coverage: --min/--min-file skipped (narrowed selection; " ..
      "partial data would read as a decline)\n")
    return stage.verdict(v.name, true, detail)
  end
  local report: {string} = {fs.join(project.BUILD_DIR, COVERAGE_DIR)}
  for _, dir in ipairs(project.source_dirs(proj)) do
    report[#report + 1] = dir
  end
  local code = minimum.gate(report, min, min_file)
  return stage.verdict(v.name, code == 0, detail)
end

--- `fmt --fix` — rewrite every selected source that is not already
--- formatted, in process.
---
--- Not through the graph: a `.fmt.got` records a VERDICT about a file,
--- and rewriting the file makes that verdict about something that no
--- longer exists. The formatter is in this binary, the file set is the
--- model's, and the answer is the same one `--fix` gives for one file.
--- @param proj Project The scanned project
--- @param paths {string} Selection paths
--- @return integer Exit code
local function fix(proj: Project, paths: {string}): integer
  local picked, serr = selection.files(
    stage.candidates(proj, stage.SELECTS.fmt), paths, proj.root)
  if not picked then
    io.stderr:write((serr or "make: nothing to do under") .. "\n")
    return stage.verdict("fmt", false, "selection")
  end
  local fmt = require("cosmic.format")
  local fixed = 0
  for _, f in ipairs(picked) do
    local result = fmt.format_file(f.path)
    if not result.ok then
      io.stderr:write(fmt.format_issues(result.errors) .. "\n")
      return stage.verdict("fmt", false, f.path)
    end
    local code = result.code
    if code == nil then
      -- ok without code would be a formatter bug; refuse rather than cast.
      io.stderr:write("fmt: no output for " .. f.path .. "\n")
      return stage.verdict("fmt", false, f.path)
    end
    if fs.read(f.path) ~= code then
      local ok, werr = fs.write(f.path, code)
      if not ok then
        io.stderr:write((werr or "cannot write " .. f.path) .. "\n")
        return stage.verdict("fmt", false, f.path)
      end
      io.write("fmt: rewrote " .. f.path .. "\n")
      fixed = fixed + 1
    end
  end
  return stage.verdict("fmt", true, fixed .. " rewritten")
end

--- One stage of `ci`: a verb name, and the material that earns it.
local record Stage
  verb: string
  --- Kinds a project must have at least one of. Empty means always.
  needs: {Kind}
end

--- The gate, in order.
---
--- A list of verb NAMES, which is the point of the registry being data:
--- `ci` reimplements nothing, so a stage cannot drift from the verb it
--- claims to run. There is no separate model stage: validating the
--- project is what `check` opens with, so `ci` gets it by listing
--- `check`.
---
--- No separate `test` stage: `coverage` runs the identical test recipe
--- with collection on, and its ratchet summary passes or fails exactly
--- the way a plain test run would, so a failing test still fails `ci`
--- through `coverage`. Running the suite twice — once plain, once
--- instrumented — bought `ci` nothing but wall-clock: measured, 157s
--- summed for the plain lane against 351s for the instrumented one,
--- pure duplication inside the gate. `--make test` standalone is
--- untouched — it is still the fast, uninstrumented developer loop —
--- this only drops the plain lane's second run inside `ci`.
local STAGES < const >: {Stage} = {
  {verb = "fmt", needs = {}},
  {verb = "check", needs = {}},
  {verb = "example", needs = {"example"}},
  {verb = "lint", needs = {}},
  {verb = "coverage", needs = {"test"}},
}

--- Look up a verb the registry is known to define.
---
--- The registry (`_make/init.tl`) is literal data: every name a caller
--- passes here names a row it defines, so a lookup miss is an
--- impossible state, not a runtime failure worth a nilable return.
--- @param by_name function Registry lookup, passed in to avoid a cycle
--- @param name string The verb name, a row the registry defines
--- @return Verb
local function must_verb(by_name: function(string): Verb | nil,
    name: string): Verb
  local v = by_name(name)
  assert(v, "make: no verb " .. name) -- assert: the registry is literal data in _make/init.tl and every name passed here is a row it defines
  return v
end

--- `ci` — every stage, in order, each gated by material.
---
--- Runs to the END rather than stopping at the first failure: a gate
--- that reports one problem per run costs a round trip per problem, and
--- the stages are independent by construction.
--- @param by_name function Registry lookup, passed in to avoid a cycle
--- @param proj Project The scanned project
--- @param _paths {string} Unused: `_make.law` refuses a selection here
--- @param cosmic string Absolute path to this binary
--- @return integer Exit code
local function run_ci(by_name: function(string): Verb | nil, proj: Project,
    _paths: {string}, cosmic: string): integer
  local failed: {string} = {}
  local ran = 0
  for _, s in ipairs(STAGES) do
    local v = by_name(s.verb)
    if not (v is Verb) then
      io.stderr:write("make: ci names a verb that does not exist: " ..
        s.verb .. "\n")
      return stage.verdict("ci", false, s.verb)
    end
    if #s.needs > 0 and not has(proj, s.needs) then
      io.write("ci: " .. s.verb .. " skipped (nothing to do)\n")
    else
      ran = ran + 1
      local code = v.run and v.run(proj, {}, cosmic)
      or stage.run_graph(v, proj, {}, cosmic)
      if code ~= 0 then
        failed[#failed + 1] = s.verb
      end
    end
  end
  -- Second-to-last line, the same slot the coverage ratchet's `declined:`
  -- line uses (_tool/coverage/baseline.tl): it must survive a truncated
  -- view, on both the pass and the fail path.
  local base_sha = vcs.diverged()
  if base_sha then
    io.write(vcs.notice(vcs.BASE_REF, base_sha) .. "\n")
  end
  if #failed > 0 then
    return stage.verdict("ci", false, table.concat(failed, " "))
  end
  return stage.verdict("ci", true, ran .. " stages")
end

local record PolicyModule
  COVERAGE_DIR: string
  STAGES: {Stage}
  has: function(proj: Project, kinds: {Kind}): boolean
  run_coverage: function(v: Verb, proj: Project, paths: {string}, cosmic: string): integer
  fix: function(proj: Project, paths: {string}): integer
  run_ci: function(by_name: function(string): Verb | nil, proj: Project, _paths: {string}, cosmic: string): integer
  must_verb: function(by_name: function(string): Verb | nil, name: string): Verb
end

local M: PolicyModule = {
  COVERAGE_DIR = COVERAGE_DIR,
  STAGES = STAGES,
  has = has,
  run_coverage = run_coverage,
  fix = fix,
  run_ci = run_ci,
  must_verb = must_verb,
}

return M
