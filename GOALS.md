# Project Goals

cosmic-lua aims to be the definitive portable scripting platform. These goals are ambitious and measurable—an agent should be able to verify each criterion and identify work needed to meet it.

## 1. Upstream Integration

**Goal**: cosmic-lua becomes part of the upstream [Cosmopolitan Libc](https://github.com/jart/cosmopolitan) project.

**Verification Criteria**:
- [ ] All code follows Cosmopolitan code style and conventions
- [ ] No external dependencies beyond what Cosmopolitan provides
- [ ] Build system integrates cleanly with Cosmopolitan's Makefile infrastructure
- [ ] All features work correctly with `MODE=` build variants (tiny, opt, dbg, etc.)
- [ ] Documentation matches Cosmopolitan's standards (man-page style, examples)
- [ ] Test suite passes under Cosmopolitan's CI infrastructure
- [ ] Upstream maintainer (@jart) has reviewed and accepted the integration plan

**To Assess**: Check if code style matches `cosmopolitan/tool/` conventions; verify no `curl` or external fetches in build; ensure tests pass with `MODE=tiny`.

---

## 2. Agent Intuition

**Goal**: An AI agent with no prior knowledge of cosmic-lua can learn the entire API and write correct programs within a single conversation, using only the embedded documentation and type definitions.

**Verification Criteria**:
- [ ] `--help` shows all available modules with one-line descriptions
- [ ] `--docs <query>` returns accurate, complete documentation for any public API
- [ ] Every public function has a doc comment explaining purpose, parameters, return values, and at least one example
- [ ] Every module has a top-level doc comment explaining when to use it
- [ ] Type definitions (`*.d.tl`) are complete and accurate—no `any` types except where unavoidable
- [ ] Error messages include actionable suggestions (e.g., "did you mean X?")
- [ ] Common tasks have discoverable recipes (agent can find how to do X by searching docs)
- [ ] The `CLAUDE.md` file provides sufficient context for an agent to understand project structure and conventions

**To Assess**: Have a fresh agent attempt these tasks using only `--docs` and type definitions:
1. Fetch a URL and parse JSON response
2. Spawn a subprocess and capture output
3. Walk a directory tree matching a glob pattern
4. Read/write a SQLite database
5. Parse command-line arguments
6. Create a ZIP archive

If the agent succeeds without external help, this goal is met.

---

## 3. Comprehensive Coverage

**Goal**: cosmic-lua exposes 100% of Cosmopolitan Libc's Lua-accessible functionality and provides batteries-included modules for common programming tasks.

### 3a. Cosmopolitan Libc Coverage

**Verification Criteria**:
- [ ] All functions in `cosmopolitan.h` that can be bound to Lua are bound
- [ ] All constants (errnos, signals, flags) are accessible from Lua
- [ ] Shared memory operations (futexes, atomics) are fully exposed
- [ ] Network operations (sockets, DNS, TLS) are fully exposed
- [ ] File operations (including `openat`, `*at` family) are fully exposed
- [ ] Process operations (fork, exec, wait, signals) are fully exposed
- [ ] Memory mapping (`mmap`, `munmap`, `mprotect`) is exposed
- [ ] Sandbox operations (pledge, landlock) are exposed

**To Assess**: Run `lib/types/gentype.tl` against cosmos and compare output to `lib/types/cosmo.d.tl`; any missing functions indicate gaps.

### 3b. Batteries Included

**Verification Criteria**:
- [ ] **HTTP client**: GET/POST/PUT/DELETE with headers, auth, redirects, timeouts, retry
- [ ] **HTTP server**: Listen, route, serve static files, handle WebSockets
- [ ] **JSON**: Parse and serialize (already have)
- [ ] **YAML**: Parse and serialize
- [ ] **TOML**: Parse and serialize
- [ ] **CSV**: Parse and serialize
- [ ] **Base64**: Encode and decode
- [ ] **URL**: Parse, build, encode/decode components
- [ ] **HTML/XML**: Parse and query (basic DOM or SAX)
- [ ] **Markdown**: Parse and render to HTML
- [ ] **Templates**: String templating engine
- [ ] **Regular expressions**: POSIX extended (have), PCRE-compatible
- [ ] **Date/time**: Parse, format, arithmetic, timezones
- [ ] **UUID**: Generate v4 and v7
- [ ] **Crypto**: Hash (SHA256, SHA512, BLAKE3), HMAC, AES, RSA, ECDSA
- [ ] **Compression**: gzip, zstd, brotli
- [ ] **Archive**: ZIP (have), tar
- [ ] **Database**: SQLite (have), connection pooling
- [ ] **Process**: Spawn with pipes, PTY support, signal handling
- [ ] **Async**: Coroutine-based event loop, timers, sleep
- [ ] **CLI**: Argument parsing (have), colored output, progress bars
- [ ] **Logging**: Structured logging with levels, formatters, outputs
- [ ] **Testing**: Assertions, mocks, fixtures, coverage
- [ ] **Diff**: Unified diff generation and patching

**To Assess**: For each category, check if `require("cosmic.<module>")` or `require("cosmo.<module>")` provides the functionality; missing items indicate work needed.

---

## 4. Safety

**Goal**: cosmic-lua makes it difficult to write incorrect programs through static type checking, runtime validation, and safe-by-default APIs.

**Verification Criteria**:
- [ ] `make check` (Teal type checking) passes with zero warnings in strict mode
- [ ] All public APIs have complete Teal type definitions—no `any` escape hatches
- [ ] Functions that can fail return `Result<T, E>` pattern (value + error) rather than throwing
- [ ] Resource handles (files, sockets, databases) use RAII patterns with `__close` metamethods
- [ ] Memory-unsafe operations (raw pointers, mmap) are clearly marked and isolated
- [ ] Input validation happens at API boundaries with clear error messages
- [ ] No global mutable state in library code
- [ ] Concurrent code uses atomic operations correctly (no data races possible)
- [ ] Security-sensitive functions (crypto, auth) follow best practices (constant-time comparison, secure defaults)

**To Assess**:
1. Run `make check` and verify zero warnings/errors
2. Grep for `any` in `.d.tl` files—each instance needs justification
3. Review `__close` metamethod usage for all handle types
4. Verify error handling patterns in public APIs

---

## 5. Performance

**Goal**: cosmic-lua performs within 2x of equivalent C code for compute-bound tasks and within 10% for I/O-bound tasks.

**Verification Criteria**:
- [ ] Benchmarks exist for all core operations (spawn, fetch, walk, sqlite, zip)
- [ ] Benchmarks compare against equivalent C/shell implementations
- [ ] `make benchmark` runs all benchmarks and reports results
- [ ] No benchmark shows >2x slowdown vs C for compute-bound work
- [ ] No benchmark shows >10% slowdown vs C for I/O-bound work
- [ ] Memory usage is within 2x of equivalent C programs
- [ ] Startup time is <50ms on commodity hardware
- [ ] Large file operations (>1GB) don't cause memory issues (streaming)

**To Assess**:
1. Run `make benchmark` and review output
2. Compare spawn.run vs `/bin/sh -c` for equivalent commands
3. Compare fetch vs curl for equivalent requests
4. Compare walk vs `find` for equivalent traversals
5. Profile memory usage for representative workloads

---

## 6. Reliability

**Goal**: cosmic-lua is production-ready with comprehensive documentation, thorough testing, and predictable behavior.

**Verification Criteria**:

### Documentation
- [ ] Every public module has a README with overview, examples, and API reference
- [ ] Every public function has doc comments with parameters, returns, errors, examples
- [ ] All type definitions have doc comments explaining semantics
- [ ] CHANGELOG tracks all user-visible changes with migration guides
- [ ] Architecture document explains design decisions and trade-offs

### Testing
- [ ] Line coverage >90% for all library code
- [ ] Every public function has at least one test
- [ ] Every public function has at least one example (Go-style `Example_*`)
- [ ] Edge cases are tested (empty input, nil, huge input, unicode, concurrent access)
- [ ] Integration tests verify end-to-end workflows
- [ ] Fuzz tests exist for parsers and input handling
- [ ] Tests pass on all supported platforms (Linux, macOS, Windows, FreeBSD, OpenBSD, NetBSD)

### Stability
- [ ] Semantic versioning with clear compatibility guarantees
- [ ] Deprecation warnings before breaking changes
- [ ] CI runs on every PR with all tests, type checking, and benchmarks
- [ ] Releases are automated with signed checksums
- [ ] No known bugs in the issue tracker for >30 days

**To Assess**:
1. Run `make ci` and verify all checks pass
2. Check coverage report for >90% threshold
3. Run `make example` and verify all examples pass
4. Review open issues for staleness
5. Verify CI runs on each supported platform
