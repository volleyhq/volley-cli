#!/bin/bash
# update-formula.sh - Automatically update Formula/volley.rb with new version and SHA256 hashes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get version from argument
VERSION=$1
if [ -z "$VERSION" ]; then
  echo -e "${RED}Error: Version required${NC}"
  echo "Usage: ./scripts/update-formula.sh v0.1.1"
  exit 1
fi

# Remove 'v' prefix if present for version number
VERSION_NUMBER=${VERSION#v}

# Validate version format
if [[ ! $VERSION_NUMBER =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo -e "${RED}Error: Invalid version format. Expected format: v0.1.1 or 0.1.1${NC}"
  exit 1
fi

FORMULA_FILE="Formula/volley.rb"
BUILD_DIR="build"

# Check if formula file exists
if [ ! -f "$FORMULA_FILE" ]; then
  echo -e "${RED}Error: $FORMULA_FILE not found${NC}"
  exit 1
fi

# Check if build directory exists
if [ ! -d "$BUILD_DIR" ]; then
  echo -e "${YELLOW}Warning: $BUILD_DIR directory not found. Running 'make release'...${NC}"
  make release
fi

# Check if all required build files exist
REQUIRED_FILES=(
  "volley-darwin-amd64.tar.gz"
  "volley-darwin-arm64.tar.gz"
  "volley-linux-amd64.tar.gz"
  "volley-linux-arm64.tar.gz"
)

MISSING_FILES=()
for file in "${REQUIRED_FILES[@]}"; do
  if [ ! -f "$BUILD_DIR/$file" ]; then
    MISSING_FILES+=("$file")
  fi
done

if [ ${#MISSING_FILES[@]} -ne 0 ]; then
  echo -e "${RED}Error: Missing build files:${NC}"
  for file in "${MISSING_FILES[@]}"; do
    echo "  - $BUILD_DIR/$file"
  done
  echo -e "${YELLOW}Run 'make release' first to build all binaries${NC}"
  exit 1
fi

echo -e "${GREEN}Calculating SHA256 hashes...${NC}"

# Calculate SHA256 hashes
DARWIN_AMD64_HASH=$(shasum -a 256 "$BUILD_DIR/volley-darwin-amd64.tar.gz" | awk '{print $1}')
DARWIN_ARM64_HASH=$(shasum -a 256 "$BUILD_DIR/volley-darwin-arm64.tar.gz" | awk '{print $1}')
LINUX_AMD64_HASH=$(shasum -a 256 "$BUILD_DIR/volley-linux-amd64.tar.gz" | awk '{print $1}')
LINUX_ARM64_HASH=$(shasum -a 256 "$BUILD_DIR/volley-linux-arm64.tar.gz" | awk '{print $1}')

echo "  darwin-amd64: $DARWIN_AMD64_HASH"
echo "  darwin-arm64: $DARWIN_ARM64_HASH"
echo "  linux-amd64:  $LINUX_AMD64_HASH"
echo "  linux-arm64:  $LINUX_ARM64_HASH"

# Create backup
BACKUP_FILE="${FORMULA_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
cp "$FORMULA_FILE" "$BACKUP_FILE"
echo -e "${GREEN}Created backup: $BACKUP_FILE${NC}"

# Update formula file
echo -e "${GREEN}Updating $FORMULA_FILE...${NC}"

# Use awk for reliable processing
awk -v version="$VERSION" \
    -v version_num="$VERSION_NUMBER" \
    -v darwin_amd64_hash="$DARWIN_AMD64_HASH" \
    -v darwin_arm64_hash="$DARWIN_ARM64_HASH" \
    -v linux_amd64_hash="$LINUX_AMD64_HASH" \
    -v linux_arm64_hash="$LINUX_ARM64_HASH" \
'
BEGIN {
  prev_line = ""
}
{
  # Update version number
  if ($0 ~ /^  version "/) {
    print "  version \"" version_num "\""
    next
  }
  
  # Update source URL
  if ($0 ~ /url "https:\/\/github.com\/volleyhq\/volley-cli\/archive\/refs\/tags\/v/) {
    print "  url \"https://github.com/volleyhq/volley-cli/archive/refs/tags/" version ".tar.gz\""
    next
  }
  
  # Update darwin-amd64 URL
  if ($0 ~ /volley-darwin-amd64\.tar\.gz/) {
    print "      url \"https://github.com/volleyhq/volley-cli/releases/download/" version "/volley-darwin-amd64.tar.gz\""
    getline
    if ($0 ~ /sha256/) {
      print "      sha256 \"" darwin_amd64_hash "\""
    } else {
      print
    }
    next
  }
  
  # Update darwin-arm64 URL
  if ($0 ~ /volley-darwin-arm64\.tar\.gz/) {
    print "      url \"https://github.com/volleyhq/volley-cli/releases/download/" version "/volley-darwin-arm64.tar.gz\""
    getline
    if ($0 ~ /sha256/) {
      print "      sha256 \"" darwin_arm64_hash "\""
    } else {
      print
    }
    next
  }
  
  # Update linux-amd64 URL
  if ($0 ~ /volley-linux-amd64\.tar\.gz/) {
    print "      url \"https://github.com/volleyhq/volley-cli/releases/download/" version "/volley-linux-amd64.tar.gz\""
    getline
    if ($0 ~ /sha256/) {
      print "      sha256 \"" linux_amd64_hash "\""
    } else {
      print
    }
    next
  }
  
  # Update linux-arm64 URL
  if ($0 ~ /volley-linux-arm64\.tar\.gz/) {
    print "      url \"https://github.com/volleyhq/volley-cli/releases/download/" version "/volley-linux-arm64.tar.gz\""
    getline
    if ($0 ~ /sha256/) {
      print "      sha256 \"" linux_arm64_hash "\""
    } else {
      print
    }
    next
  }
  
  # Print all other lines as-is
  print
}
' "$FORMULA_FILE" > "${FORMULA_FILE}.tmp" && mv "${FORMULA_FILE}.tmp" "$FORMULA_FILE"

echo -e "${GREEN}✓ Formula file updated successfully!${NC}"
echo ""
echo -e "${YELLOW}Updated:${NC}"
echo "  Version: $VERSION_NUMBER"
echo "  Source URL: https://github.com/volleyhq/volley-cli/archive/refs/tags/$VERSION.tar.gz"
echo "  All download URLs updated to $VERSION"
echo "  All SHA256 hashes updated"
echo ""
echo -e "${GREEN}Next steps:${NC}"
echo "  1. Review the changes: git diff $FORMULA_FILE"
echo "  2. Commit: git add $FORMULA_FILE && git commit -m 'Update formula for $VERSION'"
echo "  3. Create tag: git tag -a $VERSION -m 'Release $VERSION'"
echo "  4. Push: git push origin main && git push origin $VERSION"
