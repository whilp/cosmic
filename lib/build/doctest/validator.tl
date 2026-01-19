--- validator: Documentation coverage validator for Teal source files
---
--- Analyzes Teal source files to check documentation coverage and validates
--- that all public functions have proper docstrings with @param, @return,
--- and @example tags.
---
---@module validator

local cosmo = require("cosmo")
local getopt = require("cosmo.getopt")

-- Types
local record FunctionInfo
  name: string
  line: number
  params: {string}
  has_docstring: boolean
  has_example: boolean
  documented_params: {string}
  has_return_doc: boolean
  is_public: boolean
end

local record ModuleInfo
  has_module_doc: boolean
  functions: {FunctionInfo}
  exported_functions: {string:boolean}
end

local record ValidationResult
  file_path: string
  total_public: number
  documented: number
  with_examples: number
  missing_docs: {FunctionInfo}
  missing_examples: {FunctionInfo}
  coverage_percent: number
  example_percent: number
  passed: boolean
end

-- Helper functions

--- Check if a line is a docstring comment (starts with ---)
---
---@param line string Line to check
---@return boolean True if line is a docstring comment
local function is_docstring(line: string): boolean
  return line:match("^%s*%-%-%-") ~= nil
end

--- Extract parameter names from function signature
---
---@param signature string Function signature
---@return {string} List of parameter names
local function extract_params(signature: string): {string}
  local params: {string} = {}
  local params_str = signature:match("%((.-)%)")
  if not params_str then
    return params
  end

  -- Split by comma to get individual parameters
  for param_decl in params_str:gmatch("[^,]+") do
    -- Extract parameter name (before : or ? if present)
    -- Handle patterns like: "name", "name?", "name: type", "name?: type"
    local param_name = param_decl:match("^%s*([%w_]+)")
    if param_name and param_name ~= "self" then
      table.insert(params, param_name)
    end
  end

  return params
end

