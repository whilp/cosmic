# Web Scraper - A cosmic-lua Utility

A production-quality web scraper built with cosmic-lua that fetches content from URLs, extracts links, and stores them in a SQLite database with automatic retry logic and comprehensive error handling.

## Features

- **HTTP/HTTPS Fetching**: Uses cosmic's `fetch` library with automatic retry logic for failed requests
- **Link Extraction**: Extracts all `href` and `src` attributes containing HTTP/HTTPS URLs from HTML content
- **SQLite Storage**: Stores scraped data in a structured SQLite database with proper schema
- **Configuration Files**: Supports `.webscraperrc` configuration files with automatic directory traversal
- **Error Handling**: Comprehensive error handling with detailed error messages
- **Retry Logic**: Automatic retry for network errors, server errors (5xx), and rate limiting (429)
- **Type Safety**: Written in Teal for compile-time type checking
- **Command-line Interface**: Full-featured CLI with getopt-style argument parsing

## Requirements

- cosmic-lua binary (built from this repository)
- No external dependencies - everything is bundled in cosmic

## Building cosmic-lua

```bash
cd /home/user/cosmic
make cosmic
```

This will create the `cosmic-lua` binary in the output directory.

## Usage

### Basic Usage

```bash
# Scrape a single URL
./cosmic-lua webscraper.tl https://example.com

# Scrape multiple URLs
./cosmic-lua webscraper.tl https://example.com https://example.org https://example.net

# Enable verbose output
./cosmic-lua webscraper.tl -v https://example.com

# Use custom database path
./cosmic-lua webscraper.tl -d data/scraper.db https://example.com

# Set maximum retry attempts
./cosmic-lua webscraper.tl -r 5 https://example.com

# Use custom User-Agent
./cosmic-lua webscraper.tl -u "MyBot/1.0" https://example.com
```

### Command-line Options

- `-h, --help` - Show help message
- `-v, --verbose` - Enable verbose output with detailed progress information
- `-d, --database PATH` - Specify database file path (default: `scraper.db`)
- `-r, --retries N` - Set maximum retry attempts (default: 3)
- `-c, --config FILE` - Load configuration from specified file
- `-u, --user-agent UA` - Set custom User-Agent string

### Configuration File

The scraper automatically searches for a `.webscraperrc` file in the current directory and parent directories (up to 10 levels). You can also specify a config file explicitly with the `-c` option.

**Example `.webscraperrc` file:**

```ini
# Maximum number of retry attempts for failed requests
max_retries=5

# Maximum delay between retries in seconds
max_delay=60

# Path to SQLite database file
database_path=./data/scraper.db

# Custom User-Agent string
user_agent=MyWebScraper/1.0 (+https://example.com/bot)
```

Configuration file format:
- Lines starting with `#` are comments
- Empty lines are ignored
- Format: `key=value`
- Command-line options override config file settings

## Database Schema

The scraper creates a SQLite database with two tables:

### `pages` Table

Stores information about each scraped page:

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER | Primary key (auto-increment) |
| url | TEXT | The URL that was scraped (unique) |
| fetch_timestamp | INTEGER | Unix timestamp of when the page was fetched |
| success | INTEGER | 1 if fetch was successful, 0 if failed |
| error_message | TEXT | Error message if fetch failed, NULL otherwise |

### `links` Table

Stores all links extracted from each page:

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER | Primary key (auto-increment) |
| page_id | INTEGER | Foreign key to pages.id |
| link_url | TEXT | The extracted link URL |

Constraints:
- `UNIQUE(page_id, link_url)` - Prevents duplicate links per page
- Foreign key constraint maintains referential integrity
- Index on `pages.url` for fast lookups

## Retry Logic

The scraper automatically retries failed requests in the following cases:

1. **Network Errors**: Connection failures, timeouts, DNS errors
2. **Server Errors**: HTTP status codes 500-599
3. **Rate Limiting**: HTTP status code 429

Retry behavior:
- Exponential backoff: waits 2^n seconds between attempts (up to `max_delay`)
- Configurable maximum attempts via `-r` flag or `max_retries` config
- Failed requests are still recorded in the database with error details

## Link Extraction

The scraper extracts URLs from the following HTML attributes:
- `href="https://..."` - Links in anchor tags, link tags, etc.
- `href='https://...'` - Single-quoted href attributes
- `src="https://..."` - Image sources, script sources, etc.
- `src='https://...'` - Single-quoted src attributes

