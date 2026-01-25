#!/usr/bin/env cosmic
--- Minimal cosmic-lua program demonstrating the basic entry point.
---
--- This is the simplest possible cosmic program. It shows:
--- - How to use cosmic.main() as the entry point
--- - How to access stdout via the env parameter
--- - How to return an exit code (0 = success)
---
--- Usage:
---   ./cosmic-lua examples/hello.tl

local cosmic = require("cosmic")

cosmic.main(function(args: {string}, env: cosmic.Env): number
  env.stdout:write("Hello from cosmic-lua!\n")
  return 0
end)
