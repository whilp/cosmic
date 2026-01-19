modules += tl
tl_version := 3p/tl/version.lua
tl_srcs := $(wildcard 3p/tl/*.lua)
tl_files :=
tl_tests := $(wildcard 3p/tl/test_*.tl)
tl_deps := cosmos