Only HTTP and HTTPS URLs are extracted. Relative URLs, mailto: links, javascript: links, and other protocols are ignored.

## Error Handling

The scraper provides comprehensive error handling:

1. **Network Errors**: Captured and logged with retry attempts
2. **HTTP Errors**: Non-200 status codes are logged as failures
3. **Database Errors**: All database operations check return codes
4. **Configuration Errors**: Invalid config files report line numbers
5. **Argument Errors**: Invalid CLI arguments show usage information

All errors are:
- Logged to stderr
- Stored in the database (for fetch errors)
- Reported in the final summary

## Examples

### Example 1: Basic Scraping

```bash
./cosmic-lua webscraper.tl https://example.com
```

Output:
```
Scraping complete!
  Successful: 1
  Failed: 0
  Database: scraper.db
```

### Example 2: Verbose Scraping with Multiple URLs

```bash
./cosmic-lua webscraper.tl -v \
  https://example.com \
  https://example.org \
  https://example.net
```

Output:
```
Database: scraper.db
Max retries: 3
Scraping 3 URL(s)...

Fetching: https://example.com
  Found 47 links
Fetching: https://example.org
  Found 23 links
Fetching: https://example.net
  Found 31 links

Scraping complete!
  Successful: 3
  Failed: 0
  Database: scraper.db
```

### Example 3: Custom Configuration

Create `.webscraperrc`:
```ini
max_retries=5
database_path=./data/scraper.db
user_agent=ResearchBot/1.0 (+https://mysite.com/bot)
```

Run scraper:
```bash
./cosmic-lua webscraper.tl -v https://example.com
```

### Example 4: Querying the Database

After scraping, you can query the database using SQLite:

```bash
# Show all successfully scraped pages
sqlite3 scraper.db "SELECT url, datetime(fetch_timestamp, 'unixepoch') as fetched FROM pages WHERE success = 1;"

# Count links per page
sqlite3 scraper.db "SELECT p.url, COUNT(l.id) as link_count FROM pages p LEFT JOIN links l ON p.id = l.page_id GROUP BY p.url;"

# Find all unique domains linked from a page
sqlite3 scraper.db "SELECT DISTINCT substr(link_url, 1, instr(substr(link_url, 9), '/') + 7) as domain FROM links WHERE page_id = 1;"

# Show failed fetches with error messages
sqlite3 scraper.db "SELECT url, error_message FROM pages WHERE success = 0;"
```

## Architecture

The scraper is organized into several key components:

1. **Configuration Management**: Loads settings from config files and CLI arguments
2. **Database Layer**: Initializes schema and provides transactional storage
3. **Fetching Layer**: Uses cosmic.fetch with retry logic and custom headers
4. **Parsing Layer**: Extracts links using Lua pattern matching
5. **CLI Layer**: Parses arguments with getopt and provides user-friendly interface

### Type Safety

The program is written in Teal and includes complete type definitions for:
- SQLite database handles and statements
- Configuration structures
- Scraped data entries
- Fetch results and options

### Dependencies

All dependencies are bundled with cosmic-lua:
- `cosmic` - Core utilities and main entry point
- `cosmic.fetch` - HTTP fetching with retry logic
- `cosmic.walk` - Directory tree walking for config files
- `cosmo.getopt` - Command-line argument parsing
- `cosmo.lsqlite3` - SQLite database bindings
- `cosmo.unix` - POSIX system interfaces (stat, clock_gettime, etc.)
- `cosmo.path` - Path manipulation utilities

## Limitations

- Only scrapes HTML content (doesn't parse JavaScript-rendered pages)
- No authentication support (basic sites only)
- No cookie handling
- Single-threaded (scrapes URLs sequentially)
- Pattern-based link extraction (not a full HTML parser)

## Future Enhancements

Possible improvements:
- Parallel scraping with process pooling
- robots.txt compliance checking
- Sitemap.xml parsing
- HTTP authentication support
- Cookie jar for session management
- Content-Type filtering
- Response body storage (not just links)
- Recursive crawling with depth limits
- Rate limiting per domain
- Proxy support

## License

Same as cosmic-lua (MIT License).

## Contributing

This is an example utility program demonstrating cosmic-lua capabilities. Feel free to extend it for your own use cases.
