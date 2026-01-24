#!/usr/bin/env lua
-- Entry point for doc-index generation (bootstrap compatibility).
-- The bootstrap cosmic doesn't support running .tl scripts directly, so this
-- lua entry point uses require() which goes through the Teal loader.
-- Once bootstrap is updated, this file can be removed and docindex.tl used directly.
os.exit(require("cosmic.docindex").main(arg))
