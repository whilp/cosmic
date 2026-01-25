--- Generate a serialized documentation index from source files.
--- Run directly as a script with source files as arguments.

local doc = require("cosmic.doc")
local cosmo = require("cosmo")

local record DocIndexModule
  generate: function(files: {string}): string, string
  main: function(args: {string}): integer
end

--- Generate serialized documentation index from source files.
--- @param files List of .tl or .d.tl file paths to process
--- @return Encoded Lua source for the index, or nil on error
--- @return Error message if generation failed
local function generate(files: {string}): string, string
  local modules: {string:any} = {}

  for i = 1, #files do
    local file_path = files[i]

    local ok, source = pcall(cosmo.Slurp, file_path)
    if not ok then
      return nil, file_path .. ": " .. (source as string or "cannot read")
    end

    -- Parse based on file type
    local module_doc: any
    if file_path:match("%.d%.tl$") then
      module_doc = doc.parse_dtl(source as string, file_path)
    else
      module_doc = doc.parse(source as string, file_path)
    end

    -- Derive module name from file path
    local name = file_path:gsub("%.d%.tl$", ""):gsub("%.tl$", "")
    name = name:gsub("^lib/", ""):gsub("^types/", ""):gsub("/", ".")

    modules[name] = module_doc
  end

  return cosmo.EncodeLua({ modules = modules })
end

local function main(args: {string}): integer
  local result, err = generate(args)
  if not result then
    io.stderr:write("error: " .. err .. "\n")
    return 1
  end
  io.write(result)
  return 0
end

local M: DocIndexModule = {
  generate = generate,
  main = main,
}

-- When run as a script, execute main
if arg and arg[0] and arg[0]:match("docindex%.tl$") then
  os.exit(main(arg))
end

return M
