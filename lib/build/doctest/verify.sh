#!/bin/bash
# Verification script for doctest system

set -e

echo "=== Doctest System Verification ==="
echo ""

echo "1. Checking compiled files..."
ls -lh o/lib/build/doctest/example.lua o/lib/build/doctest/extractor.lua
echo "✓ Compiled files exist"
echo ""

echo "2. Running unit tests..."
LUA_PATH="o/lib/?.lua;o/lib/?/init.lua;;" o/bootstrap/cosmic lib/build/doctest/test_example.tl
echo "✓ Unit tests passed"
echo ""

echo "3. Testing extraction from lib/cosmic..."
LUA_PATH="o/lib/?.lua;o/lib/?/init.lua;;" o/bootstrap/cosmic o/lib/build/doctest/extractor.lua lib/cosmic /tmp/cosmic-examples.json
echo "✓ Extraction completed"
echo ""

echo "4. Checking extracted JSON..."
echo "Examples found:"
cat /tmp/cosmic-examples.json | python3 -c "import sys, json; data=json.load(sys.stdin); print(f'  Total: {data[\"total_count\"]}'); print(f'  Files: {data[\"file_count\"]}'); print(f'  IDs: {list(data[\"examples\"].keys())}')"
echo "✓ JSON valid"
echo ""

echo "=== All verification checks passed! ==="
