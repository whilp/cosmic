-- cosmic-lua dispatcher
-- entry point for cosmic binary that handles special args and dispatches to features

global warn: function(...: any)

require("tl").loader()

local getopt = require("cosmo.getopt")

-- Long option definition: {name, arg_requirement, short_alias}
local type LongOpt = {string, string, string}

-- Parsed options record
local record Opts
  execute: {string}
  load: {string}
  interactive: boolean
  version: boolean
  warnings: boolean
  help: boolean | string
  script: string
  script_args: {integer:string}
  compile: string          -- Input file for --compile (outputs to stdout)
  check: string            -- Input file for --check
  embed: {string}          -- Files to embed via --embed
  output: string           -- Output file for --embed (defaults to "cosmic")
  example: string          -- Input file for --example (run examples)
  benchmark: string        -- Input file for --benchmark (run benchmarks)
  doc: string              -- Input file for --doc (generate docs)
  list_modules: boolean    -- List available modules
  list_functions: string   -- List functions in a module
  error: string            -- Parse error message
end

-- Parse arguments using cosmo.getopt iterator API
local function parse_args(): Opts
  local opts: Opts = {
    execute = {},
    load = {},
    interactive = false,
    version = false,
    warnings = false,
    help = nil,
    script = nil,
    script_args = {},
    compile = nil,
    check = nil,
    embed = {},
    output = nil,
    example = nil,
    benchmark = nil,
    doc = nil,
    list_modules = false,
    list_functions = nil,
    error = nil,
  }

  local shortopts = "e:l:ivEWh::"
  local longopts: {LongOpt} = {
    { "help", "optional", "h" },
    { "compile", "required", nil },
    { "check", "required", nil },  -- Takes first file, remaining files via remaining()
    { "embed", "required", nil },
    { "output", "required", nil },
    { "example", "required", nil },
    { "benchmark", "required", nil },
    { "doc", "required", nil },
    { "list-modules", "none", nil },
    { "list-functions", "required", nil },
  }

  -- Parse shortopts to build set of options that require arguments
  local short_needs_arg: {string:boolean} = {}
  local j = 1
  while j <= #shortopts do
    local c = shortopts:sub(j, j)
    if c ~= ":" then
      -- Check if followed by : (required arg) but not :: (optional arg)
      if j < #shortopts and shortopts:sub(j+1, j+1) == ":" and
         (j+1 >= #shortopts or shortopts:sub(j+2, j+2) ~= ":") then
        short_needs_arg[c] = true
      end
    end
    j = j + 1
  end

  -- Parse longopts to build set of options that require arguments
  local long_needs_arg: {string:boolean} = {}
  for _, opt in ipairs(longopts) do
    if opt[2] == "required" then
      long_needs_arg[opt[1]] = true
    end
  end

  -- Options that consume all remaining arguments (no script after them)
  local long_greedy: {string:boolean} = {}

  -- Find first non-option argument (script name) to know where to stop parsing
  local script_idx: integer = nil
  local i = 1
  while i <= #arg do
    local a = arg[i]
    if a == "--" then
      -- Explicit end of options
      script_idx = i + 1
      break
    elseif a:sub(1, 2) == "--" then
      -- Long option
      local opt_name = a:sub(3)
      if long_greedy[opt_name] then
        -- Greedy option: consumes all remaining args, no script
        script_idx = nil
        break
      elseif not opt_name:find("=") and long_needs_arg[opt_name] then
        -- Takes next arg
        i = i + 2
      else
        i = i + 1
      end
    elseif a:sub(1, 1) == "-" and #a > 1 then
      -- Short option
      if #a == 2 and short_needs_arg[a:sub(2, 2)] then
        -- Single short option that takes arg
        i = i + 2
      else
        i = i + 1
      end
    else
      -- First non-option is the script name
      script_idx = i
      break
    end
  end

  -- Only parse cosmic options (before script name)
  local cosmic_args: {string} = {}
  if script_idx then
    for k = 1, script_idx - 1 do
      if arg[k] ~= "--" then  -- Exclude -- separator
        cosmic_args[#cosmic_args + 1] = arg[k]
      end
    end
  else
    cosmic_args = arg
  end

  local parser = getopt.new(cosmic_args, shortopts, longopts as {{string, string}})

  -- Iterate through all options
  while true do
    local opt, optarg = parser:next()
    if not opt then
      break
    end

    if opt == "?" then
      -- Unknown cosmic option
      opts.error = "cosmic-lua: unknown option '" .. optarg .. "'"
      return opts
    elseif opt == "e" then
      opts.execute[#opts.execute + 1] = optarg
    elseif opt == "l" then
      opts.load[#opts.load + 1] = optarg
    elseif opt == "i" then
      opts.interactive = true
    elseif opt == "v" then
      opts.version = true
    elseif opt == "E" then
      -- Ignore environment variables (already handled by lua)
    elseif opt == "W" then
      opts.warnings = true
    elseif opt == "h" or opt == "help" then
      if optarg then
        opts.help = optarg
      else
        opts.help = true
      end
      return opts
    elseif opt == "compile" then
      opts.compile = optarg
      return opts
    elseif opt == "check" then
      opts.check = optarg
      return opts
    elseif opt == "embed" then
      opts.embed[#opts.embed + 1] = optarg
    elseif opt == "output" then
      opts.output = optarg
    elseif opt == "example" then
      opts.example = optarg
      return opts
    elseif opt == "benchmark" then
      opts.benchmark = optarg
      return opts
    elseif opt == "doc" then
      opts.doc = optarg
      return opts
    elseif opt == "list-modules" then
      opts.list_modules = true
      return opts
    elseif opt == "list-functions" then
      opts.list_functions = optarg
      return opts
    end
  end

  -- Handle script and script args (from original arg, starting at script_idx)
  if script_idx then
    opts.script = arg[script_idx]
    opts.script_args[0] = arg[script_idx]
    local arg_num = 1
    for k = script_idx + 1, #arg do
      -- Skip -- separator
      if arg[k] ~= "--" then
        opts.script_args[arg_num] = arg[k]
        arg_num = arg_num + 1
      end
    end
    opts.script_args[-1] = arg[-1]
  end

  return opts
end

-- Simple REPL using debug.debug
local function run_repl()
  io.write(_VERSION .. "  Copyright (C) 1994-2024 Lua.org, PUC-Rio\n")
  debug.debug()
end

-- Load a script file (.tl or .lua)
-- Compiles .tl files through Teal, loads .lua files directly
local function load_script_file(script_path: string): function(...: any): any..., string
  -- Compile .tl files through Teal, load .lua files directly
  if script_path:match("%.tl$") then
    local teal = require("cosmic.teal")
    local result = teal.compile(script_path)
    if not result.ok then
      return nil, teal.format_issues(result.errors)
    end
    -- Strip shebang from compiled code before loading (Lua parser doesn't handle shebangs)
    local code = result.code
    if code:sub(1, 2) == "#!" then
      local newline_pos = code:find("\n")
      if newline_pos then
        code = code:sub(newline_pos + 1)
      end
    end
    return load(code, "@" .. script_path)
  else
    return loadfile(script_path)
  end
end

local function main(): integer, string
  local opts = parse_args()

  -- Handle parse errors
  if opts.error then
    return 1, opts.error
  end

  -- Handle -v
  if opts.version then
    io.write(_VERSION .. "\n")
    return 0
  end

  -- Handle --help
  if opts.help then
    if type(opts.help) == "string" then
      -- Help for specific module
      local ok, mod = pcall(require, opts.help as string)
      if ok and type(mod) == "table" then
        io.write("Module: " .. (opts.help as string) .. "\n")
        local modtbl = mod as {string:string}
        if modtbl._VERSION then
          io.write("Version: " .. modtbl._VERSION .. "\n")
        end
        if modtbl._DESCRIPTION then
          io.write("\n" .. modtbl._DESCRIPTION .. "\n")
        end
        if modtbl._USAGE then
          io.write("\nUsage:\n" .. modtbl._USAGE .. "\n")
        end
        return 0
      else
        return 1, "error: module '" .. (opts.help as string) .. "' not found"
      end
    else
      -- General cosmic help
      io.write("cosmic-lua: cosmopolitan lua with bundled libraries\n")
      io.write("\n")
      io.write("Usage: cosmic-lua [options] [script [args]]\n")
      io.write("\n")
      io.write("Cosmic options:\n")
      io.write("  --compile <file.tl>      compile Teal file to Lua, lax mode (stdout)\n")
      io.write("  --check <file.tl>        type-check a Teal file, strict mode\n")
      io.write("  --embed <file>           embed file(s) into cosmic (use multiple times)\n")
      io.write("  --output <file>          output file for --embed (default: cosmic)\n")
      io.write("  --example <file.tl>      run Example_* functions, check output\n")
      io.write("  --benchmark <file.tl[:pattern]>  run Benchmark_* functions, report timing\n")
      io.write("  --doc <file.tl>          generate markdown documentation\n")
      io.write("  --help [module]          show help for cosmic or a module\n")
      io.write("  --list-modules           list all available modules\n")
      io.write("  --list-functions <mod>   list functions in a module\n")
      io.write("\n")
      io.write("Standard lua options:\n")
      io.write("  -e <stat>                execute string 'stat'\n")
      io.write("  -l <name>                require library 'name'\n")
      io.write("  -i                       enter interactive mode\n")
      io.write("  -v                       show version information\n")
      io.write("  -E                       ignore environment variables\n")
      io.write("  -W                       turn warnings into errors\n")
      io.write("\n")
      io.write("Quick Start:\n")
      io.write("  cosmic-lua --list-modules            # List available modules\n")
      io.write("  cosmic-lua --help=cosmic.fetch       # Get help on a module\n")
      io.write("  cosmic-lua --list-functions cosmo    # List cosmo functions\n")
      io.write("  cosmic-lua -e 'print(\"hello\")'       # Execute Lua code\n")
      io.write("\n")
      io.write("Main Modules:\n")
      io.write("  cosmo          - Core Cosmopolitan Libc bindings (HTTP, crypto, JSON)\n")
      io.write("  unix           - POSIX system calls (files, processes, networking)\n")
      io.write("  cosmic.fetch   - HTTP client with retry logic\n")
      io.write("  cosmic.spawn   - Process spawning utilities\n")
      io.write("  cosmic.walk    - Directory tree walking\n")
      io.write("\n")
      io.write("For module help: cosmic-lua --help=<module>\n")
      return 0
    end
  end

  -- Handle --list-modules
  if opts.list_modules then
    local modules = {
      {name = "cosmo", desc = "Core Cosmopolitan Libc bindings (HTTP, crypto, compression, JSON)"},
      {name = "unix", desc = "POSIX system calls (files, processes, networking, time)"},
      {name = "cosmic", desc = "Cosmopolitan Lua utilities and main entry point"},
      {name = "cosmic.fetch", desc = "Structured HTTP fetch with retry logic"},
      {name = "cosmic.spawn", desc = "Process spawning with stdin/stdout/stderr control"},
      {name = "cosmic.walk", desc = "Directory tree walking with visitor pattern"},
      {name = "cosmic.doc", desc = "Extract documentation from Teal files, render as markdown"},
      {name = "cosmic.embed", desc = "Embed files into cosmic executable"},
      {name = "cosmic.example", desc = "Go-style executable example testing"},
      {name = "cosmic.teal", desc = "Teal compilation and type-checking"},
      {name = "cosmo.getopt", desc = "Command-line option parsing (getopt)"},
      {name = "cosmo.path", desc = "File path manipulation utilities"},
      {name = "cosmo.unix", desc = "Extended Unix utilities"},
      {name = "cosmo.zip", desc = "ZIP archive reading and writing"},
      {name = "cosmo.re", desc = "POSIX regular expression matching"},
      {name = "cosmo.lsqlite3", desc = "SQLite3 database bindings"},
    }

    io.write("Available modules:\n\n")
    for _, mod in ipairs(modules) do
      io.write(string.format("  %-20s %s\n", mod.name, mod.desc))
    end
    io.write("\nUse --help <module> for detailed information\n")
    io.write("Use --list-functions <module> to see available functions\n")
    return 0
  end

  -- Handle --list-functions
  if opts.list_functions then
    local ok, mod = pcall(require, opts.list_functions as string)
    if not ok or type(mod) ~= "table" then
      return 1, "error: module '" .. (opts.list_functions as string) .. "' not found"
    end

    io.write("Functions in " .. (opts.list_functions as string) .. ":\n\n")
    local items: {{string, string}} = {}
    for k, v in pairs(mod as {string:any}) do
      if not k:match("^_") then  -- Skip internal fields
        items[#items + 1] = {k, type(v)}
      end
    end
    table.sort(items, function(a: {string, string}, b: {string, string}): boolean
      return a[1] < b[1]
    end)

    for _, item in ipairs(items) do
      io.write(string.format("  %-30s (%s)\n", item[1], item[2]))
    end

    io.write("\nUse --help " .. (opts.list_functions as string) .. " for detailed usage\n")
    return 0
  end

  -- Handle --compile
  if opts.compile then
    local teal = require("cosmic.teal")
    local result = teal.compile(opts.compile)
    if result.ok then
      io.write(result.code)
      return 0
    else
      io.stderr:write(teal.format_issues(result.errors) .. "\n")
      return 1
    end
  end

  -- Handle --check
  if opts.check then
    local teal = require("cosmic.teal")
    local result = teal.check(opts.check)

    if #result.warnings > 0 then
      io.stderr:write(teal.format_issues(result.warnings) .. "\n")
    end
    if #result.errors > 0 then
      io.stderr:write(teal.format_issues(result.errors) .. "\n")
    end

    if result.ok then
      io.write("Type check passed\n")
      return 0
    else
      return 1
    end
  end

  -- Handle --embed
  if #opts.embed > 0 then
    local embed = require("cosmic.embed")
    local result = embed.run(opts.embed, opts.output)
    io.write(result.message .. "\n")
    return result.ok and 0 or 1
  end

  -- Handle --example
  if opts.example then
    local example = require("cosmic.example")
    local result = example.run(opts.example)
    io.write(example.format_results(opts.example, result) .. "\n")
    return result.exit_code
  end

  -- Handle --benchmark
  -- Supports: --benchmark file.tl or --benchmark file.tl:pattern
  if opts.benchmark then
    local benchmark = require("cosmic.benchmark")
    local file_path = opts.benchmark
    local filter: string = nil

    -- Check for colon-separated filter pattern
    local colon_pos = opts.benchmark:find(":[^/\\]") -- Avoid matching Windows paths or protocol prefixes
    if colon_pos then
      file_path = opts.benchmark:sub(1, colon_pos - 1)
      filter = opts.benchmark:sub(colon_pos + 1)
    end

    local result = benchmark.run(file_path, filter)
    io.write(benchmark.format_results(file_path, result) .. "\n")
    return result.exit_code
  end

  -- Handle --doc
  if opts.doc then
    local doc = require("cosmic.doc")
    local ok, output = doc.render_file(opts.doc)
    if ok then
      io.write(output)
      return 0
    else
      io.stderr:write(output .. "\n")
      return 1
    end
  end

  -- Handle -W warnings: convert warnings to errors
  if opts.warnings then
    warn = function(...: string)
      local msg = table.concat({...}, " ")
      error("warning: " .. msg, 2)
    end
  end

  -- Load libraries
  for _, name in ipairs(opts.load) do
    require(name)
  end

  -- Execute strings
  for _, code in ipairs(opts.execute) do
    local chunk, err = load(code, "=(command line)")
    if chunk then
      chunk()
    else
      return 1, "cosmic-lua: " .. (err or "error loading command")
    end
  end

  -- Execute script file
  if opts.script then
    _G.arg = opts.script_args as {string}
    local chunk, err = load_script_file(opts.script)
    if not chunk then
      return 1, "cosmic-lua: " .. (err or "error loading script")
    end
    -- Call chunk with script args as varargs (matching standard lua behavior)
    -- Standard lua passes arg[1], arg[2], ... as varargs to the script
    -- Note: table.unpack has a limit of ~250 args, but this is not a practical concern
    local args: {string} = {}
    for i = 1, #opts.script_args do
      args[i] = opts.script_args[i]
    end
    chunk(table.unpack(args))
    return 0
  end

  -- Interactive mode or REPL
  if opts.interactive or (#opts.execute == 0 and #opts.load == 0 and #arg == 0) then
    run_repl()
    return 0
  end

  -- If we have -e or -l but no script, exit normally
  if #opts.execute > 0 or #opts.load > 0 then
    return 0
  end

  return 0
end

local code, msg = main()
if msg then
  io.stderr:write(msg .. "\n")
end
os.exit(code)
