--- Command-line option parsing.
--- Parse command-line arguments using POSIX getopt conventions.

--- Parser for iterating through command-line options.
local record parser
  --- Get the next option from the command line.
  --- Returns the option character and its argument (if any).
  --- Returns `nil` when all options have been processed.
  --- @return string|nil opt The option character or nil when done
  --- @return string|nil arg The option's argument (if applicable)
  next: function(self: parser): string, string

  --- Get the remaining non-option arguments.
  --- Returns all arguments that follow the options.
  --- @return {string} args Array of remaining arguments
  remaining: function(self: parser): {string}

  --- Get unknown options encountered during parsing.
  --- Returns options that were not specified in optstring or longopts.
  --- @return {string} opts Array of unknown options
  unknown: function(self: parser): {string}
end

local record getopt
  --- Create a new option parser.
  --- Parses command-line arguments according to POSIX conventions.
  ---
  --- The optstring format follows getopt conventions:
  --- - Single character options (e.g., "abc" for -a, -b, -c)
  --- - Colon after char means required argument (e.g., "o:" for -o value)
  --- - Double colon means optional argument (e.g., "o::" for -o or -o value)
  ---
  --- Example:
  ---
  ---     local getopt = require("cosmo.getopt")
  ---     local parser = getopt.new(arg, "ho:v", {help = 0, output = 1})
  ---
  ---     local opt, optarg = parser:next()
  ---     while opt do
  ---       if opt == 'h' or opt == 'help' then
  ---         print("Usage: program [options]")
  ---       elseif opt == 'o' or opt == 'output' then
  ---         print("Output:", optarg)
  ---       end
  ---       opt, optarg = parser:next()
  ---     end
  ---
  ---     local remaining = parser:remaining()
  ---
  --- @param args {string} The arguments to parse (typically `arg`)
  --- @param optstring string Short option specification (e.g., "ho:v")
  --- @param longopts {table} Long options map: {name = arg_type} where arg_type is 0 (no arg) or 1 (required arg)
  --- @return parser The option parser
  new: function(args: {string}, optstring: string, longopts?: {table}): parser
end

return getopt

