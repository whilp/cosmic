# Cosmic Lua Extraction Plan

## Overview
This document provides a comprehensive plan to extract all relevant build components from the `whilp/world` repository to create a standalone `cosmic` repository that builds the `cosmic-lua` binary.

## 1. Components Analysis

### 1.1 Core Components

#### Cosmic Lua Binary (`o/bin/cosmic`)
The cosmic lua binary is a self-contained executable that bundles:
- **Cosmopolitan Lua**: Platform-independent Lua binary from whilp/cosmopolitan
- **Teal Compiler**: The teal-language/tl compiler for .tl → .lua compilation
- **Cosmic Library**: Core cosmic functionality (`lib/cosmic/*`)
- **Skill Library**: Extensible skill system (`lib/skill/*`)
- **Teal Type Definitions**: Type definitions from teal-types
- **Main Entry Point**: `lib/cosmic/main.lua` (compiled from `main.tl`)

#### Dependencies Tree
```
cosmic-lua
├── cosmos (cosmopolitan binary)
│   ├── lua (lua 5.4 interpreter)
│   └── zip (info-zip)
├── tl (teal compiler)
│   └── tl.lua (teal library)
├── teal-types (type definitions)
│   └── types/* (type declaration files)
├── lib/cosmic (cosmic library)
│   ├── main.tl (entry point)
│   ├── init.tl
│   ├── help.tl
│   ├── fetch.tl
│   ├── spawn.tl
│   ├── walk.tl
│   ├── tl-gen.lua
│   └── .args
├── lib/skill (skill system)
│   ├── init.tl
│   ├── bootstrap.tl
│   ├── hook.tl
│   ├── pr.tl
│   └── pr_comments.tl
├── lib/types (type declarations)
│   └── *.d.tl files
└── Bootstrap infrastructure
    ├── bootstrap.mk
    └── bin/cosmic (bootstrap wrapper)
```

### 1.2 Build System Components

#### Makefiles
- **Makefile**: Main build orchestration
- **bootstrap.mk**: Bootstrap cosmic binary for build process
- **cook.mk**: Module aggregation (can be simplified for cosmic-only build)
- **lib/cook.mk**: Library module definitions
- **lib/cosmic/cook.mk**: Cosmic module build rules
- **lib/skill/cook.mk**: Skill module build rules
- **3p/cosmos/cook.mk**: Cosmopolitan binary download/stage
- **3p/tl/cook.mk**: Teal compiler download/stage
- **3p/teal-types/cook.mk**: Teal type definitions

#### Build Scripts (lib/build/)
- **build-fetch.tl**: Download and cache versioned dependencies
- **build-stage.tl**: Extract and stage downloaded archives
- **reporter.tl**: Test/check result reporting (for CI)

#### Version Files
- **3p/cosmos/version.lua**: Cosmos binary version and download info
- **3p/tl/version.lua**: Teal compiler version and download info
- **3p/teal-types/version.lua**: Teal types version info

### 1.3 Testing Infrastructure

