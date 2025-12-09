#!/bin/bash
# release.sh - End-to-end release script for Volley CLI
# Automates the entire release process with verification

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Configuration
FORMULA_FILE="$REPO_ROOT/Formula/volley.rb"
BUILD_DIR="$REPO_ROOT/build"
UPDATE_FORMULA_SCRIPT="$SCRIPT_DIR/update-formula.sh"

# Get version from argument
VERSION=$1
if [ -z "$VERSION" ]; then
  echo -e "${RED}Error: Version required${NC}"
  echo "Usage: ./scripts/release.sh v0.1.2"
  echo ""
  echo "Available tags:"
  git tag -l | tail -5
  exit 1
fi

# Remove 'v' prefix if present for version number
VERSION_NUMBER=${VERSION#v}

# Validate version format
if [[ ! $VERSION_NUMBER =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo -e "${RED}Error: Invalid version format. Expected format: v0.1.2 or 0.1.2${NC}"
  exit 1
fi

# Check if tag already exists
if git rev-parse "$VERSION" >/dev/null 2>&1; then
  echo -e "${YELLOW}Warning: Tag $VERSION already exists${NC}"
  read -p "Do you want to continue and rebuild? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Volley CLI Release Script${NC}"
echo -e "${BLUE}Version: $VERSION${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Step 1: Pre-flight checks
echo -e "${GREEN}[1/10] Running pre-flight checks...${NC}"

# Check git status
if [ -n "$(git status --porcelain)" ]; then
  echo -e "${YELLOW}Warning: You have uncommitted changes${NC}"
  git status --short
  read -p "Continue anyway? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

# Check if we're on main branch (optional warning)
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "detached")
if [ "$CURRENT_BRANCH" != "main" ] && [ "$CURRENT_BRANCH" != "master" ] && [ "$CURRENT_BRANCH" != "HEAD" ]; then
  echo -e "${YELLOW}Warning: Not on main/master branch (currently on $CURRENT_BRANCH)${NC}"
fi

# Run tests
echo -e "${GREEN}Running tests...${NC}"
if ! make test; then
  echo -e "${RED}Tests failed! Aborting release.${NC}"
  exit 1
fi

# Step 2: Create and push tag
echo ""
echo -e "${GREEN}[2/10] Creating and pushing tag $VERSION...${NC}"
if ! git rev-parse "$VERSION" >/dev/null 2>&1; then
  git tag -a "$VERSION" -m "Release $VERSION"
  echo -e "${GREEN}Tag created${NC}"
else
  echo -e "${YELLOW}Tag already exists, skipping creation${NC}"
fi

# Push tag
echo -e "${GREEN}Pushing tag to remote...${NC}"
git push origin "$VERSION" || {
  echo -e "${YELLOW}Tag push failed or tag already exists on remote${NC}"
}

# Step 3: Checkout tag
echo ""
echo -e "${GREEN}[3/10] Checking out tag $VERSION...${NC}"
git checkout "$VERSION"
echo -e "${GREEN}Checked out tag $VERSION${NC}"

# Verify we're on the tag
CURRENT_TAG=$(git describe --exact-match --tags 2>/dev/null || echo "")
if [ "$CURRENT_TAG" != "$VERSION" ]; then
  echo -e "${RED}Error: Not on expected tag. Current: $CURRENT_TAG, Expected: $VERSION${NC}"
  exit 1
fi

# Step 4: Build release binaries
echo ""
echo -e "${GREEN}[4/10] Building release binaries...${NC}"
make clean
make release

# Verify binaries were created
REQUIRED_FILES=(
  "volley-darwin-amd64.tar.gz"
  "volley-darwin-arm64.tar.gz"
  "volley-linux-amd64.tar.gz"
  "volley-linux-arm64.tar.gz"
  "volley-windows-amd64.zip"
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
  exit 1
fi

echo -e "${GREEN}All binaries built successfully${NC}"

# Step 5: Verify version in binaries
echo ""
echo -e "${GREEN}[5/10] Verifying version in binaries...${NC}"
BINARY_VERSION=$("$BUILD_DIR/volley-darwin-amd64" --version 2>/dev/null | awk '{print $3}' || echo "")
if [[ "$BINARY_VERSION" == *"-dirty"* ]]; then
  echo -e "${RED}Error: Binary version contains '-dirty' suffix: $BINARY_VERSION${NC}"
  exit 1
fi

if [[ "$BINARY_VERSION" != "$VERSION"* ]]; then
  echo -e "${RED}Error: Binary version mismatch. Expected: $VERSION, Got: $BINARY_VERSION${NC}"
  exit 1
fi

echo -e "${GREEN}Version verified: $BINARY_VERSION${NC}"

# Step 6: Calculate SHA256 hashes and update formula
echo ""
echo -e "${GREEN}[6/10] Calculating SHA256 hashes and updating formula...${NC}"

# Switch back to main branch to update formula
git checkout main 2>/dev/null || git checkout master 2>/dev/null || {
  echo -e "${YELLOW}Warning: Could not checkout main/master, staying on tag${NC}"
}

# Use the update-formula script
if [ -f "$UPDATE_FORMULA_SCRIPT" ]; then
  "$UPDATE_FORMULA_SCRIPT" "$VERSION"
else
  echo -e "${RED}Error: update-formula.sh not found at $UPDATE_FORMULA_SCRIPT${NC}"
  exit 1
fi

# Step 7: Commit formula changes
echo ""
echo -e "${GREEN}[7/10] Committing formula changes...${NC}"
git add "$FORMULA_FILE"
if git diff --cached --quiet "$FORMULA_FILE"; then
  echo -e "${YELLOW}No changes to formula file${NC}"
else
  git commit -m "Update formula for $VERSION"
  echo -e "${GREEN}Formula changes committed${NC}"
  
  # Ask about pushing
  read -p "Push formula changes to main branch? (Y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    git push origin main 2>/dev/null || git push origin master 2>/dev/null || {
      echo -e "${YELLOW}Warning: Could not push to main/master${NC}"
    }
  fi
fi

# Step 8: Create GitHub release
echo ""
echo -e "${GREEN}[8/10] Creating GitHub release...${NC}"
echo -e "${YELLOW}You need to create the GitHub release manually or use GitHub CLI${NC}"
echo ""
echo "Option A: Using GitHub CLI (if installed):"
echo "  gh release create $VERSION \\"
echo "    --title \"$VERSION\" \\"
echo "    --notes \"Release $VERSION\" \\"
echo "    $BUILD_DIR/volley-darwin-amd64.tar.gz \\"
echo "    $BUILD_DIR/volley-darwin-arm64.tar.gz \\"
echo "    $BUILD_DIR/volley-linux-amd64.tar.gz \\"
echo "    $BUILD_DIR/volley-linux-arm64.tar.gz \\"
echo "    $BUILD_DIR/volley-windows-amd64.zip"
echo ""
echo "Option B: Using GitHub Web UI:"
echo "  1. Go to: https://github.com/volleyhq/volley-cli/releases/new"
echo "  2. Select tag: $VERSION"
echo "  3. Upload binaries from: $BUILD_DIR"
echo ""

read -p "Have you created the GitHub release? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo -e "${YELLOW}Skipping release verification. Please create the release manually.${NC}"
else
  # Verify release exists
  echo -e "${GREEN}Verifying GitHub release...${NC}"
  if command -v gh &> /dev/null; then
    if gh release view "$VERSION" &>/dev/null; then
      echo -e "${GREEN}GitHub release verified${NC}"
    else
      echo -e "${YELLOW}Warning: Could not verify GitHub release${NC}"
    fi
  fi
fi

# Step 9: Update Homebrew tap
echo ""
echo -e "${GREEN}[9/10] Updating Homebrew tap...${NC}"
echo -e "${YELLOW}You need to update the homebrew-volley repository manually${NC}"
echo ""
echo "Steps:"
echo "  1. cd /path/to/homebrew-volley"
echo "  2. cp $FORMULA_FILE Formula/volley.rb"
echo "  3. git add Formula/volley.rb"
echo "  4. git commit -m \"Update volley to $VERSION\""
echo "  5. git push"
echo ""

read -p "Have you updated the Homebrew tap? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo -e "${YELLOW}Please update the Homebrew tap manually${NC}"
fi

# Step 10: Final verification
echo ""
echo -e "${GREEN}[10/10] Final verification...${NC}"

# Verify GitHub release files
echo -e "${GREEN}Verifying SHA256 hashes from GitHub release...${NC}"
GITHUB_HASHES=()
PLATFORMS=("darwin-amd64" "darwin-arm64" "linux-amd64" "linux-arm64")

for platform in "${PLATFORMS[@]}"; do
  echo -n "  $platform: "
  HASH=$(curl -sL "https://github.com/volleyhq/volley-cli/releases/download/$VERSION/volley-$platform.tar.gz" | shasum -a 256 | awk '{print $1}')
  GITHUB_HASHES+=("$HASH")
  echo "$HASH"
done

# Compare with formula
echo -e "${GREEN}Comparing with formula hashes...${NC}"
FORMULA_HASHES=()
FORMULA_HASHES+=($(grep -A 1 "darwin-amd64.tar.gz" "$FORMULA_FILE" | grep sha256 | sed 's/.*sha256 "\([^"]*\)".*/\1/'))
FORMULA_HASHES+=($(grep -A 1 "darwin-arm64.tar.gz" "$FORMULA_FILE" | grep sha256 | sed 's/.*sha256 "\([^"]*\)".*/\1/'))
FORMULA_HASHES+=($(grep -A 1 "linux-amd64.tar.gz" "$FORMULA_FILE" | grep sha256 | sed 's/.*sha256 "\([^"]*\)".*/\1/'))
FORMULA_HASHES+=($(grep -A 1 "linux-arm64.tar.gz" "$FORMULA_FILE" | grep sha256 | sed 's/.*sha256 "\([^"]*\)".*/\1/'))

MISMATCHES=0
for i in "${!PLATFORMS[@]}"; do
  if [ "${GITHUB_HASHES[$i]}" != "${FORMULA_HASHES[$i]}" ]; then
    echo -e "${RED}Mismatch for ${PLATFORMS[$i]}:${NC}"
    echo "  GitHub: ${GITHUB_HASHES[$i]}"
    echo "  Formula: ${FORMULA_HASHES[$i]}"
    ((MISMATCHES++))
  fi
done

if [ $MISMATCHES -eq 0 ]; then
  echo -e "${GREEN}✓ All SHA256 hashes match!${NC}"
else
  echo -e "${RED}✗ Found $MISMATCHES hash mismatch(es)${NC}"
  echo -e "${YELLOW}You may need to update the formula with the correct hashes from GitHub${NC}"
fi

# Summary
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Release Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo "Version: $VERSION"
echo "Tag: Created and pushed"
echo "Binaries: Built in $BUILD_DIR"
echo "Formula: Updated"
echo ""
echo -e "${GREEN}Next steps:${NC}"
echo "  1. Create GitHub release (if not done)"
echo "  2. Update Homebrew tap repository"
echo "  3. Test installation: brew install volley"
echo ""
echo -e "${GREEN}Release script completed!${NC}"

