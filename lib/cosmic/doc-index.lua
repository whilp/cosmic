#!/usr/bin/env lua
-- Entry point for doc-index generation.
-- Loads the Teal implementation via require() which goes through the Teal loader.
os.exit(require("cosmic.docindex").main(arg))
