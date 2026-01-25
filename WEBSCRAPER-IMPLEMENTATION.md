# Web Scraper Implementation Details

This document provides technical implementation details for the cosmic-lua web scraper.

## File Overview

- **webscraper.tl** (550 lines) - Main program implementation in Teal
- **webscraper-README.md** - User-facing documentation
- **webscraper-analyze.sh** - Database analysis helper script
- **.webscraperrc.example** - Example configuration file

## Cosmic Library Usage

The web scraper demonstrates comprehensive usage of cosmic-lua's libraries:

### 1. cosmic.fetch - HTTP Fetching with Retry

```teal
local fetch_opts: fetch.Opts = {
  max_attempts = config.max_retries,
  max_delay = config.max_delay,
  should_retry = should_retry_request,
  headers = {
    ["User-Agent"] = config.user_agent,
  },
}

local result = fetch.Fetch(url, fetch_opts)
```

**Features used:**
- Structured `Result` type with `ok`, `status`, `headers`, `body`, and `error` fields
- Custom retry logic via `should_retry` callback
- Exponential backoff with configurable maximum delay
- Custom HTTP headers (User-Agent)
- Maximum response size limiting via `maxresponse` option

**Retry strategy:**
- Retries on network errors (connection failures, timeouts)
- Retries on HTTP 5xx server errors
- Retries on HTTP 429 (rate limiting)
- Does NOT retry on client errors (4xx) except 429

### 2. cosmic.walk - Directory Tree Walking

```teal
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

    local parent = path.dirname(current_dir)
    if parent == current_dir or parent == "/" then
      break
    end
    current_dir = parent
    depth = depth + 1
  end

  return nil
end
```

**Features used:**
- Manual directory traversal for config file discovery
- Could use `walk.walk()` for recursive directory scanning
- Demonstrates integration with `unix.stat()` for file type checking

**Note:** The scraper uses manual traversal for finding config files (walking UP the tree), but the `walk` library is available for walking DOWN directory trees if needed for future features like batch URL processing from files.

### 3. cosmo.getopt - Command-line Parsing

```teal
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
  -- Handle options...
end

local urls = parser:remaining()
```

**Features used:**
- Standard getopt short options (`-h`, `-v`, `-d PATH`)
- Long option names (`--help`, `--verbose`, `--database PATH`)
- Required arguments (`:` suffix)
- Remaining non-option arguments via `parser:remaining()`
- Unknown option detection via `parser:unknown()`

### 4. cosmo.lsqlite3 - SQLite Database

```teal
-- Open database
local db = lsqlite3.open(db_path) as Database

-- Execute DDL
db:exec("CREATE TABLE IF NOT EXISTS pages (...)")

-- Prepared statements
local stmt = db:prepare("INSERT INTO pages VALUES (?, ?, ?, ?)")
stmt:bind_values(url, timestamp, success, error)
local result = stmt:step()
stmt:finalize()

-- Transactions
db:exec("BEGIN TRANSACTION;")
-- ... operations ...
db:exec("COMMIT;")

-- Get last insert ID
local page_id = db:last_insert_rowid()

-- Error handling
if result ~= lsqlite3.OK then
  local err = db:errmsg()
end
```

**Features used:**
- Database creation and schema management
- Prepared statements with parameter binding
- Transaction support for data consistency
- Foreign key constraints
- Unique constraints
- Indexes for query performance
- Error code checking (`lsqlite3.OK`, `lsqlite3.DONE`)
- Error message retrieval

**Schema design:**
- Normalized with separate `pages` and `links` tables
- Foreign key from `links.page_id` to `pages.id`
- Unique constraint on `pages.url` for idempotent scraping
- Unique constraint on `(page_id, link_url)` to prevent duplicates
- Index on `pages.url` for fast lookups

### 5. cosmo.unix - POSIX System Interfaces

```teal
-- Get current working directory
local cwd = unix.getcwd()

-- File stat (check if file exists and get type)
local stat = unix.stat(config_path)
if stat and not unix.S_ISDIR(stat:mode()) then
  -- File exists and is not a directory
end

-- Get current time
local timestamp = unix.clock_gettime(unix.CLOCK_REALTIME)

-- Sleep (used internally by fetch for retry delays)
unix.nanosleep(seconds, nanoseconds)
```

