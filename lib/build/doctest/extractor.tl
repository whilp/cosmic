#!/usr/bin/env cosmic
-- doctest.extractor: Extract documentation examples from source files
--
-- This module extracts executable examples from:
-- 1. Teal source files (from --- comments with @example tags)
-- 2. Text documentation files (from >>> example blocks)
--
-- Examples are validated and saved as JSON for the test runner.

local cosmo = require("cosmo")
local path = require("cosmo.path")
local walk = require("cosmic.walk")
local example_module = require("build.doctest.example")

local type Example = example_module.Example
local type ExampleCollection = example_module.ExampleCollection

local record ExtractionResult
   collection: ExampleCollection
   errors: {string}
   warnings: {string}
end

--- Extracts examples from a Teal source file.
---
--- Looks for --- comments with @example, @example:setup, or @example:teardown tags.
--- The code following the tag is extracted until a blank line or end of comment block.
---
---@param file_path string Path to the Teal file
---@return {example_module.Example}, {string} Examples and errors
local function extract_from_teal(file_path: string): {example_module.Example}, {string}
   local content = cosmo.Slurp(file_path)
   if not content then
      return {}, {"Failed to read file: " .. file_path}
   end

   local examples: {example_module.Example} = {}
   local errors: {string} = {}
   local lines = {}
   for line in content:gmatch("([^\n]*)\n?") do
      table.insert(lines, line)
   end

   local i = 1
   while i <= #lines do
      local line = lines[i]

      -- Look for @example tags in --- comments
      local tag = line:match("^%-%-%-.*@example:?(%w*)")
      if tag ~= nil then
         local kind = "example"
         if tag == "setup" then
            kind = "setup"
         elseif tag == "teardown" then
            kind = "teardown"
         end

         local start_line = i
         local code_lines: {string} = {}

         -- Extract code from subsequent --- comment lines
         i = i + 1
         local in_code = false
         while i <= #lines do
            local code_line = lines[i]

            -- Check if still in comment block
            local comment_content = code_line:match("^%-%-%-(.*)$")
            if not comment_content then
               break
            end

            -- Skip the @example tag line itself and description lines
            -- Code starts after seeing actual code or after blank comment lines
            if comment_content:match("^%s*$") then
               if in_code then
                  -- Blank line ends the code block
                  break
               end
               -- Skip leading blank lines before code
            elseif not comment_content:match("^%s*@") then
               in_code = true
               -- Remove leading spaces from comment content
               local trimmed = comment_content:match("^%s*(.*)$")
               table.insert(code_lines, trimmed)
            end

            i = i + 1
         end

         if #code_lines > 0 then
            local code = example_module.dedent(table.concat(code_lines, "\n"))

            local ex = example_module.new_example({
               source_file = file_path,
               source_line = start_line,
               kind = kind,
               code = code,
               expected_output = "",
               tags = {},
            })

            local valid, err = example_module.validate_example(ex)
            if valid then
               table.insert(examples, ex)

               -- Warn if no assertions found
               if not example_module.has_assertions(ex) then
                  table.insert(errors, string.format(
                     "%s:%d: Warning: Example has no assertions",
                     file_path, start_line
                  ))
               end
            else
               table.insert(errors, string.format(
                  "%s:%d: Invalid example: %s",
                  file_path, start_line, err
               ))
            end
         end
      else
         i = i + 1
      end
   end

   return examples, errors
end

--- Extracts examples from a text documentation file.
---
--- Looks for Python-style doctest format with >>> prompts.
--- Example:
---   >>> x = 1 + 1
---   >>> print(x)
---   2
---
---@param file_path string Path to the text file
---@return {example_module.Example}, {string} Examples and errors
local function extract_from_text(file_path: string): {example_module.Example}, {string}
   local content = cosmo.Slurp(file_path)
   if not content then
      return {}, {"Failed to read file: " .. file_path}
   end

   local examples: {example_module.Example} = {}
   local errors: {string} = {}
   local lines = {}
   for line in content:gmatch("([^\n]*)\n?") do
      table.insert(lines, line)
   end

   local i = 1
   while i <= #lines do
      local line = lines[i]

      -- Look for >>> prompt
      if line:match("^>>>%s") then
         local start_line = i
         local code_lines: {string} = {}
         local output_lines: {string} = {}
         local in_output = false

         -- Extract code and expected output
         while i <= #lines do
            local current_line = lines[i]

            if current_line:match("^>>>%s") then
               -- New code line
               in_output = false
               local code = current_line:match("^>>>%s(.*)$")
               table.insert(code_lines, code)
            elseif current_line:match("^%.%.%.%s") then
               -- Continuation line
               in_output = false
               local code = current_line:match("^%.%.%.%s(.*)$")
               table.insert(code_lines, code)
            elseif current_line:match("^%s*$") then
               -- Blank line ends the example
               break
            else
               -- Expected output line
               in_output = true
               table.insert(output_lines, current_line)
            end

            i = i + 1
         end

         if #code_lines > 0 then
            local code = table.concat(code_lines, "\n")
            local expected_output = table.concat(output_lines, "\n")

            local ex = example_module.new_example({
               source_file = file_path,
               source_line = start_line,
               kind = "example",
               code = code,
               expected_output = expected_output,
               tags = {},
            })

            local valid, err = example_module.validate_example(ex)
            if valid then
               table.insert(examples, ex)
            else
               table.insert(errors, string.format(
                  "%s:%d: Invalid example: %s",
                  file_path, start_line, err
               ))
            end
         end
      else
         i = i + 1
      end
   end

   return examples, errors
end

