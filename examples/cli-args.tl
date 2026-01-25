#!/usr/bin/env cosmic
--- Command-line argument parsing with cosmo.getopt.
---
--- Demonstrates:
--- - Short and long option parsing
--- - Required and optional arguments
--- - Handling unknown options
--- - Accessing remaining non-option arguments
---
--- Usage:
---   ./cosmic-lua examples/cli-args.tl --help
---   ./cosmic-lua examples/cli-args.tl -v -o output.txt file1.txt file2.txt
---   ./cosmic-lua examples/cli-args.tl --verbose --output=out.txt file.txt

local cosmic = require("cosmic")
local getopt = require("cosmo.getopt")

cosmic.main(function(args: {string}, env: cosmic.Env): number, string
  -- Default configuration
  local verbose = false
  local output_file = "output.txt"
  local count = 1

  -- Create getopt parser
  -- Short options: "hvo:c:" where : means the option requires an argument
  -- Long options: array of {name, arg_type, short_equivalent}
  local parser = getopt.new(args, "hvo:c:", {
    {"help",    "none",     "h"},
    {"verbose", "none",     "v"},
    {"output",  "required", "o"},
    {"count",   "required", "c"},
  })

  -- Process all options
  while true do
    local opt, arg = parser:next()

    if not opt then
      break  -- No more options
    end

    if opt == "h" or opt == "help" then
      env.stdout:write([[
Usage: cli-args.tl [OPTIONS] [FILES...]

Options:
  -h, --help              Show this help message
  -v, --verbose           Enable verbose output
  -o, --output FILE       Output file (default: output.txt)
  -c, --count N           Number of times to process (default: 1)

Examples:
  cli-args.tl -v file.txt
  cli-args.tl --output=out.txt --count=3 file1.txt file2.txt
]])
      return 0

    elseif opt == "v" or opt == "verbose" then
      verbose = true

    elseif opt == "o" or opt == "output" then
      output_file = arg

    elseif opt == "c" or opt == "count" then
      count = tonumber(arg) or 1

    elseif opt == "?" then
      -- Unknown option
      local unknown = parser:unknown()
      return 1, "Unknown option: " .. unknown .. "\nUse --help for usage."
    end
  end

  -- Get remaining non-option arguments (the file names)
  local files = parser:remaining()

  -- Display parsed configuration
  env.stdout:write("Configuration:\n")
  env.stdout:write("  Verbose: " .. tostring(verbose) .. "\n")
  env.stdout:write("  Output file: " .. output_file .. "\n")
  env.stdout:write("  Count: " .. tostring(count) .. "\n")
  env.stdout:write("  Files: " .. (files and #files or 0) .. "\n")

  if files and #files > 0 then
    env.stdout:write("\nFiles to process:\n")
    for i, file in ipairs(files) do
      env.stdout:write("  " .. tostring(i) .. ". " .. file .. "\n")
    end
  else
    env.stdout:write("\nNo files specified.\n")
  end

  if verbose then
    env.stdout:write("\nVerbose mode: Would process files " .. tostring(count) .. " time(s)\n")
    env.stdout:write("Results would be saved to: " .. output_file .. "\n")
  end

  return 0
end)
