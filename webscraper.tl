#!/usr/bin/env cosmic
--- Web scraper that fetches URLs, extracts links, and stores them in SQLite.
--- Supports retry logic, configuration files, and proper error handling.

local cosmic = require("cosmic")
local fetch = require("cosmic.fetch")
local walk = require("cosmic.walk")
local getopt = require("cosmo.getopt")
local lsqlite3 = require("cosmo.lsqlite3")
local unix = require("cosmo.unix")
local path = require("cosmo.path")

--- Database handle types (lsqlite3)
local record Database
  exec: function(self: Database, sql: string): number
  prepare: function(self: Database, sql: string): Statement
  close: function(self: Database): number
  last_insert_rowid: function(self: Database): number
  errmsg: function(self: Database): string
  errcode: function(self: Database): number
end

local record Statement
  bind: function(self: Statement, idx: number, value: any): number
  bind_values: function(self: Statement, ...: any): number
  step: function(self: Statement): number
  reset: function(self: Statement): number
  finalize: function(self: Statement): number
  get_value: function(self: Statement, idx: number): any
  get_values: function(self: Statement): {any}
end

--- Configuration for the scraper
local record Config
  max_retries: number
  max_delay: number
  database_path: string
  config_file: string
  verbose: boolean
  user_agent: string
end

--- Scraped data entry
local record ScrapedEntry
  url: string
  links: {string}
  timestamp: number
  success: boolean
  error: string
end

--- Default configuration
local DEFAULT_CONFIG: Config = {
  max_retries = 3,
  max_delay = 30,
  database_path = "scraper.db",
  config_file = nil,
  verbose = false,
  user_agent = "cosmic-webscraper/1.0",
}

--- Initialize the SQLite database with required tables.
--- Creates a 'pages' table for URLs and a 'links' table for extracted links.
--- @param db_path string Path to the SQLite database file
--- @return Database | nil, string Database handle or error message
local function init_database(db_path: string): Database, string
  local db = lsqlite3.open(db_path) as Database
  if not db then
    return nil, "Failed to open database: " .. db_path
  end

  -- Create pages table
  local sql_pages = [[
    CREATE TABLE IF NOT EXISTS pages (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      url TEXT NOT NULL UNIQUE,
      fetch_timestamp INTEGER NOT NULL,
      success INTEGER NOT NULL,
      error_message TEXT
    );
  ]]

  local result = db:exec(sql_pages)
  if result ~= lsqlite3.OK then
    return nil, "Failed to create pages table: " .. db:errmsg()
  end

  -- Create links table
  local sql_links = [[
    CREATE TABLE IF NOT EXISTS links (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      page_id INTEGER NOT NULL,
      link_url TEXT NOT NULL,
      FOREIGN KEY (page_id) REFERENCES pages(id),
      UNIQUE(page_id, link_url)
    );
  ]]

  result = db:exec(sql_links)
  if result ~= lsqlite3.OK then
    return nil, "Failed to create links table: " .. db:errmsg()
  end

  -- Create index for faster lookups
  local sql_index = [[
    CREATE INDEX IF NOT EXISTS idx_page_url ON pages(url);
  ]]

  result = db:exec(sql_index)
  if result ~= lsqlite3.OK then
    return nil, "Failed to create index: " .. db:errmsg()
  end

  return db, nil
end

--- Extract all HTTP/HTTPS links from HTML content using pattern matching.
--- Finds both href and src attributes in HTML tags.
--- @param html string HTML content to parse
--- @return {string} List of extracted URLs
local function extract_links(html: string): {string}
  local links: {string} = {}
  local seen: {string:boolean} = {}

  -- Use Lua pattern matching for reliable HTML parsing
  -- Pattern for href="..." with double quotes
  for url in html:gmatch('[hH][rR][eE][fF]="(https?://[^"]+)"') do
    if not seen[url] then
      table.insert(links, url)
      seen[url] = true
    end
  end

  -- Pattern for href='...' with single quotes
  for url in html:gmatch("[hH][rR][eE][fF]='(https?://[^']+)'") do
    if not seen[url] then
      table.insert(links, url)
      seen[url] = true
    end
  end

  -- Pattern for src="..." with double quotes
  for url in html:gmatch('[sS][rR][cC]="(https?://[^"]+)"') do
    if not seen[url] then
      table.insert(links, url)
      seen[url] = true
    end
  end

  -- Pattern for src='...' with single quotes
  for url in html:gmatch("[sS][rR][cC]='(https?://[^']+)'") do
    if not seen[url] then
      table.insert(links, url)
      seen[url] = true
    end
  end

  return links