--- Extracts examples from a single file based on its extension.
---
---@param file_path string Path to the file
---@return {example_module.Example}, {string} Examples and errors
local function extract_from_file(file_path: string): {example_module.Example}, {string}
   if file_path:match("%.tl$") then
      return extract_from_teal(file_path)
   elseif file_path:match("%.txt$") then
      return extract_from_text(file_path)
   else
      return {}, {}
   end
end

--- Extracts examples from all files in a directory tree.
---
---@param root_dir string Root directory to search
---@param pattern string? Optional filename pattern (default: all .tl and .txt files)
---@return ExtractionResult Results of extraction
local function extract_from_directory(root_dir: string, pattern: string): ExtractionResult
   local collection = example_module.new_collection()
   local errors: {string} = {}
   local warnings: {string} = {}

   -- Default pattern matches .tl and .txt files
   pattern = pattern or "%.t?l%.?t?x?t?$"

   -- Walk the directory tree
   walk.walk(root_dir, function(full_path: string, entry: string, stat: any): boolean
      -- Skip hidden files and directories
      if entry:match("^%.") then
         return false
      end

      -- Process matching files
      if entry:match("%.tl$") or entry:match("%.txt$") then
         local file_examples, file_errors = extract_from_file(full_path)

         for _, ex in ipairs(file_examples) do
            example_module.add_example(collection, ex)
         end

         for _, err in ipairs(file_errors) do
            table.insert(errors, err)
         end
      end

      return true
   end)

   return {
      collection = collection,
      errors = errors,
      warnings = warnings,
   }
end

--- Saves an example collection as JSON to a file.
---
---@param collection example_module.ExampleCollection The collection to save
---@param output_path string Path to write JSON file
---@return boolean, string? Success status and optional error message
local function save_collection_json(collection: example_module.ExampleCollection, output_path: string): boolean, string
   -- Convert collection to a JSON-serializable format
   local data = {
      examples = {},
      total_count = collection.total_count,
      file_count = collection.file_count,
   }

   for id, ex in pairs(collection.examples) do
      data.examples[id] = {
         id = ex.id,
         source_file = ex.source_file,
         source_line = ex.source_line,
         kind = ex.kind,
         code = ex.code,
         expected_output = ex.expected_output,
         requires_setup = ex.requires_setup,
         requires_teardown = ex.requires_teardown,
         tags = ex.tags,
      }
   end

   local json = cosmo.EncodeJson(data)
   local ok = cosmo.Barf(output_path, json)

   if not ok then
      return false, "Failed to write output file: " .. output_path
   end

   return true
end

--- Loads an example collection from a JSON file.
---
---@param input_path string Path to JSON file
---@return example_module.ExampleCollection?, string? Collection or nil and error message
local function load_collection_json(input_path: string): example_module.ExampleCollection, string
   local content = cosmo.Slurp(input_path)
   if not content then
      return nil, "Failed to read input file: " .. input_path
   end

   local ok, data_any = pcall(cosmo.DecodeJson, content)
   if not ok then
      return nil, "Failed to parse JSON: " .. tostring(data_any)
   end

   local data = data_any as {string:any}
   local collection = example_module.new_collection()

   local examples_table = data.examples as {string:{string:any}}
   for id, ex_data_any in pairs(examples_table) do
      local ex_data = ex_data_any as {string:any}
      local ex = example_module.new_example({
         source_file = ex_data.source_file as string,
         source_line = ex_data.source_line as integer,
         kind = ex_data.kind as string,
         code = ex_data.code as string,
         expected_output = (ex_data.expected_output as string) or "",
         tags = (ex_data.tags as {string}) or {},
      })

      ex.requires_setup = (ex_data.requires_setup as boolean) or false
      ex.requires_teardown = (ex_data.requires_teardown as boolean) or false

      example_module.add_example(collection, ex)
   end

   return collection
end

--- Main entry point for the extractor.
---
--- Usage: cosmic lib/build/doctest/extractor.tl [file_or_directory] [output_file]
---
local function main(args: {string})
   local input = args[1] or "lib"
   local output_file = args[2] or ".doctest.extracted"

   print("Extracting examples from: " .. input)

   local result: ExtractionResult
   local collection = example_module.new_collection()
   local errors: {string} = {}

   -- Check if input is a file or directory
   local is_file = input:match("%.tl$") or input:match("%.txt$")

   if is_file then
      -- Extract from single file
      local file_examples, file_errors = extract_from_file(input)
      for _, ex in ipairs(file_examples) do
         example_module.add_example(collection, ex)
      end
      for _, err in ipairs(file_errors) do
         table.insert(errors, err)
      end
      result = {
         collection = collection,
         errors = errors,
         warnings = {},
      }
   else
      -- Extract from directory
      result = extract_from_directory(input, nil)
   end

   -- Print statistics
   print(string.format(
      "Found %d examples in %d files",
      result.collection.total_count,
      result.collection.file_count
   ))

   -- Print errors
   if #result.errors > 0 then
      print("\nErrors and warnings:")
      for _, err in ipairs(result.errors) do
         print("  " .. err)
      end
   end

   -- Save to JSON
   local ok, err = save_collection_json(result.collection, output_file)
   if not ok then
      io.stderr:write("Error: " .. (err or "unknown error") .. "\n")
      os.exit(1)
   end

   print("Saved examples to: " .. output_file)

   -- Exit with error if there were validation errors
   if #result.errors > 0 then
      os.exit(1)
   end
end

-- Run main if this is the main module
if cosmo.is_main() then
   main(arg)
end

return {
   extract_from_teal = extract_from_teal,
   extract_from_text = extract_from_text,
   extract_from_file = extract_from_file,
   extract_from_directory = extract_from_directory,
   save_collection_json = save_collection_json,
   load_collection_json = load_collection_json,
}
