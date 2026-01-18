# cosmic repository module definitions
# This file aggregates all modules for the build system

# Bootstrap module: setup cosmic-lua for build process
modules += bootstrap
bootstrap_cosmic := $(o)/bootstrap/cosmic
bootstrap_files := $(bootstrap_cosmic)

export PATH := $(o)/bootstrap:$(PATH)

bin/cosmic-lua: bin/cosmic
	@bin/cosmic --version >/dev/null 2>&1 || true

$(bootstrap_cosmic): bin/cosmic-lua
	@mkdir -p $(@D)
	@cp bin/cosmic-lua $@
	@chmod +x $@
	@ln -sf cosmic $(@D)/lua