end

--- Store scraped page data in the database.
--- Inserts the page record and all extracted links.
--- @param db Database Database handle
--- @param entry ScrapedEntry Scraped data to store
--- @return boolean, string Success status and optional error message
local function store_in_database(db: Database, entry: ScrapedEntry): boolean, string
  -- Begin transaction for consistency
  local result = db:exec("BEGIN TRANSACTION;")
  if result ~= lsqlite3.OK then
    return false, "Failed to begin transaction: " .. db:errmsg()
  end

  -- Insert page record
  local stmt = db:prepare([[
    INSERT OR REPLACE INTO pages (url, fetch_timestamp, success, error_message)
    VALUES (?, ?, ?, ?)
  ]]) as Statement

  if not stmt then
    db:exec("ROLLBACK;")
    return false, "Failed to prepare statement: " .. db:errmsg()
  end

  stmt:bind_values(
    entry.url,
    entry.timestamp,
    entry.success and 1 or 0,
    entry.error
  )

  result = stmt:step()
  if result ~= lsqlite3.DONE then
    stmt:finalize()
    db:exec("ROLLBACK;")
    return false, "Failed to insert page: " .. db:errmsg()
  end

  local page_id = db:last_insert_rowid()
  stmt:finalize()

  -- Insert links if the fetch was successful
  if entry.success and #entry.links > 0 then
    local link_stmt = db:prepare([[
      INSERT OR IGNORE INTO links (page_id, link_url)
      VALUES (?, ?)
    ]]) as Statement

    if not link_stmt then
      db:exec("ROLLBACK;")
      return false, "Failed to prepare link statement: " .. db:errmsg()
    end

    for _, link in ipairs(entry.links) do
      link_stmt:reset()
      link_stmt:bind_values(page_id, link)
      result = link_stmt:step()
      if result ~= lsqlite3.DONE then
        link_stmt:finalize()
        db:exec("ROLLBACK;")
        return false, "Failed to insert link: " .. db:errmsg()
      end
    end

    link_stmt:finalize()
  end

  -- Commit transaction
  result = db:exec("COMMIT;")
  if result ~= lsqlite3.OK then
    return false, "Failed to commit transaction: " .. db:errmsg()
  end

  return true, nil
end

--- Retry logic for failed HTTP requests.
--- Determines if a request should be retried based on status code.
--- @param result fetch.Result Fetch result
--- @return boolean Whether the request should be retried
local function should_retry_request(result: fetch.Result): boolean
  if not result.ok then
    return true  -- Network errors should be retried
  end

  -- Retry on server errors (5xx) and rate limiting (429)
  if result.status >= 500 or result.status == 429 then
    return true
  end

  return false
end

