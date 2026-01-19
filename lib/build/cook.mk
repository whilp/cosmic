modules += build
build_lua_srcs := $(wildcard lib/build/*.lua)
# tl sources exist alongside lua (for reference) but aren't used during build
# because bootstrap needs lua before tl is staged
build_srcs := $(build_lua_srcs)
build_fetch := $(o)/bin/build-fetch.lua
build_stage := $(o)/bin/build-stage.lua
build_reporter := $(o)/bin/reporter.lua
build_help := $(o)/bin/make-help.lua
build_files := $(build_fetch) $(build_stage) $(build_reporter) $(build_help)
build_tests := $(wildcard lib/build/test_*.tl)

.PRECIOUS: $(build_files)

# Build scripts use cosmic's bundled teal (no tl_staged dependency)
# This breaks the circular dependency: build scripts -> fetch -> tl_staged -> build scripts
$(build_files): $(o)/bin/%.lua: lib/build/%.tl | $(bootstrap_files)
	@mkdir -p $(@D)
	@$(bootstrap_cosmic) --compile $< > $@
	@chmod +x $@
reporter := $(bootstrap_cosmic) -- $(build_reporter)

# test_reporter needs cosmic binary
$(o)/lib/build/test_reporter.tl.test.got: $$(cosmic_bin)

# make-help snapshot: generate actual help output
$(o)/lib/build/make-help.snap: Makefile $(build_help) | $(bootstrap_cosmic)
	@mkdir -p $(@D)
	@$(bootstrap_cosmic) $(build_help) Makefile > $@

# makefile validation outputs
build_make_out := $(o)/lib/build/make

$(build_make_out)/dry-run.out: Makefile $(wildcard */*.mk) $(wildcard */*/*.mk)
	@mkdir -p $(@D)
	@code=0; $(MAKE) -n files >$@.tmp 2>&1 || code=$$?; echo "exit:$$code" >> $@.tmp; mv $@.tmp $@

$(build_make_out)/database.out: Makefile $(wildcard */*.mk) $(wildcard */*/*.mk)
	@mkdir -p $(@D)
	@code=0; $(MAKE) -p -n -q >$@.tmp 2>&1 || code=$$?; echo "exit:$$code" >> $@.tmp; mv $@.tmp $@

build_make_outputs := $(build_make_out)/dry-run.out $(build_make_out)/database.out

$(o)/lib/build/test_makefile.tl.test.got: $(build_make_outputs)
$(o)/lib/build/test_makefile.tl.test.got: TEST_DIR := $(build_make_out)
