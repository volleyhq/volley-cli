.PHONY: build install test clean release help

# Version info
# For releases, use --exact-match to ensure we're on a tag, otherwise use describe without --dirty
VERSION ?= $(shell git describe --exact-match --tags 2>/dev/null || git describe --tags --always 2>/dev/null || echo "dev")
COMMIT ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILD_DATE ?= $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")

# Build info
LDFLAGS = -X github.com/volleyhq/volley-cli/cmd.version=$(VERSION) \
          -X github.com/volleyhq/volley-cli/cmd.commit=$(COMMIT) \
          -X github.com/volleyhq/volley-cli/cmd.buildDate=$(BUILD_DATE)

# Binary name
BINARY_NAME = volley

# Build directory
BUILD_DIR = build

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Build the CLI for current platform
	@echo "Building $(BINARY_NAME)..."
	@go build -ldflags "$(LDFLAGS)" -o $(BUILD_DIR)/$(BINARY_NAME) .

install: build ## Install the CLI to $GOPATH/bin
	@echo "Installing $(BINARY_NAME)..."
	@go install -ldflags "$(LDFLAGS)" .

test: ## Run tests
	@echo "Running tests..."
	@go test -v ./...

clean: ## Clean build artifacts
	@echo "Cleaning..."
	@rm -rf $(BUILD_DIR)
	@go clean

release: ## Build releases for all platforms
	@echo "Building releases for all platforms..."
	@mkdir -p $(BUILD_DIR)
	@echo "Building for darwin/amd64..."
	@GOOS=darwin GOARCH=amd64 go build -ldflags "$(LDFLAGS)" -o $(BUILD_DIR)/$(BINARY_NAME)-darwin-amd64 .
	@echo "Building for darwin/arm64..."
	@GOOS=darwin GOARCH=arm64 go build -ldflags "$(LDFLAGS)" -o $(BUILD_DIR)/$(BINARY_NAME)-darwin-arm64 .
	@echo "Building for linux/amd64..."
	@GOOS=linux GOARCH=amd64 go build -ldflags "$(LDFLAGS)" -o $(BUILD_DIR)/$(BINARY_NAME)-linux-amd64 .
	@echo "Building for linux/arm64..."
	@GOOS=linux GOARCH=arm64 go build -ldflags "$(LDFLAGS)" -o $(BUILD_DIR)/$(BINARY_NAME)-linux-arm64 .
	@echo "Building for windows/amd64..."
	@GOOS=windows GOARCH=amd64 go build -ldflags "$(LDFLAGS)" -o $(BUILD_DIR)/$(BINARY_NAME)-windows-amd64.exe .
	@echo "Creating release archives..."
	@cd $(BUILD_DIR) && tar -czf $(BINARY_NAME)-darwin-amd64.tar.gz $(BINARY_NAME)-darwin-amd64
	@cd $(BUILD_DIR) && tar -czf $(BINARY_NAME)-darwin-arm64.tar.gz $(BINARY_NAME)-darwin-arm64
	@cd $(BUILD_DIR) && tar -czf $(BINARY_NAME)-linux-amd64.tar.gz $(BINARY_NAME)-linux-amd64
	@cd $(BUILD_DIR) && tar -czf $(BINARY_NAME)-linux-arm64.tar.gz $(BINARY_NAME)-linux-arm64
	@cd $(BUILD_DIR) && zip -q $(BINARY_NAME)-windows-amd64.zip $(BINARY_NAME)-windows-amd64.exe
	@echo "Releases built in $(BUILD_DIR)/"

