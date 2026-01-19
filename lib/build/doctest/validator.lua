local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local io = _tl_compat and _tl_compat.io or io; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local math = _tl_compat and _tl_compat.math or math; local os = _tl_compat and _tl_compat.os or os; local pairs = _tl_compat and _tl_compat.pairs or pairs; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table







local cosmo = require("cosmo")
local getopt = require("cosmo.getopt")





































local function is_docstring(line)
   return line:match("^%s*%-%-%-") ~= nil
end





local function extract_params(signature)
   local params = {}
   local params_str = signature:match("%((.-)%)")
   if not params_str then
      return params
   end


   for param_decl in params_str:gmatch("[^,]+") do


      local param_name = param_decl:match("^%s*([%w_]+)")
      if param_name and param_name ~= "self" then
         table.insert(params, param_name)
      end
   end

   return params
end






local function parse_file(file_path)
   local content = cosmo.Slurp(file_path)
   if not content then
      return nil, "failed to read file: " .. file_path
   end

   local module_info = {
      has_module_doc = false,
      functions = {},
      exported_functions = {},
   }

   local lines = {}
   for line in content:gmatch("[^\n]*") do
      table.insert(lines, line)
   end


   local found_code = false
   for i = 1, math.min(20, #lines) do
      local line = lines[i]
      if not line:match("^%s*$") and not line:match("^#!") then
         if is_docstring(line) then
            module_info.has_module_doc = true
            break
         elseif not line:match("^%s*%-%-[^%-]") then

            found_code = true
            break
         end
      end
   end


   local pending_docstring = {}
   local in_return_block = false
   local return_block_functions = {}

   for i, line in ipairs(lines) do

      if is_docstring(line) then
         table.insert(pending_docstring, line)

      elseif line:match("^%s*local%s+[%w_]+%s*:%s*[%w_]+%s*=%s*{%s*$") or
         line:match("^%s*return%s*{%s*$") then
         in_return_block = true

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

      elseif line:match("function") then
         local func_name, signature = line:match("local%s+function%s+([%w_]+)%s*(%b())")
         if not func_name then

            func_name, signature = line:match("function%s+[%w_]+:([%w_]+)%s*(%b())")
         end
         if not func_name then

            func_name, signature = line:match("([%w_]+)%s*:%s*function%s*(%b())")
         end

         if func_name and signature then
            local func_info = {
               name = func_name,
               line = i,
               params = extract_params(signature),
               has_docstring = false,
               has_example = false,
               documented_params = {},
               has_return_doc = false,
               is_public = false,
            }


            if #pending_docstring > 0 then
               func_info.has_docstring = true


               for _, doc_line in ipairs(pending_docstring) do
                  if doc_line:match("@example") or doc_line:match("@usage") then
                     func_info.has_example = true
                  end


                  local param_name = doc_line:match("@param%s+([%w_?]+)")
                  if param_name then

                     param_name = param_name:gsub("%?$", "")
                     table.insert(func_info.documented_params, param_name)
                  end


                  if doc_line:match("@return") then
                     func_info.has_return_doc = true
                  end
               end
            end

            table.insert(module_info.functions, func_info)
         end


         pending_docstring = {}

      elseif not line:match("^%s*$") and not line:match("^%s*%-%-") then
         pending_docstring = {}
      end
   end


   for _, func in ipairs(module_info.functions) do
      if module_info.exported_functions[func.name] then
         func.is_public = true
      end
   end


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







local function validate_coverage(module_info, file_path, threshold)
   local result = {
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


   for _, func in ipairs(module_info.functions) do
      if func.is_public then
         result.total_public = result.total_public + 1


         local is_fully_documented = func.has_docstring and func.has_return_doc


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


   if result.total_public > 0 then
      result.coverage_percent = (result.documented / result.total_public) * 100
      result.example_percent = (result.with_examples / result.total_public) * 100
   else
      result.coverage_percent = 100
      result.example_percent = 100
   end


   result.passed = result.example_percent >= threshold

   return result
end





local function print_results(result, threshold)
   print(string.format("Documentation validation for %s:\n", result.file_path))
   print(string.format("Public functions: %d", result.total_public))
   print(string.format("Documented: %d (%.0f%%)", result.documented, result.coverage_percent))
   print(string.format("With examples: %d (%.0f%%)", result.with_examples, result.example_percent))

   if #result.missing_docs > 0 then
      print("\nMissing documentation:")
      for _, func in ipairs(result.missing_docs) do
         print(string.format("  - %s() at line %d", func.name, func.line))
      end
   end

   if #result.missing_examples > 0 then
      print("\nMissing examples:")
      for _, func in ipairs(result.missing_examples) do
         print(string.format("  - %s() at line %d", func.name, func.line))
      end
   end

   print()
   if result.passed then
      print(string.format("Coverage: %.0f%% (meets threshold of %.0f%%)", result.example_percent, threshold))
   else
      print(string.format("Coverage: %.0f%% (below threshold of %.0f%%)", result.example_percent, threshold))
   end
end





local function main(args)

   local threshold = 90
   local file_path

   local longopts = { { "threshold", "required" } }
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


   local module_info, err = parse_file(file_path)
   if not module_info then
      io.stderr:write(string.format("Error: %s\n", err or "unknown error"))
      return 1
   end


   local result = validate_coverage(module_info, file_path, threshold)


   print_results(result, threshold)


   if result.passed then
      return 0
   else
      return 1
   end
end


if arg then
   os.exit(main(arg))
end

return {
   parse_file = parse_file,
   validate_coverage = validate_coverage,
   print_results = print_results,
   main = main,
}