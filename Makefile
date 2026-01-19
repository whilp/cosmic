.SECONDEXPANSION:
.SECONDARY:
SHELL := /bin/bash
.SHELLFLAGS := -o pipefail -c
.DEFAULT_GOAL := help

MAKEFLAGS += --no-print-directory
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --no-builtin-variables
MAKEFLAGS += --output-sync

modules :=
o := o

export PATH := $(CURDIR)/$(o)/bin:$(PATH)
export STAGE_O := $(CURDIR)/$(o)/staged
export FETCH_O := $(CURDIR)/$(o)/fetched

## TMP: temp directory for tests (default: /tmp, use TMP=~/tmp for more space)
TMP ?= /tmp
export TMPDIR := $(TMP)

# Platform for build scripts (all deps use wildcard "*" platform)
platform := linux-x86_64

include cook.mk
include lib/cook.mk
include 3p/cosmos/cook.mk
include 3p/tl/cook.mk
include 3p/teal-types/cook.mk

# landlock-make sandbox constraints (only effective when using landlock-make)
# global defaults: read-only access, no network, basic stdio
.PLEDGE = stdio rpath
.UNVEIL = \
	rx:$(o)/bootstrap \
	r:lib \
	r:3p

.PHONY: help
## Show this help message
help: $(build_files) | $(bootstrap_cosmic)
	@$(bootstrap_cosmic) $(build_help) $(MAKEFILE_LIST)

## Filter targets by pattern (make test only='teal')
filter-only = $(if $(only),$(foreach f,$1,$(if $(findstring $(only),$(f)),$(f))),$1)

cp := cp -p

$(o)/%: %
	@mkdir -p $(@D)
	@$(cp) $< $@

# compile .tl files to .lua (extension changes)
$(o)/%.lua: %.tl $(types_files) $(tl_files) $(bootstrap_files)
	@mkdir -p $(@D)
	@$(bootstrap_cosmic) --compile $< > $@

# tl files: modules declare _tl, derive compiled .lua outputs
all_tl := $(call filter-only,$(foreach x,$(modules),$($(x)_tl)))
all_lua := $(patsubst %.tl,$(o)/%.lua,$(all_tl))

# define *_staged, *_dir for versioned modules (must be before dep expansion)
# modules can override *_dir for post-processing (e.g., nvim bundles plugins)
$(foreach m,$(modules),$(if $($(m)_version),\
  $(eval $(m)_staged := $(o)/$(m)/.staged)\
  $(if $($(m)_dir),,$(eval $(m)_dir := $(o)/$(m)/.staged))))

# default deps for regular modules (also excluded from file dep expansion)
default_deps := bootstrap test

# expand module deps: M_files depends on deps' _files and _staged
$(foreach m,$(filter-out $(default_deps),$(modules)),\
  $(foreach d,$($(m)_deps),\
    $(eval $($(m)_files): $($(d)_files))\
    $(if $($(d)_staged),\
      $(eval $($(m)_files): $($(d)_staged)))))

all_versions := $(call filter-only,$(foreach x,$(modules),$($(x)_version)))

# versioned modules: o/module/.versioned -> version.lua
$(foreach m,$(modules),$(if $($(m)_version),\
  $(eval $(o)/$(m)/.versioned: $($(m)_version) ; @mkdir -p $$(@D) && ln -sfn $(CURDIR)/$$< $$@)))
all_versioned := $(call filter-only,$(foreach m,$(modules),$(if $($(m)_version),$(o)/$(m)/.versioned)))

# versions get fetched: o/module/.fetched -> o/fetched/module/<ver>-<sha>/<archive>
.PHONY: fetched
all_fetched := $(patsubst %/.versioned,%/.fetched,$(all_versioned))
## Fetch all dependencies only
fetched: $(all_fetched)
$(o)/%/.fetched: .PLEDGE = stdio rpath wpath cpath inet dns
$(o)/%/.fetched: .UNVEIL = rx:$(o)/bootstrap r:3p rwc:$(o) r:/etc/resolv.conf r:/etc/ssl
$(o)/%/.fetched: $(o)/%/.versioned $(build_files) | $(bootstrap_cosmic)
	@$(bootstrap_cosmic) -- $(build_fetch) $$(readlink $<) $(platform) $@

