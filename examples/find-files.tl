#!/usr/bin/env cosmic
--- Find files matching a pattern using cosmic.walk.
---
--- Demonstrates:
--- - Directory tree walking with walk.collect()
--- - Lua pattern matching
--- - File path manipulation
---
--- Usage:
---   ./cosmic-lua examples/find-files.tl           # Find all .tl files
---   ./cosmic-lua examples/find-files.tl "%.lua$"  # Find all .lua files
---   ./cosmic-lua examples/find-files.tl "test"    # Find files containing "test"

local cosmic = require("cosmic")
local walk = require("cosmic.walk")
local path = require("cosmo.path")

cosmic.main(function(args: {string}, env: cosmic.Env): number
  -- Default pattern: find .tl files
  local pattern = args[2] or "%.tl$"
  local search_dir = args[3] or "."

  env.stdout:write("Searching for files matching '" .. pattern .. "' in " .. search_dir .. "\n")
  env.stdout:write(string.rep("-", 60) .. "\n")

  -- Collect matching files
  local files = walk.collect(search_dir, pattern)

  -- Display results
  if #files == 0 then
    env.stdout:write("No files found.\n")
  else
    env.stdout:write("Found " .. #files .. " file(s):\n\n")

    for _, file in ipairs(files) do
      env.stdout:write("  " .. file .. "\n")
    end
  end

  return 0
end)