--- Parse a Teal source file and extract documentation information
---
---@param file_path string Path to Teal file
---@return ModuleInfo|nil Module information
---@return string? Error message if parsing failed
local function parse_file(file_path: string): ModuleInfo, string
  local content = cosmo.Slurp(file_path)
  if not content then
    return nil, "failed to read file: " .. file_path
  end

  local module_info: ModuleInfo = {
    has_module_doc = false,
    functions = {},
    exported_functions = {},
  }

  local lines = {}
  for line in content:gmatch("[^\n]*") do
    table.insert(lines, line)
  end

  -- Check for module-level documentation (first non-empty, non-shebang lines)
  local found_code = false
  for i = 1, math.min(20, #lines) do
    local line = lines[i]
    if not line:match("^%s*$") and not line:match("^#!") then
      if is_docstring(line) then
        module_info.has_module_doc = true
        break
      elseif not line:match("^%s*%-%-[^%-]") then
        -- Found non-comment, non-docstring code
        found_code = true
        break
      end
    end
  end

  -- Track docstrings before functions
  local pending_docstring: {string} = {}
  local in_return_block = false
  local return_block_functions: {string:boolean} = {}

  for i, line in ipairs(lines) do
    -- Track docstring comments
    if is_docstring(line) then
      table.insert(pending_docstring, line)
    -- Check for return block start
    elseif line:match("^%s*local%s+[%w_]+%s*:%s*[%w_]+%s*=%s*{%s*$") or
           line:match("^%s*return%s*{%s*$") then
      in_return_block = true
    -- Check for exported functions in return block
    elseif in_return_block then
      if line:match("}") then
        in_return_block = false
      else
        local func_name = line:match("^%s*([%w_]+)%s*=")
        if func_name then
          return_block_functions[func_name] = true
          module_info.exported_functions[func_name] = true
        end
      end
    -- Check for function definitions
    elseif line:match("function") then
      local func_name, signature = line:match("local%s+function%s+([%w_]+)%s*(%b())")
      if not func_name then
        -- Try method definition pattern
        func_name, signature = line:match("function%s+[%w_]+:([%w_]+)%s*(%b())")
      end
      if not func_name then
        -- Try record method pattern
        func_name, signature = line:match("([%w_]+)%s*:%s*function%s*(%b())")
      end

      if func_name and signature then
        local func_info: FunctionInfo = {
          name = func_name,
          line = i,
          params = extract_params(signature),
          has_docstring = false,
          has_example = false,
          documented_params = {},
          has_return_doc = false,
          is_public = false,
        }

        -- Check if function has docstring
        if #pending_docstring > 0 then
          func_info.has_docstring = true

          -- Check for @example tag
          for _, doc_line in ipairs(pending_docstring) do
            if doc_line:match("@example") or doc_line:match("@usage") then
              func_info.has_example = true
            end

            -- Check for @param tags
            local param_name = doc_line:match("@param%s+([%w_?]+)")
            if param_name then
              -- Remove optional marker
              param_name = param_name:gsub("%?$", "")
              table.insert(func_info.documented_params, param_name)
            end

            -- Check for @return tag
            if doc_line:match("@return") then
              func_info.has_return_doc = true
            end
          end
        end

        table.insert(module_info.functions, func_info)
      end

      -- Clear pending docstring after processing function
      pending_docstring = {}
    -- Clear pending docstring if we hit non-docstring, non-empty line
    elseif not line:match("^%s*$") and not line:match("^%s*%-%-") then
      pending_docstring = {}
    end
  end

  -- Mark exported functions as public
  for _, func in ipairs(module_info.functions) do
    if module_info.exported_functions[func.name] then
      func.is_public = true
    end
  end

  -- If no explicit exports found, consider all documented functions as public
  local has_exports = false
  for _ in pairs(module_info.exported_functions) do
    has_exports = true
    break
  end

  if not has_exports then
    for _, func in ipairs(module_info.functions) do
      func.is_public = true
    end
  end

  return module_info
end

--- Validate module documentation coverage
---
---@param module_info ModuleInfo Module information from parsing
---@param file_path string Path to source file
---@param threshold number Coverage threshold (0-100)
---@return ValidationResult Validation results
local function validate_coverage(module_info: ModuleInfo, file_path: string, threshold: number): ValidationResult
  local result: ValidationResult = {
    file_path = file_path,
    total_public = 0,
    documented = 0,
    with_examples = 0,
    missing_docs = {},
    missing_examples = {},
    coverage_percent = 0,
    example_percent = 0,
    passed = false,
  }

  -- Count public functions and their documentation
  for _, func in ipairs(module_info.functions) do
    if func.is_public then
      result.total_public = result.total_public + 1

      -- Check if function is properly documented
      local is_fully_documented = func.has_docstring and func.has_return_doc

      -- Check if all parameters are documented
      if #func.params > 0 and is_fully_documented then
        local all_params_documented = true
        for _, param in ipairs(func.params) do
          local param_documented = false
          for _, doc_param in ipairs(func.documented_params) do
            if doc_param == param then
              param_documented = true
              break
            end
          end
          if not param_documented then
            all_params_documented = false
            break
          end
        end
        is_fully_documented = all_params_documented
      end

      if is_fully_documented then
        result.documented = result.documented + 1
      else
        table.insert(result.missing_docs, func)
      end

      if func.has_example then
        result.with_examples = result.with_examples + 1
      else
        table.insert(result.missing_examples, func)
      end
    end
  end

  -- Calculate coverage percentages
  if result.total_public > 0 then
    result.coverage_percent = (result.documented / result.total_public) * 100
    result.example_percent = (result.with_examples / result.total_public) * 100
  else
    result.coverage_percent = 100
    result.example_percent = 100
  end

  -- Check if validation passed
  result.passed = result.example_percent >= threshold

  return result
end

--- Format and print validation results
---
---@param result ValidationResult Validation results
---@param threshold number Coverage threshold used
local function print_results(result: ValidationResult, threshold: number)
  print(string.format("Documentation validation for %s:\n", result.file_path))
  print(string.format("Public functions: %d", result.total_public as integer))
  print(string.format("Documented: %d (%.0f%%)", result.documented as integer, result.coverage_percent))
  print(string.format("With examples: %d (%.0f%%)", result.with_examples as integer, result.example_percent))

  if #result.missing_docs > 0 then
    print("\nMissing documentation:")
    for _, func in ipairs(result.missing_docs) do
      print(string.format("  - %s() at line %d", func.name, func.line as integer))
    end
  end

  if #result.missing_examples > 0 then
    print("\nMissing examples:")
    for _, func in ipairs(result.missing_examples) do
      print(string.format("  - %s() at line %d", func.name, func.line as integer))
    end
  end

  print()
  if result.passed then
    print(string.format("Coverage: %.0f%% (meets threshold of %.0f%%)", result.example_percent, threshold as integer))
  else
    print(string.format("Coverage: %.0f%% (below threshold of %.0f%%)", result.example_percent, threshold as integer))
  end
end

--- Main entry point
---
---@param args {string} Command-line arguments
---@return integer Exit code (0 for success, 1 for failure)
local function main(args: {string}): integer
  -- Parse command-line arguments
  local threshold: number = 90
  local file_path: string

  local longopts = {{"threshold", "required"}}
  local parser = getopt.new(args, "", longopts)

  while true do
    local opt, optarg = parser:next()
    if not opt then break end
    if opt == "threshold" then
      threshold = tonumber(optarg) or 90
    elseif opt == "?" then
      io.stderr:write("Usage: validator.lua <source.tl> [--threshold 90]\n")
      return 1
    end
  end

  local remaining = parser:remaining()
  if not remaining or #remaining < 1 then
    io.stderr:write("Usage: validator.lua <source.tl> [--threshold 90]\n")
    return 1
  end

  file_path = remaining[1]

  -- Parse the file
  local module_info, err = parse_file(file_path)
  if not module_info then
    io.stderr:write(string.format("Error: %s\n", err or "unknown error"))
    return 1
  end

  -- Validate coverage
  local result = validate_coverage(module_info, file_path, threshold)

  -- Print results
  print_results(result, threshold)

  -- Return appropriate exit code
  if result.passed then
    return 0
  else
    return 1
  end
end

-- Run if executed directly
if arg then
  os.exit(main(arg) as boolean)
end

return {
  parse_file = parse_file,
  validate_coverage = validate_coverage,
  print_results = print_results,
  main = main,
}
