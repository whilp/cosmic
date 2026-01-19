-- doctest.example: Core data structures for representing documentation examples
--
-- Provides type-safe structures for storing and validating code examples
-- extracted from documentation and source code comments.

local record Example
   -- Unique identifier for this example (generated from source location)
   id: string

   -- Source file this example was extracted from
   source_file: string

   -- Line number where the example starts in the source file
   source_line: integer

   -- Type of example: "example", "setup", "teardown"
   kind: string

   -- The actual code to execute
   code: string

   -- Expected output (for text-based examples with >>> format)
   expected_output: string

   -- Whether this example requires special setup
   requires_setup: boolean

   -- Whether this example requires teardown
   requires_teardown: boolean

   -- Tags associated with this example (e.g., "async", "network")
   tags: {string}
end

local record ExampleCollection
   -- All examples indexed by ID
   examples: {string: Example}

   -- Examples grouped by source file
   by_file: {string: {Example}}

   -- Setup examples (run before regular examples)
   setup_examples: {Example}

   -- Teardown examples (run after regular examples)
   teardown_examples: {Example}

   -- Statistics about the collection
   total_count: integer
   file_count: integer
end

--- Creates a new empty example collection.
---
---@return ExampleCollection
local function new_collection(): ExampleCollection
   return {
      examples = {},
      by_file = {},
      setup_examples = {},
      teardown_examples = {},
      total_count = 0,
      file_count = 0,
   }
end

--- Generates a unique ID for an example based on its source location.
---
---@param source_file string The source file path
---@param source_line integer The line number in the source file
---@param kind string The kind of example
---@return string Unique identifier
local function generate_id(source_file: string, source_line: integer, kind: string): string
   -- Remove path prefix to make IDs more readable
   local short_file = source_file:match("([^/]+)$") or source_file
   return string.format("%s:%d:%s", short_file, source_line, kind)
end

local record NewExampleOpts
   source_file: string
   source_line: integer
   kind: string
   code: string
   expected_output: string
   tags: {string}
end

--- Creates a new example with the given parameters.
---
---@param opts NewExampleOpts Options for creating the example
---@return Example
local function new_example(opts: NewExampleOpts): Example
   local id = generate_id(opts.source_file, opts.source_line, opts.kind)

   return {
      id = id,
      source_file = opts.source_file,
      source_line = opts.source_line,
      kind = opts.kind or "example",
      code = opts.code,
      expected_output = opts.expected_output or "",
      requires_setup = false,
      requires_teardown = false,
      tags = opts.tags or {},
   }
end

--- Validates that an example has executable code.
---
---@param example Example The example to validate
---@return boolean, string? True if valid, false and error message otherwise
local function validate_example(example: Example): boolean, string
   if not example.code or example.code == "" then
      return false, "Example has no code"
   end

   if not example.source_file or example.source_file == "" then
      return false, "Example has no source file"
   end

   if not example.source_line or example.source_line <= 0 then
      return false, "Example has invalid source line"
   end

   local valid_kinds: {string:boolean} = {
      example = true,
      setup = true,
      teardown = true,
   }

   if not valid_kinds[example.kind] then
      return false, "Invalid example kind: " .. tostring(example.kind)
   end

   return true
end

--- Checks if an example contains assertions.
---
--- Assertions are detected by looking for:
--- - assert() calls
--- - Expected output (for text-based examples)
---
---@param example Example The example to check
---@return boolean True if the example contains assertions
local function has_assertions(example: Example): boolean
   -- Check for assert() calls in the code
   if example.code:match("assert%s*%(") then
      return true
   end

   -- Check for expected output
   if example.expected_output and example.expected_output ~= "" then
      return true
   end

   return false
end

--- Adds an example to a collection.
---
---@param collection ExampleCollection The collection to add to
---@param example Example The example to add
local function add_example(collection: ExampleCollection, example: Example)
   -- Add to main index
   collection.examples[example.id] = example
   collection.total_count = collection.total_count + 1

   -- Add to file index
   if not collection.by_file[example.source_file] then
      collection.by_file[example.source_file] = {}
      collection.file_count = collection.file_count + 1
   end
   table.insert(collection.by_file[example.source_file], example)

   -- Add to kind-specific lists
   if example.kind == "setup" then
      table.insert(collection.setup_examples, example)
   elseif example.kind == "teardown" then
      table.insert(collection.teardown_examples, example)
   end
end

--- Gets all examples from a collection for a specific file.
---
---@param collection ExampleCollection The collection to query
---@param file string The file path
---@return {Example} List of examples for that file
local function get_examples_for_file(collection: ExampleCollection, file: string): {Example}
   return collection.by_file[file] or {}
end

--- Removes indentation from a code block while preserving relative indentation.
---
---@param code string The code to dedent
---@return string Dedented code
local function dedent(code: string): string
   local lines = {}
   for line in code:gmatch("([^\n]*)\n?") do
      if line ~= "" or #lines > 0 then
         table.insert(lines, line)
      end
   end

   if #lines == 0 then
      return ""
   end

   -- Find minimum indentation (ignoring empty lines)
   local min_indent: integer = nil
   for _, line in ipairs(lines) do
      if line:match("%S") then  -- Non-empty line
         local indent = line:match("^%s*")
         if indent then
            local indent_len: integer = #indent
            if not min_indent or indent_len < min_indent then
               min_indent = indent_len
            end
         end
      end
   end

   if min_indent == nil or min_indent == 0 then
      return table.concat(lines, "\n")
   end

   -- Remove minimum indentation from all lines
   local dedented: {string} = {}
   for _, line in ipairs(lines) do
      if line:match("%S") then
         table.insert(dedented, line:sub(min_indent + 1))
      else
         table.insert(dedented, "")
      end
   end

   return table.concat(dedented, "\n")
end

return {
   Example = Example,
   ExampleCollection = ExampleCollection,
   new_collection = new_collection,
   new_example = new_example,
   generate_id = generate_id,
   validate_example = validate_example,
   has_assertions = has_assertions,
   add_example = add_example,
   get_examples_for_file = get_examples_for_file,
   dedent = dedent,
}
