# cosmic-lua

A cosmopolitan Lua distribution with Teal support and bundled libraries.

## Overview

`cosmic-lua` is a single-file, self-contained Lua interpreter built on [Cosmopolitan Libc](https://github.com/jart/cosmopolitan) that runs on Linux, macOS, Windows, FreeBSD, OpenBSD, and NetBSD without requiring installation or dependencies.

It includes:
- **Lua 5.4**: Full Lua interpreter
- **Teal**: A typed dialect of Lua that compiles to Lua
- **cosmic library**: Core utilities for file operations, process spawning, HTTP fetching, and directory walking
- **Type definitions**: Complete type declarations for the Cosmopolitan Lua API

## Features

- **Actually Portable Executable**: Single binary runs on multiple platforms
- **No Installation Required**: Download and run
- **Teal Support**: Full integration with the Teal type checker and compiler
- **Self-Contained**: All dependencies bundled in the executable

## Installation

Download the latest release:

```bash
curl -L -o cosmic-lua https://github.com/whilp/cosmic/releases/latest/download/cosmic-lua
chmod +x cosmic-lua
```

## Usage

### Running Lua Scripts

```bash
./cosmic-lua script.lua
./cosmic-lua -e 'print("Hello, World!")'
```

### Using Teal

The Teal compiler is bundled and available via `tl.lua`:

```bash
./cosmic-lua /zip/tl.lua check myfile.tl
./cosmic-lua /zip/tl.lua run myfile.tl
```

### Cosmic Library

The cosmic library provides utilities for common tasks:

```lua
local cosmic = require("cosmic")
local spawn = require("cosmic.spawn")
local fetch = require("cosmic.fetch")
local walk = require("cosmic.walk")

-- Spawn a process
local result = spawn.run({"ls", "-la"})

-- Fetch a URL
local response = fetch.get("https://example.com")

-- Walk a directory
for path in walk.files(".") do
  print(path)
end
```

## Building from Source

Prerequisites:
- GNU Make
- Git
- Internet connection (to download dependencies)

Build the cosmic binary:

```bash
make cosmic
```

Run tests:

```bash
make test
```

Run type checking:

```bash
make check
```

Full CI pipeline:

```bash
make ci
```

## Development

The repository uses a module-based build system with:
- `lib/cosmic/`: Core cosmic library
- `lib/build/`: Build scripts for fetching and staging dependencies
- `3p/cosmos/`: Cosmopolitan Lua binary
- `3p/tl/`: Teal compiler
- `3p/teal-types/`: Teal type definitions

### Directory Structure

```
cosmic/
├── 3p/              # Third-party dependencies
├── lib/             # Library modules
│   ├── build/       # Build infrastructure
│   ├── checker/     # Type checking utilities
│   ├── cosmic/      # Core cosmic library
│   └── types/       # Type declarations
├── bin/             # Build scripts
├── Makefile         # Main build file
└── o/               # Build output directory (created during build)
```

## License

MIT License - See LICENSE file

## Links

- [Cosmopolitan Libc](https://github.com/jart/cosmopolitan)
- [Teal Language](https://github.com/teal-language/tl)
- [Lua](https://www.lua.org/)
