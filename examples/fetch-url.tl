#!/usr/bin/env cosmic
--- Simple HTTP client using cosmic.fetch.
---
--- Demonstrates:
--- - Fetching a URL with error handling
--- - Accessing HTTP status, headers, and body
--- - Command-line argument handling
---
--- Usage:
---   ./cosmic-lua examples/fetch-url.tl https://example.com

local cosmic = require("cosmic")
local fetch = require("cosmic.fetch")

cosmic.main(function(args: {string}, env: cosmic.Env): number, string
  -- Check arguments
  if #args < 2 then
    env.stderr:write("Usage: fetch-url.tl <url>\n")
    return 1
  end

  local url = args[2]

  env.stdout:write("Fetching: " .. url .. "\n")

  -- Fetch the URL
  local result = fetch.Fetch(url)

  -- Check if fetch succeeded
  if not result.ok then
    return 1, "Fetch failed: " .. result.error
  end

  -- Display results
  env.stdout:write("\nStatus: " .. tostring(result.status) .. "\n")
  env.stdout:write("Content-Type: " .. (result.headers["content-type"] or "unknown") .. "\n")
  env.stdout:write("Body length: " .. #result.body .. " bytes\n")

  -- Display first 200 characters of body
  local preview = result.body:sub(1, 200)
  if #result.body > 200 then
    preview = preview .. "..."
  end
  env.stdout:write("\nBody preview:\n" .. preview .. "\n")

  return 0
end)
