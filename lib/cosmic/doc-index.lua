#!/usr/bin/env lua
-- Generate a serialized documentation index from source files.
-- This script is run with the bootstrap cosmic to generate the doc index.
-- Usage: cosmic lib/cosmic/doc-index.lua file1.tl file2.tl ... > index.lua

local doc = require("cosmic.doc")
local cosmo = require("cosmo")

local function main()
  local modules = {}

  for i = 1, #arg do
    local file_path = arg[i]

    -- Read the file
    local f, err = io.open(file_path, "r")
    if not f then
      io.stderr:write("error: " .. file_path .. ": " .. (err or "cannot open") .. "\n")
      return 1
    end
    local source = f:read("*a")
    f:close()

    -- Parse based on file type
    local module_doc
    if file_path:match("%.d%.tl$") then
      -- .d.tl files require parse_dtl which may not exist in older cosmic
      if doc.parse_dtl then
        module_doc = doc.parse_dtl(source, file_path)
      else
        io.stderr:write("warning: skipping " .. file_path .. " (parse_dtl not available)\n")
        goto continue
      end
    else
      module_doc = doc.parse(source, file_path)
    end

    -- Derive module name from file path
    local name = file_path:gsub("%.d%.tl$", ""):gsub("%.tl$", "")
    name = name:gsub("^lib/", ""):gsub("^types/", ""):gsub("/", ".")

    modules[name] = module_doc

    ::continue::
  end

  io.write(cosmo.EncodeLua({ modules = modules }))
  return 0
end

os.exit(main())