**Features used:**
- `getcwd()` for current directory
- `stat()` for file metadata
- `S_ISDIR()` for checking file types
- `clock_gettime()` for high-resolution timestamps
- Standard POSIX interfaces in a portable way

### 6. cosmo.path - Path Manipulation

```teal
-- Join path components
local config_path = path.join(current_dir, filename)

-- Get parent directory
local parent = path.dirname(current_dir)
```

**Features used:**
- `join()` for platform-independent path joining
- `dirname()` for extracting parent directory
- Handles edge cases (trailing slashes, root directory)

### 7. cosmic.init - Main Entry Point

```teal
cosmic.main(function(args: {string}, env: cosmic.Env): number, string
  -- Program logic...

  if error_occurred then
    return 1, "Error message"
  end

  return 0  -- Success
end)
```

**Features used:**
- Standard main function signature with args and env
- Exit code convention (0 = success, non-zero = error)
- Error message returned as second value
- Automatic stderr writing for error messages
- Only runs when script is executed directly (not when required as module)

## Type Safety with Teal

The program uses comprehensive type definitions:

### Custom Types

```teal
-- Database handle (from lsqlite3)
local record Database
  exec: function(self: Database, sql: string): number
  prepare: function(self: Database, sql: string): Statement
  close: function(self: Database): number
  -- ...
end

-- Prepared statement handle
local record Statement
  bind_values: function(self: Statement, ...: any): number
  step: function(self: Statement): number
  finalize: function(self: Statement): number
  -- ...
end

-- Application configuration
local record Config
  max_retries: number
  max_delay: number
  database_path: string
  config_file: string
  verbose: boolean
  user_agent: string
end

-- Scraped data
local record ScrapedEntry
  url: string
  links: {string}
  timestamp: number
  success: boolean
  error: string
end
```

### Type Casting

The program uses type assertions where necessary:

```teal
local db = lsqlite3.open(db_path) as Database
local stmt = db:prepare(sql) as Statement
```

This is required because the lsqlite3 bindings return generic types that need to be cast to the specific record types.

## Error Handling Strategy

The program implements comprehensive error handling at multiple levels:

### 1. Network Level
- Fetch errors are captured in `Result.error`
- HTTP status codes checked explicitly
- Retry logic handles transient failures

### 2. Database Level
- All SQLite operations check return codes
- Transactions ensure data consistency
- Rollback on any error within transaction
- Error messages retrieved via `db:errmsg()`

### 3. Configuration Level
- Missing config files are non-fatal
- Invalid config lines report line numbers
- Type validation for numeric values

### 4. Application Level
- Command-line argument validation
- Empty URL list detection
- Database initialization errors are fatal
- Summary statistics at end

### Error Reporting

```teal
-- Functions return (success, error_message) tuples
local function store_in_database(db: Database, entry: ScrapedEntry): boolean, string
  if error then
    return false, "Error description"
  end
  return true, nil
end

-- Errors written to stderr
if not ok then
  env.stderr:write("Error: " .. err .. "\n")
end

-- All errors tracked in database for later analysis
INSERT INTO pages (url, success, error_message)
VALUES (?, 0, 'Network timeout')
```

## Link Extraction Implementation

The link extraction uses Lua's pattern matching rather than regex for simplicity and reliability:

```teal
-- Pattern for href="..." with double quotes
for url in html:gmatch('[hH][rR][eE][fF]="(https?://[^"]+)"') do
  table.insert(links, url)
end

-- Pattern for href='...' with single quotes
for url in html:gmatch("[hH][rR][eE][fF]='(https?://[^']+)'") do
  table.insert(links, url)
end
```

**Why Lua patterns instead of POSIX regex?**
1. Built-in to Lua, no external dependency
2. More predictable for HTML parsing
3. Simpler pattern syntax for this use case
4. Better performance for this specific task

**Limitations:**
- Doesn't handle relative URLs (by design)
- Doesn't handle unquoted attributes
- Doesn't handle HTML entities in URLs
- Not a full HTML parser (intentionally)

**URL filtering:**
- Only extracts `http://` and `https://` URLs
- Deduplicates within each page using `seen` table
- Case-insensitive attribute matching

## Configuration Precedence

Settings are loaded in this order (later overrides earlier):

