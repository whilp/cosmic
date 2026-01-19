--- Command-line argument parsing.
--- The getopt module provides POSIX-style command-line option parsing with support for both
--- short options (-v) and long options (--verbose).

--- Parser for iterating through command-line options.
local record Parser
  --- Get the next option from the parser.
  ---
  --- Returns the next option character or long name, along with its argument
  --- if the option takes one. Returns nil when no more options remain.
  ---
  --- If the option is unknown, returns "?" as the option name and the unknown
  --- option string as the argument.
  ---
  --- @return string|nil opt Option character or long name, or "?" for unknown, or nil when done
  --- @return string|nil arg Option argument (for options that take arguments), or nil
  next: function(self): string, string

  --- Get remaining non-option arguments after all options have been parsed.
  ---
  --- @return {string} remaining Non-option arguments
  remaining: function(self): {string}
end

local record getopt
  --- Long option definition: {name, has_arg, short}
  --- - name: the long option name (e.g., "help" for --help)
  --- - has_arg: "none", "required", or "optional"
  --- - short: the equivalent short option character (e.g., "h")
  type LongOpt = {string, string, string}

  --- Create a new getopt parser for iterating through command-line options.
  ---
  --- The optstring uses standard getopt format:
  --- - A letter means that option takes no argument (e.g., "v" for -v)
  --- - A letter followed by : means it requires an argument (e.g., "o:" for -o file)
  --- - A letter followed by :: means it takes an optional argument
  ---
  --- Example - Basic usage:
  ---
  ---     local getopt = require("cosmo.getopt")
  ---     local parser = getopt.new(arg, "hvo:", {
  ---       {"help",    "none",     "h"},
  ---       {"verbose", "none",     "v"},
  ---       {"output",  "required", "o"},
  ---     })
  ---
  ---     while true do
  ---       local opt, arg = parser:next()
  ---       if not opt then break end
  ---
  ---       if opt == "h" or opt == "help" then
  ---         print("Usage: ...")
  ---       elseif opt == "v" or opt == "verbose" then
  ---         verbose = true
  ---       elseif opt == "o" or opt == "output" then
  ---         output = arg
  ---       end
  ---     end
  ---
  ---     local remaining = parser:remaining()  -- non-option args
  ---
  --- Example - Handling repeated options:
  ---
  ---     local parser = getopt.new(arg, "e:", {})
  ---     local excludes = {}
  ---     while true do
  ---       local opt, arg = parser:next()
  ---       if not opt then break end
  ---       if opt == "e" then
  ---         table.insert(excludes, arg)
  ---       end
  ---     end
  ---     -- Now excludes contains all -e values: {"foo", "bar", "spam"}
  ---
  --- @param args {string} Command-line arguments (typically `arg`)
  --- @param shortopts string Short options string (e.g., "hvo:")
  --- @param longopts {LongOpt} Long option definitions
  --- @return Parser parser Parser object with next() and remaining() methods
  new: function(args: {string}, shortopts: string, longopts: {LongOpt}): Parser
end

return getopt