# versions get staged: o/module/.staged -> o/staged/module/<ver>-<sha>
.PHONY: staged
all_staged := $(patsubst %/.fetched,%/.staged,$(all_fetched))
## Fetch and extract all dependencies
staged: $(all_staged)
$(o)/%/.staged: .PLEDGE = stdio rpath wpath cpath proc exec
$(o)/%/.staged: .UNVEIL = rx:$(o)/bootstrap r:3p rwc:$(o) rx:/usr/bin
$(o)/%/.staged: $(o)/%/.fetched $(build_files)
	@$(bootstrap_cosmic) -- $(build_stage) $$(readlink $(o)/$*/.versioned) $(platform) $< $@

all_tests := $(call filter-only,$(foreach x,$(modules),$($(x)_tests)))
all_tested := $(patsubst %,$(o)/%.test.got,$(all_tests))

## Run all tests (incremental)
test: $(o)/test-summary.txt

$(o)/test-summary.txt: $(all_tested) | $(build_reporter)
	@$(reporter) --dir $(o) $^ | tee $@

export TEST_O := $(o)
export TEST_PLATFORM := $(platform)
export TEST_BIN := $(o)/bin
export TEST_TMPDIR := $(TMP)
# LUA_PATH: aggregate _lua_dirs from modules
space := $(subst ,, )
lua_path_dirs := $(foreach m,$(modules),$($(m)_lua_dirs))
export LUA_PATH := $(subst $(space),;,$(foreach d,$(lua_path_dirs),$(CURDIR)/$(d)/?.lua $(CURDIR)/$(d)/?/init.lua));;
export NO_COLOR := 1

# Test rule: execute test directly via shebang, capture exit code, stdout, stderr
$(o)/%.tl.test.got: .PLEDGE = stdio rpath wpath cpath proc exec
$(o)/%.tl.test.got: .UNVEIL = rx:$(o)/bootstrap r:lib r:3p rwc:$(o) rwc:$(TMP) rx:/usr rx:/proc r:/etc r:/dev/null
$(o)/%.tl.test.got: $(o)/%.lua $(test_files) $(o)/bin/cosmic | $(bootstrap_files)
	@mkdir -p $(@D)
	@chmod +x $<
	-@PATH=$(CURDIR)/$(o)/bin:$$PATH TEST_DIR=$(TEST_DIR) $< > $(basename $@).out 2> $(basename $@).err; STATUS=$$?; echo $$STATUS > $@

# expand test deps: M's tests depend on own _files/_tl plus deps' _dir/_files/_lua
# derive compiled .lua from _tl (first pass: compute all _lua)
$(foreach m,$(filter-out bootstrap,$(modules)),\
  $(if $($(m)_tl),$(eval $(m)_lua := $(patsubst %.tl,$(o)/%.lua,$($(m)_tl)))))
# second pass: set up test dependencies
$(foreach m,$(filter-out bootstrap,$(modules)),\
  $(eval $(patsubst %,$(o)/%.test.got,$($(m)_tests)): $($(m)_files) $($(m)_lua))\
  $(eval $(patsubst %,$(o)/%.test.got,$($(m)_tests)): TEST_DEPS += $($(m)_files) $($(m)_lua))\
  $(if $($(m)_dir),\
    $(eval $(patsubst %,$(o)/%.test.got,$($(m)_tests)): $($(m)_dir))\
    $(eval $(patsubst %,$(o)/%.test.got,$($(m)_tests)): TEST_DEPS += $($(m)_dir))\
    $(eval $(patsubst %,$(o)/%.test.got,$($(m)_tests)): TEST_DIR := $($(m)_dir)))\
  $(foreach d,$(filter-out $(m),$(default_deps) $($(m)_deps)),\
    $(if $($(d)_dir),\
      $(eval $(patsubst %,$(o)/%.test.got,$($(m)_tests)): $($(d)_dir))\
      $(eval $(patsubst %,$(o)/%.test.got,$($(m)_tests)): TEST_DEPS += $($(d)_dir)))\
    $(eval $(patsubst %,$(o)/%.test.got,$($(m)_tests)): $($(d)_files) $($(d)_lua))))

