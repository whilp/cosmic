modules += lib
lib_dirs := $(o)/lib

# type declaration files for teal compilation
types_files := $(wildcard lib/types/*.d.tl lib/types/*/*.d.tl lib/types/*/*/*.d.tl)

# copy .lua files to $(o)/lib/
$(o)/lib/%.lua: lib/%.lua
	@mkdir -p $(@D)
	@cp $< $@

# compile .tl files to .lua (for $(o)/teal/lib)
$(o)/teal/lib/%.lua: lib/%.tl $(types_files) | $(bootstrap_files)
	@mkdir -p $(@D)
	@$(bootstrap_cosmic) --compile $< > $@

include lib/build/cook.mk
include lib/cosmic/cook.mk
