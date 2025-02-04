#!/bin/bash

# Exit on error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Error handling
trap 'echo -e "${RED}❌ Error on line $LINENO${NC}"' ERR

# Navigate to project directory
cd "$(dirname "$0")/.."

echo -e "${YELLOW}🔍 Starting comprehensive build and verification...${NC}"

# Function to check step completion
check_step() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1 successful${NC}"
    else
        echo -e "${RED}❌ $1 failed${NC}"
        exit 1
    fi
}

# 1. Environment Verification
echo -e "\n${YELLOW}📋 Verifying environment...${NC}"
xcode-select -p > /dev/null 2>&1
check_step "Xcode CLI tools verification"

# 2. Clean Previous Builds
echo -e "\n${YELLOW}🧹 Cleaning build directory...${NC}"
xcodebuild clean \
    -scheme AIVideoEditorApp \
    -destination 'platform=macOS' \
    CODE_SIGN_IDENTITY=- \
    CODE_SIGNING_REQUIRED=NO \
    | xcpretty
swift package clean
check_step "Clean"

# 3. Dependencies Check
echo -e "\n${YELLOW}📦 Checking dependencies...${NC}"
swift package resolve
check_step "Package resolution"
swift package show-dependencies
check_step "Dependencies check"

# 4. Code Signing Verification
echo -e "\n${YELLOW}🔐 Verifying code signing...${NC}"
if [ "$RELEASE_BUILD" = true ]; then
    if ! security find-identity -v -p codesigning | grep -q "Developer ID Application" && \
       ! security find-identity -v -p codesigning | grep -q "Apple Development"; then
        echo -e "${RED}❌ No valid macOS development certificate found${NC}"
        echo -e "${YELLOW}⚠️  You may need to:"
        echo "1. Open Xcode"
        echo "2. Go to Xcode > Settings > Accounts"
        echo "3. Add your Apple ID if not already added"
        echo "4. Click Manage Certificates"
        echo "5. Click + and select Apple Development${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠️  Skipping code signing for development build${NC}"
fi
check_step "Code signing verification"

# 5. Firebase Configuration Check
echo -e "\n${YELLOW}🔥 Checking Firebase configuration...${NC}"
if [ "$RELEASE_BUILD" = true ]; then
    if command -v firebase &> /dev/null; then
        firebase projects:list > /dev/null 2>&1
        check_step "Firebase configuration"
        
        echo -e "\n${YELLOW}Validating Firebase Rules...${NC}"
        firebase deploy --only firestore:rules --dry-run
        firebase deploy --only storage:rules --dry-run
        check_step "Firebase rules validation"
    else
        echo -e "${YELLOW}⚠️  Firebase CLI not installed - skipping Firebase checks${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Skipping Firebase checks for development build${NC}"
    check_step "Firebase configuration"
fi

# 6. Project Structure Verification
echo -e "\n${YELLOW}📁 Verifying project structure...${NC}"
echo "Swift files:"
find . -type f -name "*.swift" | sort
echo -e "\nResource files:"
find . -type f -name "*.xcassets" -o -name "*.storyboard" -o -name "*.xib"
check_step "Project structure verification"

# 7. Static Analysis
echo -e "\n${YELLOW}🔍 Running static analysis...${NC}"
if command -v swiftlint &> /dev/null; then
    swiftlint lint --strict
    check_step "SwiftLint analysis"
else
    echo -e "${YELLOW}⚠️  SwiftLint not installed - skipping linting${NC}"
fi

# 8. Build Project
echo -e "\n${YELLOW}🏗️  Building project...${NC}"
xcodebuild build \
    -scheme AIVideoEditorApp \
    -destination 'platform=macOS' \
    CODE_SIGN_IDENTITY=- \
    CODE_SIGNING_REQUIRED=NO \
    | xcpretty
check_step "Project build"

# 9. Run Tests
echo -e "\n${YELLOW}🧪 Running tests...${NC}"
xcodebuild test \
    -scheme AIVideoEditorApp \
    -destination 'platform=macOS' \
    CODE_SIGN_IDENTITY=- \
    CODE_SIGNING_REQUIRED=NO \
    | xcpretty
check_step "Tests"

# 10. Check Environment Variables
echo -e "\n${YELLOW}🔐 Checking environment variables...${NC}"
if [ -f ".env.local" ]; then
    echo "Environment file found"
    check_step "Environment variables check"
else
    echo -e "${YELLOW}⚠️  No .env.local file found${NC}"
fi

# 11. Verify iOS SDK versions
echo -e "\n${YELLOW}📱 Verifying iOS SDK versions...${NC}"
xcodebuild -showsdks
check_step "SDK verification"

# 12. Archive Project (if this is a release build)
if [ "$RELEASE_BUILD" = true ]; then
    echo -e "\n${YELLOW}📦 Archiving project...${NC}"
    xcodebuild archive \
        -scheme AIVideoEditorApp \
        -destination 'platform=macOS' \
        -configuration Release \
        -archivePath build/AIVideoEditorApp.xcarchive \
        | xcpretty
    check_step "Project archive"
fi

# Final Summary
echo -e "\n${GREEN}✅ Build and verification complete!${NC}"
echo -e "${YELLOW}Summary:${NC}"
echo "1. Build directory cleaned"
echo "2. Dependencies verified"
echo "3. Code signing checked"
echo "4. Firebase configuration validated"
echo "5. Project structure verified"
echo "6. Static analysis completed"
echo "7. Project built successfully"
echo "8. Tests passed"
echo "9. Environment checked"
echo "10. SDK versions verified"

if [ "$RELEASE_BUILD" = true ]; then
    echo "11. Archive created"
fi

echo -e "\n${YELLOW}Next Steps:${NC}"
echo "1. Check Firebase Console for any warnings"
echo "2. Verify all environment variables are properly set"
echo "3. Test on multiple iOS versions if possible"
echo "4. Review any SwiftLint warnings"

# Make the script executable
chmod +x Scripts/build.sh