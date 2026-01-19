# cosmic repository module definitions
# This file aggregates all modules for the build system

# Bootstrap module: setup cosmic-lua for build process
modules += bootstrap
bootstrap_cosmic := $(o)/bootstrap/cosmic
bootstrap_files := $(bootstrap_cosmic)
bootstrap_url := https://github.com/whilp/cosmic/releases/download/2026-01-19-50ffdcd/cosmic-lua

export PATH := $(o)/bootstrap:$(PATH)

$(bootstrap_cosmic):
	@mkdir -p $(@D)
	curl -fsSL -o $@ $(bootstrap_url)
	chmod +x $@
	@ln -sf cosmic $(@D)/lua
