#!/bin/bash

# Exit on error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "Running tests for AIVideoEditor..."

# Navigate to project directory
cd "$(dirname "$0")/.."

# Run unit tests
echo "Running unit tests..."
xcodebuild test \
  -scheme AIVideoEditor \
  -destination 'platform=iOS Simulator,name=iPhone 14,OS=latest' \
  -only-testing:AIVideoEditorTests \
  | xcpretty

# Run UI tests
echo "Running UI tests..."
xcodebuild test \
  -scheme AIVideoEditor \
  -destination 'platform=iOS Simulator,name=iPhone 14,OS=latest' \
  -only-testing:AIVideoEditorUITests \
  | xcpretty

echo -e "${GREEN}All tests completed successfully!${NC}"