#### Test Components
- **lib/test/**: Test framework
  - `common.tl`: Test utilities
  - `test-runner.lua`: Test execution
- **lib/checker/**: Linting framework
  - `common.tl`: Checker utilities
  - AST-grep integration
  - Teal type checker integration

#### Tests to Include
- `lib/cosmic/test_*.tl`: Cosmic library tests
- `lib/skill/test_*.tl`: Skill library tests
- `3p/cosmos/test_cosmos.tl`: Cosmos binary tests
- `3p/tl/test_tl.tl`: Teal compiler tests

### 1.4 Supporting Libraries

#### Required Libraries
- **lib/platform.tl**: Platform detection and utilities
- **lib/utils.tl**: General utilities
- **lib/ulid.tl**: ULID generation
- **lib/version.lua**: Version management
- **lib/checker/common.tl**: Linting/checking utilities

#### Type Declarations
- **lib/types/*.d.tl**: Type declarations for external libraries
- **lib/types/cosmo/*.d.tl**: Cosmopolitan Lua API types

## 2. GitHub Workflows

### 2.1 Current Workflow Structure (from whilp/world)

#### PR Workflow (.github/workflows/pr.yml)
```yaml
- Runs on: ubuntu-latest
- Steps:
  1. Checkout
  2. make ci (astgrep, teal, test, build)
```

#### Release Workflow (.github/workflows/release.yml)
```yaml
- Strategy Matrix:
  - linux-x86_64 (ubuntu-latest)
  - darwin-arm64 (macos-latest)
  - linux-arm64 (ubuntu-24.04-arm)
- Steps per platform:
  1. Checkout
  2. make check test build
  3. make test-release
  4. Upload artifacts (home-* binaries, cosmopolitan binaries)
- Release job:
  1. Download all artifacts
  2. make release (creates cosmic-lua from o/bin/cosmic)
  3. Creates GitHub release with date-sha tag
```

### 2.2 Simplified Workflow for Cosmic Repository

#### PR Workflow (simplified)
```yaml
name: pr
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - checkout
      - make ci (teal, test, build)
```

#### Release Workflow (linux-x86_64 only)
```yaml
name: release
on:
  schedule: ['0 6 * * *']  # Daily at 6 AM UTC
  workflow_dispatch:
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - checkout
      - make check test build
      - upload cosmic binary as artifact
  release:
    needs: build
    steps:
      - download artifacts
      - create GitHub release with cosmic-lua
      - generate SHA256SUMS
```

## 3. Extraction Steps

### Phase 1: Repository Structure Setup
1. Create directory structure:
   ```
   cosmic/
   ├── .github/workflows/
   ├── 3p/
   │   ├── cosmos/
   │   ├── tl/
   │   └── teal-types/
   ├── bin/
   ├── lib/
   │   ├── build/
   │   ├── checker/
   │   ├── cosmic/
   │   ├── skill/
   │   ├── test/
   │   └── types/
   ├── bootstrap.mk
   ├── cook.mk
   └── Makefile
   ```

2. Copy core files:
   - LICENSE (already present)
   - .gitignore (from world, filtered for cosmic-only)
   - .editorconfig
   - README.md (new, cosmic-specific)

### Phase 2: Build System Extraction

#### Step 1: Copy Makefiles
```bash
# From whilp/world to cosmic/
cp Makefile Makefile.full
cp bootstrap.mk bootstrap.mk
cp cook.mk cook.mk
```

#### Step 2: Simplify Main Makefile
- Remove home, nvim, and other 3p modules not needed for cosmic
- Keep only:
  - bootstrap module
  - cosmos module
  - tl module
  - teal-types module
  - lib/cosmic module
  - lib/skill module
  - lib/build module
  - lib/test module
  - lib/checker module
- Update includes to only reference kept modules

#### Step 3: Copy Module cook.mk Files
```bash
# 3p modules
cp 3p/cosmos/cook.mk 3p/cosmos/cook.mk
cp 3p/tl/cook.mk 3p/tl/cook.mk
cp 3p/teal-types/cook.mk 3p/teal-types/cook.mk

# lib modules
cp lib/cook.mk lib/cook.mk
cp lib/cosmic/cook.mk lib/cosmic/cook.mk
cp lib/skill/cook.mk lib/skill/cook.mk
cp lib/build/cook.mk lib/build/cook.mk
cp lib/test/cook.mk lib/test/cook.mk
cp lib/checker/cook.mk lib/checker/cook.mk
```

#### Step 4: Simplify lib/cook.mk
- Remove all module includes not needed
- Keep only: build, checker, cosmic, skill, test

### Phase 3: Source Code Extraction

#### Step 1: Copy 3p Modules
```bash
# Cosmos
cp 3p/cosmos/version.lua 3p/cosmos/version.lua
cp 3p/cosmos/test_cosmos.tl 3p/cosmos/test_cosmos.tl

# Teal
cp 3p/tl/version.lua 3p/tl/version.lua
cp 3p/tl/run-teal.tl 3p/tl/run-teal.tl
cp 3p/tl/test_tl.tl 3p/tl/test_tl.tl

# Teal types (if exists)
cp -r 3p/teal-types/ 3p/teal-types/
```

#### Step 2: Copy lib/cosmic
```bash
cp -r lib/cosmic/ lib/cosmic/
# Includes:
# - *.tl files (main, init, help, fetch, spawn, walk)
# - tl-gen.lua
# - .args
# - test_*.tl files
```

#### Step 3: Copy lib/skill
```bash
cp -r lib/skill/ lib/skill/
# Includes:
# - *.tl files (init, bootstrap, hook, pr, pr_comments)
# - test_*.tl files
```

#### Step 4: Copy Supporting Libraries
```bash
# Core lib files
cp lib/platform.tl lib/platform.tl
cp lib/utils.tl lib/utils.tl
cp lib/ulid.tl lib/ulid.tl
cp lib/version.lua lib/version.lua

# Build scripts
cp -r lib/build/ lib/build/

# Test framework
cp -r lib/test/ lib/test/

# Checker framework
cp -r lib/checker/ lib/checker/

# Type declarations
cp -r lib/types/ lib/types/
```

#### Step 5: Copy bin/ Scripts
```bash
cp bin/cosmic bin/cosmic
cp bin/make bin/make
cp bin/run-test bin/run-test
cp bin/hook bin/hook
```

### Phase 4: Configuration Files

#### Step 1: Copy Linter Configs
```bash
cp .stylua.toml .stylua.toml
cp .luacheckrc .luacheckrc
cp tlconfig.lua tlconfig.lua
```

#### Step 2: Copy AST-grep Rules (if used)
```bash
cp -r .ast-grep/ .ast-grep/
```

### Phase 5: GitHub Workflows

#### Step 1: Create Simplified PR Workflow
Create `.github/workflows/pr.yml`:
```yaml
name: pr

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: make ci
        shell: bash -x {0}
        run: bin/make -j ci
```

#### Step 2: Create Simplified Release Workflow
Create `.github/workflows/release.yml`:
```yaml
name: release

on:
  schedule:
    - cron: '0 6 * * *'  # 6 AM UTC daily
  workflow_dispatch:
    inputs:
      prerelease:
        description: 'Mark release as pre-release'
        required: false
        type: boolean
        default: false

env:
  PRERELEASE: false

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: make check test build
        shell: bash -x {0}
        run: bin/make -j check test build

      - name: upload cosmic
        uses: actions/upload-artifact@v4
        with:
          name: cosmic-lua
          path: o/bin/cosmic

  release:
    runs-on: ubuntu-latest
    needs: build
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v4

      - name: download artifacts
        uses: actions/download-artifact@v4
        with:
          path: artifacts/

      - name: create release
        env:
          GH_TOKEN: ${{ github.token }}
          GITHUB_SHA: ${{ github.sha }}
          PRERELEASE_FLAG: ${{ (github.event.inputs.prerelease == 'true' || (github.event.inputs.prerelease == '' && env.PRERELEASE == 'true')) && '--prerelease' || '' }}
        run: |
          mkdir -p release
          cp artifacts/cosmic-lua/cosmic release/cosmic-lua
          chmod +x release/cosmic-lua
          tag="$(date -u +%Y-%m-%d)-${GITHUB_SHA::7}"
          (cd release && sha256sum cosmic-lua > SHA256SUMS && cat SHA256SUMS)
          gh release create "$tag" \
            ${PRERELEASE_FLAG} \
            --title "$tag" \
            release/cosmic-lua release/SHA256SUMS
```

### Phase 6: Documentation

#### Step 1: Create README.md
```markdown
# Cosmic Lua

A cosmopolitan Lua distribution with Teal support and bundled libraries.

## Features
- Single-file, self-contained binary
- Teal language support
- Cross-platform (Linux, macOS, Windows)
- Skill system for extensible functionality

## Building
```bash
make cosmic
```

## Testing
```bash
make test
```

## Usage
```bash
cosmic-lua [options] [script [args]]
cosmic-lua --help
cosmic-lua --skill <name> [args]
```

## License
MIT License - See LICENSE file
```

#### Step 2: Create CONTRIBUTING.md
- Development workflow
- Testing requirements
- Code style guidelines

### Phase 7: Validation

#### Step 1: Build Verification
```bash
make clean
make bootstrap  # Should download cosmic-lua
make check      # Should run teal type checker
make test       # Should run all tests
make cosmic     # Should build o/bin/cosmic
```

#### Step 2: Binary Verification
```bash
./o/bin/cosmic --version
./o/bin/cosmic --help
./o/bin/cosmic -e 'print("hello")'
./o/bin/cosmic --skill bootstrap  # If bootstrap skill is included
```

#### Step 3: Test Coverage
- Ensure all cosmic tests pass
- Ensure all skill tests pass
- Verify teal type checking works

## 4. Simplified Build Targets

### Essential Targets
- `help`: Show help (using cosmic)
- `bootstrap`: Download/setup cosmic-lua for build
- `files`: Build all module files
- `check`: Run type checking and linting
- `test`: Run all tests
- `cosmic`: Build cosmic-lua binary
- `clean`: Remove build artifacts

### Removed Targets
- `home`: Home binary (not needed)
- `build`: Simplified to just `cosmic`
- Platform-specific targets for home
- nvim bundling targets

## 5. Key Differences from whilp/world

### Removed Components
1. Home binary and all its dependencies
2. nvim bundling
3. Most 3p tools (ast-grep, biome, comrak, delta, duckdb, gh, marksman, rg, ruff, shfmt, stylua, etc.)
4. Dotfiles management
5. Platform-specific home setup scripts

### Simplified Components
1. Makefile: ~350 lines instead of ~350 lines (focused on cosmic only)
2. cook.mk: Only includes cosmic-related modules
3. lib/cook.mk: Only includes cosmic, skill, build, test, checker
4. Workflows: Single platform (linux-x86_64) instead of 3 platforms

### Retained Components
1. Bootstrap infrastructure (bin/cosmic wrapper)
2. Teal compilation pipeline
3. Build/fetch/stage infrastructure
4. Test framework
5. Checker framework
6. Cosmic library
7. Skill library

## 6. Migration Checklist

- [ ] Create cosmic repo directory structure
- [ ] Copy LICENSE and base config files
- [ ] Copy and simplify Makefile
- [ ] Copy bootstrap.mk
- [ ] Copy and simplify cook.mk
- [ ] Copy 3p modules (cosmos, tl, teal-types)
- [ ] Copy lib modules (cosmic, skill, build, test, checker)
- [ ] Copy supporting lib files (platform, utils, ulid, version, types)
- [ ] Copy bin scripts
- [ ] Copy linter configs
- [ ] Create GitHub workflows
- [ ] Create README.md
- [ ] Test bootstrap process
- [ ] Test build process
- [ ] Test check/lint process
- [ ] Test test suite
- [ ] Verify cosmic binary works
- [ ] Create first release
- [ ] Update bin/cosmic wrapper to point to cosmic repo releases

## 7. Post-Extraction Tasks

1. **Update Version References**
   - Update bin/cosmic wrapper to pull from whilp/cosmic instead of whilp/world
   - Update cosmos version URL if needed

2. **CI/CD Setup**
   - Enable GitHub Actions
   - Test PR workflow
   - Test release workflow (manual trigger first)

3. **Documentation**
   - Add API documentation for cosmic library
   - Add skill development guide
   - Add examples

4. **Maintenance**
   - Set up dependency update workflow
   - Configure automated releases
   - Set up issue templates

## 8. Build Process Deep Dive

### Bootstrap Phase
1. `bin/cosmic` wrapper downloads pre-built cosmic-lua if not present
2. `bootstrap.mk` creates `o/bootstrap/cosmic` symlink to cosmic-lua
3. Bootstrap cosmic is used for all build operations

### Fetch Phase (for dependencies)
1. `lib/build/build-fetch.tl` reads version.lua files
2. Downloads archives from specified URLs
3. Caches in `o/fetched/`
4. Verifies SHA256 checksums

### Stage Phase (for dependencies)
1. `lib/build/build-stage.tl` extracts fetched archives
2. Applies strip_components
3. Stages in `o/staged/`

### Compile Phase (for .tl files)
1. `lib/cosmic/tl-gen.lua` compiles .tl to .lua
2. Uses teal compiler as library (no argparse dependency)
3. Outputs to `o/` preserving directory structure

### Bundle Phase (for cosmic binary)
1. Collects all compiled .lua files
2. Creates `.lua/cosmic/`, `.lua/skill/` directories
3. Copies tl.lua, teal-types
4. Bundles using cosmos zip into cosmic binary
5. Adds main.lua and .args to zip root

## 9. File Manifest

### Minimum Required Files

#### Root
- Makefile (simplified)
- bootstrap.mk
- cook.mk (simplified)
- LICENSE
- README.md
- .gitignore
- .editorconfig
- .stylua.toml (optional)
- tlconfig.lua
- .luacheckrc (optional)

#### bin/
- cosmic (bootstrap wrapper)
- make (make wrapper)
- run-test (test runner)

#### 3p/cosmos/
- cook.mk
- version.lua
- test_cosmos.tl

#### 3p/tl/
- cook.mk
- version.lua
- run-teal.tl
- test_tl.tl

#### 3p/teal-types/
- cook.mk
- version.lua

#### lib/
- cook.mk (simplified)
- platform.tl
- utils.tl
- ulid.tl
- version.lua

#### lib/cosmic/
- cook.mk
- main.tl
- init.tl
- help.tl
- fetch.tl
- spawn.tl
- walk.tl
- tl-gen.lua
- .args
- test_*.tl

#### lib/skill/
- cook.mk
- init.tl
- bootstrap.tl
- hook.tl (optional)
- pr.tl (optional)
- pr_comments.tl (optional)
- test_*.tl

#### lib/build/
- cook.mk
- build-fetch.tl
- build-stage.tl
- reporter.tl

#### lib/test/
- cook.mk
- common.tl
- (test runner scripts)

#### lib/checker/
- cook.mk
- common.tl

#### lib/types/
- (all .d.tl files for type definitions)

#### .github/workflows/
- pr.yml
- release.yml

## 10. Testing Strategy

### Unit Tests
- `lib/cosmic/test_cosmic.tl`: Cosmic library basics
- `lib/cosmic/test_args.tl`: Argument parsing
- `lib/cosmic/test_spawn.tl`: Process spawning
- `lib/cosmic/test_walk.tl`: Directory walking
- `lib/cosmic/test_fetch.tl`: HTTP fetching
- `lib/skill/test_*.tl`: Skill system tests

### Integration Tests
- `3p/cosmos/test_cosmos.tl`: Cosmos binary functionality
- `3p/tl/test_tl.tl`: Teal compilation
- `lib/cosmic/test_binary.tl`: Cosmic binary integration

### Type Checking
- All .tl files type-checked with teal
- Type definitions in lib/types/

### Linting
- AST-grep rules (optional)
- luacheck (optional)
- stylua (optional)

## 11. Release Process

### Version Scheme
`YYYY-MM-DD-<short-sha>` (e.g., `2026-01-18-a1b2c3d`)

### Release Assets
- `cosmic-lua`: The standalone binary
- `SHA256SUMS`: Checksums for verification

### Release Triggers
1. **Scheduled**: Daily at 6 AM UTC (if changes)
2. **Manual**: workflow_dispatch trigger
3. **Tagged**: On version tags (optional)

### Release Workflow
1. Build cosmic binary on ubuntu-latest
2. Upload as artifact
3. Download artifact in release job
4. Create GitHub release with tag
5. Attach cosmic-lua binary and SHA256SUMS

## 12. Future Enhancements

### Multi-Platform Support
Could add macOS and Windows builds:
- Use same release workflow structure as whilp/world
- Build on macos-latest and windows-latest
- Upload platform-specific binaries
- Note: cosmos already produces actually portable executables

### Additional Skills
Could add more skills to lib/skill/:
- Git operations
- File manipulation
- Text processing
- Network utilities

### Package Registry
Could publish to package registries:
- LuaRocks
- Homebrew tap
- APT repository

### Documentation Site
Could create docs site with:
- API reference
- Skill development guide
- Examples and tutorials
- Blog posts

## Summary

This plan extracts approximately:
- **3 3p modules** (cosmos, tl, teal-types) from 20+ in world
- **5 lib modules** (cosmic, skill, build, test, checker) from 15+ in world
- **~50 source files** instead of 200+
- **1 main build target** (cosmic) instead of multiple (home, cosmic, bootstrap, nvim bundles)
- **Single platform releases** (linux-x86_64) instead of 3 platforms

The result is a focused, maintainable repository dedicated to building and distributing the cosmic-lua binary with all its functionality intact.