--- Scrape a single URL with retry logic.
--- Fetches the URL, extracts links, and returns the scraped data.
--- @param url string URL to scrape
--- @param config Config Scraper configuration
--- @return ScrapedEntry Scraped data with success/error status
local function scrape_url(url: string, config: Config): ScrapedEntry
  if config.verbose then
    io.stdout:write("Fetching: " .. url .. "\n")
  end

  local fetch_opts: fetch.Opts = {
    max_attempts = config.max_retries,
    max_delay = config.max_delay,
    should_retry = should_retry_request,
    headers = {
      ["User-Agent"] = config.user_agent,
    },
  }

  local result = fetch.Fetch(url, fetch_opts)
  local timestamp = unix.clock_gettime(unix.CLOCK_REALTIME)

  if not result.ok then
    if config.verbose then
      io.stderr:write("  Error: " .. (result.error or "unknown error") .. "\n")
    end
    return {
      url = url,
      links = {},
      timestamp = timestamp,
      success = false,
      error = result.error or "unknown error",
    }
  end

  if result.status ~= 200 then
    local err = "HTTP " .. tostring(result.status)
    if config.verbose then
      io.stderr:write("  Error: " .. err .. "\n")
    end
    return {
      url = url,
      links = {},
      timestamp = timestamp,
      success = false,
      error = err,
    }
  end

  -- Extract links from HTML
  local links = extract_links(result.body)

  if config.verbose then
    io.stdout:write("  Found " .. tostring(#links) .. " links\n")
  end

  return {
    url = url,
    links = links,
    timestamp = timestamp,
    success = true,
    error = nil,
  }
end

--- Find configuration file by walking up directories.
--- Searches for a .webscraperrc file in the current directory and parent directories.
--- @param start_dir string Starting directory for the search
--- @param filename string Configuration filename to find
--- @return string | nil Path to config file if found
local function find_config_file(start_dir: string, filename: string): string
  local current_dir = start_dir
  local max_depth = 10
  local depth = 0

  while depth < max_depth do
    local config_path = path.join(current_dir, filename)
    local stat = unix.stat(config_path)

    if stat and not unix.S_ISDIR(stat:mode()) then
      return config_path
    end

    -- Move up one directory
    local parent = path.dirname(current_dir)
    if parent == current_dir or parent == "/" then
      break
    end
    current_dir = parent
    depth = depth + 1
  end

  return nil
end

--- Load configuration from a file.
--- Reads key=value pairs from the config file.
--- @param config_path string Path to configuration file
--- @param config Config Configuration object to update
--- @return boolean, string Success status and optional error
local function load_config_file(config_path: string, config: Config): boolean, string
  local file = io.open(config_path, "r")
  if not file then
    return false, "Failed to open config file: " .. config_path
  end

  local line_num = 0
  for line in file:lines() do
    line_num = line_num + 1
    -- Skip empty lines and comments
    if line:match("^%s*$") or line:match("^%s*#") then
      goto continue
    end

    -- Parse key=value
    local key, value = line:match("^%s*([%w_]+)%s*=%s*(.+)%s*$")
    if not key or not value then
      file:close()
      return false, "Invalid config line " .. tostring(line_num) .. ": " .. line
    end

    -- Apply configuration
    if key == "max_retries" then
      config.max_retries = tonumber(value) or config.max_retries
    elseif key == "max_delay" then
      config.max_delay = tonumber(value) or config.max_delay
    elseif key == "database_path" then
      config.database_path = value
    elseif key == "user_agent" then
      config.user_agent = value
    end

    ::continue::
  end

  file:close()
  return true, nil
end

--- Print usage information.
--- @param program_name string Name of the program
local function print_usage(program_name: string)
  io.stdout:write([[
Usage: ]] .. program_name .. [[ [OPTIONS] URL [URL...]

Web scraper that fetches URLs, extracts links, and stores them in SQLite.

Options:
  -h, --help              Show this help message
  -v, --verbose           Enable verbose output
  -d, --database PATH     Database file path (default: scraper.db)
  -r, --retries N         Maximum retry attempts (default: 3)
  -c, --config FILE       Configuration file path
  -u, --user-agent UA     Custom User-Agent string

Configuration File:
  The scraper can load settings from a .webscraperrc file in the current
  directory or any parent directory. The file uses key=value format:

    max_retries=5
    max_delay=60
    database_path=./data/scraper.db
    user_agent=MyBot/1.0

Examples:
  # Scrape a single URL
  ]] .. program_name .. [[ https://example.com

  # Scrape multiple URLs with verbose output
  ]] .. program_name .. [[ -v https://example.com https://example.org

  # Use custom database and retry settings
  ]] .. program_name .. [[ -d data.db -r 5 https://example.com

]])
end

--- Main entry point for the web scraper.
--- Parses arguments, initializes database, and scrapes URLs.
cosmic.main(function(args: {string}, env: cosmic.Env): number, string
  -- Initialize configuration
  local config: Config = {
    max_retries = DEFAULT_CONFIG.max_retries,
    max_delay = DEFAULT_CONFIG.max_delay,
    database_path = DEFAULT_CONFIG.database_path,
    config_file = DEFAULT_CONFIG.config_file,
    verbose = DEFAULT_CONFIG.verbose,
    user_agent = DEFAULT_CONFIG.user_agent,
  }

  -- Try to find and load config file
  local cwd = unix.getcwd()
  if cwd then
    local config_file = find_config_file(cwd, ".webscraperrc")
    if config_file then
      local ok, err = load_config_file(config_file, config)
      if not ok then
        return 1, "Error loading config: " .. (err or "unknown error")
      end
      if config.verbose then
        env.stdout:write("Loaded config from: " .. config_file .. "\n")
      end
    end
  end

  -- Parse command-line arguments
  local parser = getopt.new(args, "hvd:r:c:u:", {
    {"help",       "none",     "h"},
    {"verbose",    "none",     "v"},
    {"database",   "required", "d"},
    {"retries",    "required", "r"},
    {"config",     "required", "c"},
    {"user-agent", "required", "u"},
  })

  while true do
    local opt, arg = parser:next()
    if not opt then break end

    if opt == "h" or opt == "help" then
      print_usage(args[0] or "webscraper.tl")
      return 0
    elseif opt == "v" or opt == "verbose" then
      config.verbose = true
    elseif opt == "d" or opt == "database" then
      config.database_path = arg
    elseif opt == "r" or opt == "retries" then
      local retries = tonumber(arg)
      if not retries or retries < 1 then
        return 1, "Invalid retry count: " .. arg
      end
      config.max_retries = retries
    elseif opt == "c" or opt == "config" then
      local ok, err = load_config_file(arg, config)
      if not ok then
        return 1, "Error loading config: " .. (err or "unknown error")
      end
    elseif opt == "u" or opt == "user-agent" then
      config.user_agent = arg
    elseif opt == "?" then
      return 1, "Unknown option: " .. (arg or "")
    end
  end

  -- Get remaining URLs
  local urls = parser:remaining()
  if #urls == 0 then
    print_usage(args[0] or "webscraper.tl")
    return 1, "Error: No URLs provided"
  end

  -- Initialize database
  local db, db_err = init_database(config.database_path)
  if not db then
    return 1, "Database error: " .. (db_err or "unknown error")
  end

  if config.verbose then
    env.stdout:write("Database: " .. config.database_path .. "\n")
    env.stdout:write("Max retries: " .. tostring(config.max_retries) .. "\n")
    env.stdout:write("Scraping " .. tostring(#urls) .. " URL(s)...\n\n")
  end

  -- Scrape each URL
  local success_count = 0
  local error_count = 0

  for _, url in ipairs(urls) do
    local entry = scrape_url(url, config)

    -- Store in database
    local ok, store_err = store_in_database(db, entry)
    if not ok then
      env.stderr:write("Database error for " .. url .. ": " .. (store_err or "unknown") .. "\n")
      error_count = error_count + 1
    else
      if entry.success then
        success_count = success_count + 1
      else
        error_count = error_count + 1
      end
    end
  end

  -- Close database
  db:close()

  -- Print summary
  if config.verbose then
    env.stdout:write("\n")
  end
  env.stdout:write("Scraping complete!\n")
  env.stdout:write("  Successful: " .. tostring(success_count) .. "\n")
  env.stdout:write("  Failed: " .. tostring(error_count) .. "\n")
  env.stdout:write("  Database: " .. config.database_path .. "\n")

  return 0
end)
