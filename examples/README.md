# cosmic-lua Examples

Complete, runnable example programs demonstrating cosmic-lua features.

## Quick Start

Run any example:

```bash
./cosmic-lua examples/hello.tl
./cosmic-lua examples/fetch-url.tl https://example.com
./cosmic-lua examples/run-command.tl ls -la
```

Or make them executable:

```bash
chmod +x examples/*.tl
./examples/hello.tl
```

## Examples

### 1. hello.tl
**Minimal cosmic program**

The simplest possible cosmic-lua program. Shows the basic entry point pattern.

```bash
./cosmic-lua examples/hello.tl
```

**Demonstrates**:
- `cosmic.main()` entry point
- Accessing stdout via `env`
- Returning exit codes

**Lines**: ~20

---

### 2. fetch-url.tl
**Simple HTTP client**

Fetch a URL and display status, headers, and body preview.

```bash
./cosmic-lua examples/fetch-url.tl https://example.com
```

**Demonstrates**:
- HTTP fetching with `cosmic.fetch`
- Error handling
- Command-line arguments
- Accessing response status/headers/body

**Lines**: ~40

---

### 3. run-command.tl
**Process spawning**

Run any command and capture its output.

```bash
./cosmic-lua examples/run-command.tl ls -la
./cosmic-lua examples/run-command.tl git status
./cosmic-lua examples/run-command.tl echo "Hello, World!"
```

**Demonstrates**:
- Process spawning with `cosmic.spawn`
- Capturing stdout
- Exit code handling
- Dynamic command arrays

**Lines**: ~45

---

### 4. find-files.tl
**File searching**

Find files matching a Lua pattern.

```bash
./cosmic-lua examples/find-files.tl              # Find .tl files
./cosmic-lua examples/find-files.tl "%.lua$"     # Find .lua files
./cosmic-lua examples/find-files.tl "test"       # Files containing "test"
./cosmic-lua examples/find-files.tl "%.md$" lib  # Find .md files in lib/
```

**Demonstrates**:
- Directory walking with `cosmic.walk`
- Lua pattern matching
- File collection

**Lines**: ~35

---

### 5. database.tl
**SQLite database operations**

Create database, insert data, query results.

```bash
./cosmic-lua examples/database.tl
# Creates example.db
```

**Demonstrates**:
- Opening SQLite database with `cosmo.lsqlite3`
- Creating tables
- Prepared statements
- Inserting data
- Querying with callbacks
- Error handling
- Resource cleanup

**Lines**: ~90

---

### 6. cli-args.tl
**Command-line argument parsing**

Parse short and long options with getopt.

```bash
./cosmic-lua examples/cli-args.tl --help
./cosmic-lua examples/cli-args.tl -v -o output.txt file1.txt file2.txt
./cosmic-lua examples/cli-args.tl --verbose --output=out.txt --count=3 file.txt
```

**Demonstrates**:
- Short options (`-v`, `-o FILE`)
- Long options (`--verbose`, `--output=FILE`)
- Required vs optional arguments
- Help text generation
- Remaining non-option arguments

**Lines**: ~80

---

## Learning Path

**Complete beginner**:
1. Start with `hello.tl` - understand the basic structure
2. Try `fetch-url.tl` - see how to use a library
3. Run `run-command.tl` - learn process spawning

**Building real programs**:
1. Study `cli-args.tl` - learn proper CLI handling
2. Review `database.tl` - understand data persistence
3. Examine `find-files.tl` - see directory traversal

**Advanced topics**:
- Read the source code in `lib/cosmic/*.tl`
- Check test files in `lib/cosmic/*_test.tl`
- See the web scraper: `webscraper.tl`

## Next Steps

After exploring these examples:

1. **Read the Quick Start**: [QUICKSTART.md](../QUICKSTART.md)
2. **API Reference**: [API-REFERENCE.md](../API-REFERENCE.md)
3. **Build your own program**: Combine these patterns for your use case

## Tips

- **Make examples executable**:
  ```bash
  chmod +x examples/*.tl
  ./examples/hello.tl
  ```

- **Run with Teal type checking**:
  ```bash
  ./cosmic-lua /zip/tl.lua check examples/database.tl
  ```

- **Modify and experiment**:
  - Copy an example and adapt it
  - Mix features from multiple examples
  - Add error handling, logging, etc.

## Common Patterns

These examples demonstrate common patterns you'll use:

| Pattern | Example | Shows |
|---------|---------|-------|
| Entry point | hello.tl | cosmic.main() usage |
| Error handling | All examples | Return codes and error messages |
| CLI args | cli-args.tl | getopt parsing |
| HTTP | fetch-url.tl | URL fetching |
| Process | run-command.tl | Spawning commands |
| Files | find-files.tl | Directory walking |
| Database | database.tl | SQLite operations |

## Example Sizes

All examples are intentionally small (<100 lines) to be easy to understand:

| File | Lines | Complexity |
|------|-------|------------|
| hello.tl | ~20 | Trivial |
| fetch-url.tl | ~40 | Simple |
| find-files.tl | ~35 | Simple |
| run-command.tl | ~45 | Simple |
| cli-args.tl | ~80 | Medium |
| database.tl | ~90 | Medium |

For a more complex, production-quality example, see `webscraper.tl` (~550 lines).

## Troubleshooting

**"cosmic-lua: command not found"**
- Build cosmic: `make cosmic` (creates `o/cosmic`)
- Or download from releases

**"No such file or directory"**
- Run from repo root: `./cosmic-lua examples/hello.tl`
- Or use absolute path

**Type errors**
- Check your Teal syntax
- Run type checker: `./cosmic-lua /zip/tl.lua check <file>`

## Contributing

Have a good example? Contributions welcome!

Guidelines:
- Keep it under 100 lines
- Add inline comments
- Include usage examples in header
- Follow the existing style
- Demonstrate one main feature

## License

MIT License - same as cosmic-lua
