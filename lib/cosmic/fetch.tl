--- Structured HTTP fetch with optional retry.
--- Wraps cosmo.Fetch with structured results to prevent accidentally discarding errors.

local cosmo = require("cosmo")
local unix = require("cosmo.unix")

--- Result from a fetch operation.
local record Result
  ok: boolean
  status: number
  headers: {string:string}
  body: string
  error: string
end

local record Opts
  headers: {string:string}
  maxresponse: number
  max_attempts: number
  max_delay: number
  should_retry: function(Result): boolean
end

local function do_fetch(url: string, opts?: Opts): Result
  local status: number
  local headers_or_err: {string:string} | string
  local body: string

  status, headers_or_err, body = cosmo.Fetch(url, opts as {string:any})

  if not status then
    return {ok = false, error = tostring(headers_or_err or "unknown error")}
  end

  return {
    ok = true,
    status = status,
    headers = headers_or_err as {string:string},
    body = body,
  }
end

--- Fetch a URL and return structured result.
--- @param url string URL to fetch
--- @param opts Opts optional fetch options (retry, headers, etc.)
--- @return Result fetch result with ok, status, headers, body, or error
local function Fetch(url: string, opts?: Opts): Result
  local max_attempts = (opts and opts.max_attempts) or 1
  local max_delay = (opts and opts.max_delay) or 30
  local should_retry = opts and opts.should_retry

  local result: Result
  for attempt = 1, max_attempts do
    result = do_fetch(url, opts)

    if not result.ok or not should_retry or not should_retry(result) then
      return result
    end

    if attempt < max_attempts then
      unix.nanosleep(math.min(max_delay, 2 ^ attempt), 0)
    end
  end

  return result
end

local record fetch
  _VERSION: string
  _DESCRIPTION: string
  _USAGE: string
  Fetch: function(url: string, opts?: Opts): Result
  Opts: Opts
  Result: Result
end

local M: fetch = {
  _VERSION = "1.0.0",
  _DESCRIPTION = "Structured HTTP fetch with optional retry logic",
  _USAGE = [[
Usage:
  local fetch = require("cosmic.fetch")

  -- Simple GET request
  local result = fetch.Fetch("https://api.example.com/data")
  if result.ok then
    print("Status:", result.status)
    print("Body:", result.body)
  else
    print("Error:", result.error)
  end

  -- With retry logic
  local result = fetch.Fetch("https://api.example.com/data", {
    max_attempts = 3,
    max_delay = 30,
    should_retry = function(r)
      return r.status >= 500  -- Retry on server errors
    end
  })

Functions:
  Fetch(url, opts?) -> Result
    Fetch a URL and return structured result with retry support.

    Parameters:
      url (string)         - HTTP/HTTPS URL to fetch
      opts.max_attempts    - Maximum retry attempts (default: 1)
      opts.max_delay       - Maximum delay between retries in seconds (default: 30)
      opts.should_retry    - Function(Result) -> boolean to determine if should retry
      opts.headers         - Table of HTTP headers to send
      opts.maxresponse     - Maximum response size

    Returns:
      Result {
        ok (boolean)       - True if request succeeded
        status (number)    - HTTP status code (200, 404, etc.)
        headers (table)    - Response headers
        body (string)      - Response body
        error (string)     - Error message if ok is false
      }
]],
  Fetch = Fetch,
}

return M