all_built_files := $(call filter-only,$(foreach x,$(modules),$($(x)_files)))
all_built_files += $(all_lua)
all_source_files := $(call filter-only,$(foreach x,$(modules),$($(x)_tests)))
all_source_files += $(call filter-only,$(filter-out ,$(foreach x,$(modules),$($(x)_version))))
all_source_files += $(call filter-only,$(foreach x,$(modules),$($(x)_srcs)))
all_source_files += $(all_tl)
all_checkable_files := $(addprefix $(o)/,$(all_source_files))

.PHONY: files
## Build all module files
files: $(all_built_files)

all_teals := $(patsubst %,%.teal.got,$(all_checkable_files))

## Run teal type checker on all files
teal: $(o)/teal-summary.txt

$(o)/teal-summary.txt: $(all_teals) | $(build_reporter)
	@$(reporter) --dir $(o) $^ | tee $@

$(o)/%.teal.got: $(o)/% $(cosmic_bin) | $(bootstrap_files)
	@mkdir -p $(@D)
	-@$(cosmic_bin) --check $< > $(basename $@).out 2> $(basename $@).err; STATUS=$$?; echo $$STATUS > $@

.PHONY: clean
## Remove all build artifacts
clean:
	@rm -rf $(o)

.PHONY: bootstrap
## Bootstrap build environment
bootstrap: $(bootstrap_files)

.PHONY: build
## Build cosmic binary
build: cosmic

# Example testing - run Example_* functions in .tl files (exclude test files)
all_example_srcs := $(call filter-only,$(foreach m,$(modules),$(filter-out $($(m)_tests),$($(m)_tl))))
all_examples := $(patsubst %.tl,$(o)/%.tl.example.got,$(all_example_srcs))

.PHONY: example
## Run all example tests
example: $(o)/example-summary.txt

$(o)/example-summary.txt: $(all_examples) | $(build_reporter)
	@$(reporter) --dir $(o) $^ | tee $@

$(o)/%.tl.example.got: .PLEDGE = stdio rpath wpath cpath proc exec
$(o)/%.tl.example.got: .UNVEIL = rx:$(o)/bootstrap r:lib r:3p rwc:$(o) rwc:$(TMP) rx:/usr rx:/proc r:/etc r:/dev/null
$(o)/%.tl.example.got: %.tl $(cosmic_bin) | $(bootstrap_files)
	@mkdir -p $(@D)
	@set +e; $(cosmic_bin) --example $< > $(basename $@).out 2> $(basename $@).err; echo $$? > $@

# Documentation generation - render .tl files as markdown
all_docs := $(patsubst %.tl,$(o)/%.md,$(all_example_srcs))

.PHONY: doc
## Generate documentation from source
doc: $(all_docs)

$(o)/%.md: %.tl $(cosmic_bin) | $(bootstrap_files)
	@mkdir -p $(@D)
	@$(cosmic_bin) --doc $< > $@

ci_stages := teal test build

.PHONY: ci
## Run full CI pipeline (teal, test, build)
ci:
	@rm -f $(o)/failed
	@$(foreach s,$(ci_stages),\
		echo "::group::$(s)"; \
		$(MAKE) --keep-going $(s) || echo $(s) >> $(o)/failed; \
		echo "::endgroup::";)
	@if [ -f $(o)/failed ]; then echo "failed:"; cat $(o)/failed; exit 1; fi

debug-modules:
	@echo $(modules)

