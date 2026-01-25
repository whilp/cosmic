#!/bin/bash
# Helper script to analyze scraped data from the web scraper database

DB_PATH="${1:-scraper.db}"

if [ ! -f "$DB_PATH" ]; then
    echo "Error: Database file not found: $DB_PATH"
    echo "Usage: $0 [database_path]"
    exit 1
fi

echo "=== Web Scraper Database Analysis ==="
echo "Database: $DB_PATH"
echo ""

# Total pages scraped
echo "--- Summary Statistics ---"
TOTAL=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM pages;")
SUCCESSFUL=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM pages WHERE success = 1;")
FAILED=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM pages WHERE success = 0;")
TOTAL_LINKS=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM links;")

echo "Total pages scraped: $TOTAL"
echo "Successful fetches: $SUCCESSFUL"
echo "Failed fetches: $FAILED"
echo "Total links extracted: $TOTAL_LINKS"
echo ""

# Most recent scrapes
echo "--- Recent Scrapes (Last 5) ---"
sqlite3 -header -column "$DB_PATH" "
SELECT
    url,
    datetime(fetch_timestamp, 'unixepoch') as fetched,
    CASE WHEN success = 1 THEN 'OK' ELSE 'FAILED' END as status
FROM pages
ORDER BY fetch_timestamp DESC
LIMIT 5;
"
echo ""

# Link counts per page
echo "--- Link Counts Per Page ---"
sqlite3 -header -column "$DB_PATH" "
SELECT
    p.url,
    COUNT(l.id) as links
FROM pages p
LEFT JOIN links l ON p.id = l.page_id
WHERE p.success = 1
GROUP BY p.url
ORDER BY links DESC
LIMIT 10;
"
echo ""

# Failed fetches with errors
if [ "$FAILED" -gt 0 ]; then
    echo "--- Failed Fetches ---"
    sqlite3 -header -column "$DB_PATH" "
    SELECT
        url,
        error_message
    FROM pages
    WHERE success = 0
    LIMIT 10;
    "
    echo ""
fi

# Most common domains in extracted links
echo "--- Top 10 Linked Domains ---"
sqlite3 -header -column "$DB_PATH" "
WITH domain_counts AS (
    SELECT
        CASE
            WHEN link_url LIKE 'http://%' THEN substr(link_url, 8, instr(substr(link_url, 8), '/') - 1)
            WHEN link_url LIKE 'https://%' THEN substr(link_url, 9, instr(substr(link_url, 9), '/') - 1)
            ELSE link_url
        END as domain,
        COUNT(*) as count
    FROM links
    GROUP BY domain
)
SELECT domain, count
FROM domain_counts
ORDER BY count DESC
LIMIT 10;
"
echo ""

echo "=== Analysis Complete ==="
echo ""
echo "For custom queries, use: sqlite3 $DB_PATH"
echo "Example: sqlite3 $DB_PATH 'SELECT * FROM pages;'"
