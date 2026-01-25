# Web Scraper Quick Start Guide

A comprehensive web scraper built with cosmic-lua demonstrating all major cosmic libraries.

## Quick Install

```bash
cd /home/user/cosmic
make cosmic  # Build cosmic-lua binary
```

## Quick Usage

```bash
# Basic scraping
./cosmic-lua webscraper.tl https://example.com

# Verbose mode with custom database
./cosmic-lua webscraper.tl -v -d mydata.db https://example.com

# Multiple URLs with retry
./cosmic-lua webscraper.tl -r 5 https://example.com https://example.org

# Analyze results
./webscraper-analyze.sh mydata.db
```

## Files in This Package

| File | Purpose | Lines |
|------|---------|-------|
| `webscraper.tl` | Main program (Teal source) | 550 |
| `webscraper-README.md` | User documentation | 291 |
| `WEBSCRAPER-IMPLEMENTATION.md` | Technical details | 519 |
| `webscraper-analyze.sh` | Database analysis helper | 92 |
| `.webscraperrc.example` | Example config file | 19 |

## cosmic-lua Libraries Demonstrated

### Core Libraries

- **cosmic.fetch** - HTTP requests with automatic retry
- **cosmic.walk** - Directory tree traversal
- **cosmic.init** - Program entry point and exit handling

### cosmo Bindings

- **cosmo.getopt** - Command-line argument parsing
- **cosmo.lsqlite3** - SQLite database access
- **cosmo.unix** - POSIX system calls (stat, getcwd, clock_gettime)
- **cosmo.path** - Path manipulation utilities

## Feature Highlights

✅ **Retry Logic**: Automatic retry for network and server errors
✅ **SQLite Storage**: Normalized schema with transactions
✅ **Config Files**: Automatic discovery via directory walking
✅ **Type Safety**: Full Teal type definitions
✅ **Error Handling**: Comprehensive error tracking and reporting
✅ **CLI**: Professional command-line interface with help

## Example Session

```bash
# Create config file
cat > .webscraperrc << EOF
max_retries=5
database_path=./scraper.db
user_agent=MyBot/1.0
EOF

# Scrape some URLs
./cosmic-lua webscraper.tl -v \
  https://example.com \
  https://example.org

# Output:
# Loaded config from: /home/user/cosmic/.webscraperrc
# Database: ./scraper.db
# Max retries: 5
# Scraping 2 URL(s)...
#
# Fetching: https://example.com
#   Found 47 links
# Fetching: https://example.org
#   Found 23 links
#
# Scraping complete!
#   Successful: 2
#   Failed: 0
#   Database: ./scraper.db

# Analyze the data
./webscraper-analyze.sh scraper.db

# Query directly
sqlite3 scraper.db "SELECT url, COUNT(*) FROM pages JOIN links ON pages.id = links.page_id GROUP BY url;"
```

## Database Schema

```sql
-- Pages table
CREATE TABLE pages (
    id INTEGER PRIMARY KEY,
    url TEXT UNIQUE,
    fetch_timestamp INTEGER,
    success INTEGER,
    error_message TEXT
);

-- Links table
CREATE TABLE links (
    id INTEGER PRIMARY KEY,
    page_id INTEGER,
    link_url TEXT,
    FOREIGN KEY (page_id) REFERENCES pages(id),
    UNIQUE(page_id, link_url)
);
```

## Common Tasks

### Scrape and View Results

```bash
# Scrape
./cosmic-lua webscraper.tl https://news.ycombinator.com

# View pages
sqlite3 scraper.db "SELECT * FROM pages;"

# Count links
sqlite3 scraper.db "SELECT COUNT(*) FROM links;"

# Top linked domains
sqlite3 scraper.db "SELECT link_url, COUNT(*) as c FROM links GROUP BY link_url ORDER BY c DESC LIMIT 10;"
```

### Batch Processing

```bash
# Create URL list
cat > urls.txt << EOF
https://example.com
https://example.org
https://example.net
EOF

# Scrape all (passing URLs as arguments)
./cosmic-lua webscraper.tl $(cat urls.txt)
```

### Error Investigation

```bash
# Show failed fetches
sqlite3 scraper.db "SELECT url, error_message FROM pages WHERE success = 0;"

# Retry failed URLs
./cosmic-lua webscraper.tl -r 10 $(sqlite3 scraper.db "SELECT url FROM pages WHERE success = 0;")
```

## Configuration Options

### Command-line

| Option | Long | Argument | Description |
|--------|------|----------|-------------|
| `-h` | `--help` | None | Show help message |
| `-v` | `--verbose` | None | Enable verbose output |
| `-d` | `--database` | PATH | Database file path |
| `-r` | `--retries` | N | Max retry attempts |
| `-c` | `--config` | FILE | Config file path |
| `-u` | `--user-agent` | UA | Custom User-Agent |

### Config File (.webscraperrc)

```ini
# Retry settings
max_retries=5
max_delay=60

# Database
database_path=./data/scraper.db

# HTTP headers
user_agent=MyBot/1.0 (+https://example.com/bot)
```

## cosmic Libraries API Quick Reference

### cosmic.fetch

```teal
local result = fetch.Fetch(url, {
  max_attempts = 3,
  max_delay = 30,
  should_retry = function(r) return r.status >= 500 end,
  headers = { ["User-Agent"] = "Bot/1.0" }
})

if result.ok then
  print(result.status, result.body)
else
  print(result.error)
end
```

### cosmo.getopt

```teal
local parser = getopt.new(args, "hv:", {
  {"help", "none", "h"},
  {"value", "required", "v"}
})

while true do
  local opt, arg = parser:next()
  if not opt then break end
  -- Handle opt
end

local remaining = parser:remaining()
```

### cosmo.lsqlite3

```teal
local db = lsqlite3.open("data.db")
db:exec("CREATE TABLE IF NOT EXISTS t (id INTEGER, name TEXT)")

local stmt = db:prepare("INSERT INTO t VALUES (?, ?)")
stmt:bind_values(1, "test")
stmt:step()
stmt:finalize()

db:close()
```

### cosmic.walk

```teal
walk.walk("/path", function(full_path, name, stat, ctx)
  if not unix.S_ISDIR(stat:mode()) then
    print("File:", full_path)
  end
  return true  -- continue recursion
end)

-- Or collect files matching pattern
local lua_files = walk.collect("/path", "%.lua$")
```

### cosmo.unix

```teal
-- Get current directory
local cwd = unix.getcwd()

-- File info
local stat = unix.stat("/path/file")
if stat and unix.S_ISREG(stat:mode()) then
  print("File size:", stat:size())
end

-- Timestamp
local now = unix.clock_gettime(unix.CLOCK_REALTIME)
```

### cosmo.path

```teal
-- Join paths
local p = path.join("/home", "user", "file.txt")
-- Result: /home/user/file.txt

-- Get directory
local dir = path.dirname("/home/user/file.txt")
-- Result: /home/user

-- Get basename
local name = path.basename("/home/user/file.txt")
-- Result: file.txt
```

## Next Steps

1. **Read** `webscraper-README.md` for detailed usage
2. **Study** `WEBSCRAPER-IMPLEMENTATION.md` for technical details
3. **Examine** `webscraper.tl` source code
4. **Experiment** with different URLs and settings
5. **Extend** with your own features

## License

MIT License (same as cosmic-lua)

## Support

For issues or questions about cosmic-lua libraries:
- GitHub: https://github.com/whilp/cosmic
- Documentation: See lib/cosmic/ and lib/types/cosmo/ directories
