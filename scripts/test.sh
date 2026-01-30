#!/bin/bash

# RecurPay Protocol Test Runner
echo "Running RecurPay Protocol Test Suite..."

# Unit tests
echo "Running unit tests..."
forge test test/unit/ -vv

# Integration tests  
echo "Running integration tests..."
forge test test/integration/ -vv

# Fuzz tests
echo "Running fuzz tests..."
forge test test/fuzz/ -vv

# Invariant tests
echo "Running invariant tests..."
forge test test/invariant/ -vv

# Benchmark tests
echo "Running benchmark tests..."
forge test test/benchmark/ -vv

echo "All tests completed!"
echo "Test results summary available above."
