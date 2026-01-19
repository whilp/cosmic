-- cosmic.teal: Teal compilation and type-checking for cosmic-lua
-- Provides --compile and --check functionality

local tl = require("tl")

local record Issue
  file: string
  line: integer
  column: integer
  message: string
  severity: string  -- "error" or "warning"
end

local record CompileOpts
  include_dirs: {string}
  gen_target: string
  gen_compat: string
end

local record CheckOpts
  include_dirs: {string}
end

local record CompileResult
  ok: boolean
  code: string
  errors: {Issue}
end

local record CheckResult
  ok: boolean
  warnings: {Issue}
  errors: {Issue}
end

-- Default include directories for cosmic type definitions
local function get_default_include_dirs(): {string}
  return {
    "/zip/.lua/types",       -- Bundled cosmic types (in binary)
    "/zip/.lua/teal-types",  -- Bundled third-party types (in binary)
    "lib/types",             -- Local cosmic types (development)
  }
end

-- Compile a Teal file to Lua code
-- Returns: CompileResult with ok, code (if successful), errors (if failed)
local function compile(input_path: string, opts: CompileOpts): CompileResult
  opts = opts or {} as CompileOpts

  -- Read input file
  local f, open_err = io.open(input_path, "r")
  if not f then
    return {
      ok = false,
      code = nil,
      errors = {{
        file = input_path,
        line = 0,
        column = 0,
        message = "cannot open file: " .. (open_err or "unknown error"),
        severity = "error",
      }},
    }
  end
  local input = f:read("*a")
  f:close()

  -- Extract shebang if present (to preserve it in output)
  local shebang: string = nil
  if input:sub(1, 2) == "#!" then
    local newline_pos = input:find("\n")
    if newline_pos then
      shebang = input:sub(1, newline_pos)
    end
  end

  -- Set up include directories for type definitions
  local include_dirs = opts.include_dirs or get_default_include_dirs()

  -- Add include dirs to package.path for teal's module resolution
  local saved_path = package.path
  for _, dir in ipairs(include_dirs) do
    package.path = package.path .. ";" .. dir .. "/?.d.tl"
    package.path = package.path .. ";" .. dir .. "/?/init.d.tl"
  end

  -- Initialize teal environment
  local env = tl.init_env(false)

  -- Process the file (lex, parse, type check)
  local result, proc_err = tl.process_string(input, false, env, input_path)

  -- Restore package.path
  package.path = saved_path

  if not result then
    return {
      ok = false,
      code = nil,
      errors = {{
        file = input_path,
        line = 0,
        column = 0,
        message = proc_err or "processing failed",
        severity = "error",
      }},
    }
  end

  -- Collect all errors (syntax + type)
  local errors: {Issue} = {}

  if result.syntax_errors then
    for _, e in ipairs(result.syntax_errors) do
      if e.msg then
        table.insert(errors, {
          file = e.filename or input_path,
          line = e.y or 0,
          column = e.x or 0,
          message = e.msg,
          severity = "error",
        })
      end
    end
  end

  if result.type_errors then
    for _, e in ipairs(result.type_errors) do
      if e.msg then
        table.insert(errors, {
          file = e.filename or input_path,
          line = e.y or 0,
          column = e.x or 0,
          message = e.msg,
          severity = "error",
        })
      end
    end
  end

  if #errors > 0 then
    return {
      ok = false,
      code = nil,
      errors = errors,
    }
  end

  -- Generate Lua code from the validated AST
  local gen_opts: {string:any} = {
    gen_target = opts.gen_target or "5.4",
    gen_compat = opts.gen_compat or "off",
  }
  local lua_code = tl.generate(result.ast, gen_opts)

  -- Prepend shebang if source had one
  if shebang then
    lua_code = shebang .. lua_code
  end

  return {
    ok = true,
    code = lua_code,
    errors = {},
  }
end

-- Type-check a Teal file
-- Returns: CheckResult with ok, warnings, errors
local function check(input_path: string, opts: CheckOpts): CheckResult
  opts = opts or {} as CheckOpts

  -- Read input file
  local f, open_err = io.open(input_path, "r")
  if not f then
    return {
      ok = false,
      warnings = {},
      errors = {{
        file = input_path,
        line = 0,
        column = 0,
        message = "cannot open file: " .. (open_err or "unknown error"),
        severity = "error",
      }},
    }
  end
  local input = f:read("*a")
  f:close()

  -- Set up include directories for type definitions
  local include_dirs = opts.include_dirs or get_default_include_dirs()

  -- Add include dirs to package.path for teal's module resolution
  local saved_path = package.path
  for _, dir in ipairs(include_dirs) do
    package.path = package.path .. ";" .. dir .. "/?.d.tl"
    package.path = package.path .. ";" .. dir .. "/?/init.d.tl"
  end

  -- Initialize teal environment
  local env = tl.init_env(false)

  -- Process the file (lex, parse, type check)
  local result, proc_err = tl.process_string(input, false, env, input_path)

  -- Restore package.path
  package.path = saved_path

  if not result then
    return {
      ok = false,
      warnings = {},
      errors = {{
        file = input_path,
        line = 0,
        column = 0,
        message = proc_err or "processing failed",
        severity = "error",
      }},
    }
  end

  -- Collect warnings and errors
  local warnings: {Issue} = {}
  local errors: {Issue} = {}

  if result.warnings then
    for _, w in ipairs(result.warnings) do
      if w.msg then
        table.insert(warnings, {
          file = w.filename or input_path,
          line = w.y or 0,
          column = w.x or 0,
          message = w.msg,
          severity = "warning",
        })
      end
    end
  end

  if result.type_errors then
    for _, e in ipairs(result.type_errors) do
      if e.msg then
        table.insert(errors, {
          file = e.filename or input_path,
          line = e.y or 0,
          column = e.x or 0,
          message = e.msg,
          severity = "error",
        })
      end
    end
  end

  if result.syntax_errors then
    for _, e in ipairs(result.syntax_errors) do
      if e.msg then
        table.insert(errors, {
          file = e.filename or input_path,
          line = e.y or 0,
          column = e.x or 0,
          message = e.msg,
          severity = "error",
        })
      end
    end
  end

  return {
    ok = #errors == 0,
    warnings = warnings,
    errors = errors,
  }
end

-- Format issues for human-readable output
local function format_issues(issues: {Issue}): string
  local lines: {string} = {}
  for _, issue in ipairs(issues) do
    table.insert(lines, string.format("%s:%d:%d: %s: %s",
      issue.file,
      issue.line,
      issue.column,
      issue.severity,
      issue.message))
  end
  return table.concat(lines, "\n")
end

local record TealModule
  compile: function(input_path: string, opts?: CompileOpts): CompileResult
  check: function(input_path: string, opts?: CheckOpts): CheckResult
  format_issues: function(issues: {Issue}): string
  get_default_include_dirs: function(): {string}
end

local M: TealModule = {
  compile = compile,
  check = check,
  format_issues = format_issues,
  get_default_include_dirs = get_default_include_dirs,
}

return M