1. **Default values** (hardcoded in `DEFAULT_CONFIG`)
2. **Config file** (`.webscraperrc` found via directory walk)
3. **Explicit config file** (`-c` option)
4. **Command-line options** (highest priority)

Example:
```
DEFAULT: max_retries=3
.webscraperrc: max_retries=5
Command-line: -r 10

Result: max_retries=10
```

## Database Schema Rationale

### Why two tables?

Separating pages and links allows:
- Efficient querying of links per page
- Deduplication of links per page
- Future features like link metadata
- Better normalization (no repeated data)

### Why timestamps?

Unix timestamps enable:
- Tracking when pages were last scraped
- Implementing refresh logic
- Analyzing scraping patterns over time
- Time-based queries

### Why success flag?

Boolean flag allows:
- Quick filtering of successful scrapes
- Separate queries for errors vs. successes
- Retry logic based on previous attempts

## Performance Considerations

### Current Implementation

- **Sequential scraping**: URLs scraped one at a time
- **In-memory link storage**: All links for a page held in memory
- **Single transaction per page**: One transaction wraps page + all links
- **Prepared statement reuse**: Link insertion uses single prepared statement

### Bottlenecks

1. **Network I/O**: Primary bottleneck, mitigated by retry logic
2. **HTML parsing**: Lua pattern matching is fast
3. **Database writes**: Minimal due to efficient schema

### Scalability

**Current limits:**
- Memory: Scales with largest HTML page size and link count
- Storage: SQLite handles millions of rows efficiently
- Time: Linear with number of URLs (sequential processing)

**For large-scale scraping, consider:**
- Parallel processing with multiple cosmic processes
- Batch URL processing
- Response body streaming (don't hold full HTML in memory)
- Connection pooling (currently opens new connection per URL)

## Testing Recommendations

### Unit Testing

Test individual functions:
- `extract_links()` with various HTML inputs
- `find_config_file()` with different directory structures
- `should_retry_request()` with different status codes

### Integration Testing

Test complete workflows:
- Scraping a local test server
- Config file loading and precedence
- Database schema creation
- Transaction rollback on errors

### Error Testing

Test error conditions:
- Network timeouts
- Invalid URLs
- Database write failures
- Invalid config files
- Missing command-line arguments

## Extension Points

The program is designed to be extensible:

### 1. Custom Link Extraction
Replace `extract_links()` with a more sophisticated HTML parser:
```teal
local function extract_links_advanced(html: string): {string}
  -- Use a proper HTML parser library
  -- Extract metadata (link text, title, etc.)
  -- Handle relative URLs with base tag
end
```

### 2. Content Storage
Store full HTML in database:
```sql
ALTER TABLE pages ADD COLUMN content TEXT;
```

### 3. Recursive Crawling
Add crawl depth and breadth limits:
```teal
local function crawl_recursive(start_url: string, max_depth: number)
  -- Queue-based crawling
  -- Respect robots.txt
  -- Domain-specific rate limiting
end
```

### 4. Authentication
Add auth support to fetch options:
```teal
fetch_opts.headers["Authorization"] = "Bearer " .. token
```

### 5. Content-Type Filtering
Only scrape HTML pages:
```teal
if result.headers["content-type"]:match("text/html") then
  -- Extract links
end
```

## Production Deployment

For production use, consider:

1. **Logging**: Add structured logging with timestamps
2. **Monitoring**: Track success/failure rates
3. **Rate Limiting**: Respect server resources
4. **User-Agent**: Provide contact information
5. **robots.txt**: Check before scraping
6. **Error Alerting**: Notify on repeated failures
7. **Resource Limits**: Use `unix.setrlimit` for safety
8. **Database Backups**: Regular SQLite backup
9. **Timeout Configuration**: Reasonable fetch timeouts
10. **Legal Compliance**: Respect terms of service

## Conclusion

This web scraper demonstrates production-quality code with:
- ✅ Comprehensive error handling
- ✅ Type safety with Teal
- ✅ Proper use of cosmic libraries
- ✅ Configuration management
- ✅ Database transactions
- ✅ Retry logic
- ✅ CLI argument parsing
- ✅ Documentation and examples
- ✅ Extensible architecture
- ✅ Performance considerations

It serves as both a useful utility and a reference implementation for cosmic-lua development.
