#!/bin/bash

# RecurPay Protocol Build Script
echo "Building RecurPay Protocol..."

# Clean previous builds
forge clean

# Install dependencies
forge install

# Build contracts
echo "Compiling contracts..."
forge build

# Run tests
echo "Running test suite..."
forge test

# Generate gas report
echo "Generating gas report..."
forge test --gas-report

# Check coverage
echo "Checking test coverage..."
forge coverage

echo "Build completed successfully!"
echo "RecurPay Protocol is ready for deployment!"
