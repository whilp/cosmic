#!/bin/bash
# Comprehensive test suite for the documentation validator

set -e

echo "Testing Documentation Coverage Validator"
echo "========================================"
echo

validator="./lib/build/doctest/validate-docs"

# Test 1: Fully documented module passes
echo "Test 1: Fully documented module (should pass)"
if $validator lib/build/doctest/demo.tl --threshold 90; then
  echo "✓ PASS: Fully documented module passed validation"
else
  echo "✗ FAIL: Fully documented module should pass"
  exit 1
fi
echo

# Test 2: Undocumented module fails high threshold
echo "Test 2: Undocumented module with high threshold (should fail)"
if $validator lib/cosmic/spawn.tl --threshold 90 2>&1 | grep -q "below threshold"; then
  echo "✓ PASS: Undocumented module correctly failed"
else
  echo "✗ FAIL: Undocumented module should fail with high threshold"
  exit 1
fi
echo

# Test 3: Undocumented module passes low threshold
echo "Test 3: Undocumented module with low threshold (should pass)"
if $validator lib/cosmic/spawn.tl --threshold 0; then
  echo "✓ PASS: Low threshold allows undocumented module"
else
  echo "✗ FAIL: Module should pass with threshold 0"
  exit 1
fi
echo

# Test 4: Custom threshold
echo "Test 4: Custom threshold of 100% (should pass for demo.tl)"
if $validator lib/build/doctest/demo.tl --threshold 100; then
  echo "✓ PASS: Demo file meets 100% threshold"
else
  echo "✗ FAIL: Demo file should meet 100% threshold"
  exit 1
fi
echo

# Test 5: Invalid file
echo "Test 5: Nonexistent file (should fail)"
if $validator /nonexistent/file.tl 2>&1 | grep -q "Error"; then
  echo "✓ PASS: Invalid file correctly reported error"
else
  echo "✗ FAIL: Should report error for nonexistent file"
  exit 1
fi
echo

echo "========================================"
echo "All tests passed!"
echo
echo "Summary:"
echo "- Validator correctly identifies documentation coverage"
echo "- Threshold checking works as expected"
echo "- Error handling is appropriate"
