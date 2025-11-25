.PHONY: help build test unit-test ui-test coverage clean deep-clean install ci

# Colors
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m # No Color

help: ## Show this help message
	@echo "$(BLUE)Poem of the Day - Build Commands$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "Examples:"
	@echo "  make build"
	@echo "  make test"
	@echo "  make ci"

install: ## Install Bazelisk
	@echo "$(BLUE)Installing Bazelisk...$(NC)"
	@brew install bazelisk
	@chmod +x bazel.sh
	@echo "$(GREEN)✓ Setup complete$(NC)"

build: ## Build the iOS app
	@echo "$(BLUE)Building iOS app...$(NC)"
	@bazelisk build //:PoemOfTheDay
	@echo "$(GREEN)✓ Build successful$(NC)"

build-release: ## Build in release mode
	@echo "$(BLUE)Building iOS app (release)...$(NC)"
	@bazelisk build --config=release //:PoemOfTheDay
	@echo "$(GREEN)✓ Release build successful$(NC)"

test: ## Run all tests (unit + UI tests)
	@echo "$(BLUE)Running all tests via xcodebuild...$(NC)"
	@set -o pipefail && xcodebuild test \
		-scheme "Poem of the Day" \
		-destination "platform=iOS Simulator,name=iPhone 17 Pro,OS=26.1" \
		-resultBundlePath ./test-results \
		-parallel-testing-enabled YES \
		-maximum-concurrent-test-simulator-destinations 4 \
		2>&1 | tee test-output.log | grep -E "(Test Suite|Test Case.*passed|Test Case.*failed|passed|failed|Testing.*succeeded|Testing.*failed|BUILD)" | tail -50; \
	if [ $$? -eq 0 ]; then \
		echo ""; \
		echo "$(GREEN)✓ All tests passed$(NC)"; \
	else \
		echo ""; \
		echo "$(YELLOW)⚠ Some tests failed. Check test-results/ for details$(NC)"; \
		exit 1; \
	fi

unit-test: ## Run unit tests only
	@echo "$(BLUE)Running unit tests...$(NC)"
	@xcodebuild test \
		-scheme "Poem of the Day" \
		-destination "platform=iOS Simulator,name=iPhone 17 Pro,OS=26.1" \
		-only-testing:"Poem_of_the_DayTests" \
		-resultBundlePath ./test-results/unit \
		2>&1 | grep -E "(Test Suite|Test Case.*passed|Test Case.*failed|passed|failed)" | tail -30
	@echo "$(GREEN)✓ Unit tests passed$(NC)"

ui-test: ## Run UI tests only
	@echo "$(BLUE)Running UI tests...$(NC)"
	@xcodebuild test \
		-scheme "Poem of the Day" \
		-destination "platform=iOS Simulator,name=iPhone 17 Pro,OS=26.1" \
		-only-testing:"Poem_of_the_DayUITests" \
		-resultBundlePath ./test-results/ui \
		-parallel-testing-enabled YES \
		2>&1 | grep -E "(Test Suite|Test Case.*passed|Test Case.*failed|passed|failed)" | tail -30
	@echo "$(GREEN)✓ UI tests passed$(NC)"

coverage: ## Generate test coverage report
	@echo "$(BLUE)Generating coverage report...$(NC)"
	@bazelisk coverage --combined_report=lcov //:PoemOfTheDayTests
	@echo "$(GREEN)✓ Coverage report generated$(NC)"
	@echo "$(YELLOW)Location: $$(bazelisk info output_path)/_coverage/_coverage_report.dat$(NC)"

clean: ## Clean build artifacts
	@echo "$(YELLOW)Cleaning build artifacts...$(NC)"
	@bazelisk clean
	@echo "$(GREEN)✓ Clean complete$(NC)"

deep-clean: ## Deep clean all Bazel state
	@echo "$(YELLOW)Deep cleaning...$(NC)"
	@bazelisk clean --expunge
	@rm -rf ~/.bazel_cache
	@echo "$(GREEN)✓ Deep clean complete$(NC)"

query: ## Query build dependencies
	@echo "$(BLUE)Build dependencies:$(NC)"
	@bazelisk query 'deps(//:PoemOfTheDay)'

graph: ## Generate dependency graph (requires graphviz)
	@echo "$(BLUE)Generating dependency graph...$(NC)"
	@bazelisk query 'deps(//:PoemOfTheDay)' --output graph > deps.dot
	@dot -Tpng deps.dot -o deps.png
	@echo "$(GREEN)✓ Graph saved to deps.png$(NC)"
	@open deps.png || true

ci: ## Run full CI pipeline (build → test → upload)
	@echo "$(BLUE)Running CI pipeline...$(NC)"
	@echo ""
	@echo "$(YELLOW)→ Step 1/4: Building app with Bazel...$(NC)"
	@bazelisk build //:PoemOfTheDay
	@echo "$(GREEN)✓ Bazel build complete$(NC)"
	@echo ""
	@echo "$(YELLOW)→ Step 2/4: Running tests with xcodebuild...$(NC)"
	@make test
	@echo ""
	@echo "$(YELLOW)→ Step 3/4: Building release version...$(NC)"
	@bazelisk build --config=release //:PoemOfTheDay 2>&1 | tail -5
	@echo ""
	@echo "$(YELLOW)→ Step 4/4: Preparing for upload...$(NC)"
	@IPA_PATH=$$(bazelisk cquery --output=files //:PoemOfTheDay 2>&1 | grep "\.ipa" | head -1); \
	echo "$(GREEN)✓ Build artifact ready: $$IPA_PATH$(NC)"
	@echo ""
	@echo "$(GREEN)✓ CI pipeline completed successfully$(NC)"
	@echo ""
	@echo "To upload to TestFlight, run: make upload"

format: ## Format Swift code (requires swift-format)
	@echo "$(BLUE)Formatting Swift code...$(NC)"
	@swift-format format --in-place --recursive .
	@echo "$(GREEN)✓ Code formatted$(NC)"

lint: ## Run SwiftLint
	@echo "$(BLUE)Running SwiftLint...$(NC)"
	@swiftlint lint
	@echo "$(GREEN)✓ Linting complete$(NC)"

info: ## Show Bazel info
	@echo "$(BLUE)Bazel Information:$(NC)"
	@echo ""
	@echo "Version:"
	@bazelisk version
	@echo ""
	@echo "Output path:"
	@bazelisk info output_path
	@echo ""
	@echo "Workspace:"
	@bazelisk info workspace

.DEFAULT_GOAL := help

upload: ## Upload build to TestFlight/XCloud
	@echo "$(BLUE)Uploading to TestFlight...$(NC)"
	@IPA_PATH=$$(bazelisk cquery --output=files //:PoemOfTheDay 2>&1 | grep "\.ipa" | head -1); \
	if [ -z "$$IPA_PATH" ] || [ ! -f "$$IPA_PATH" ]; then \
		echo "$(YELLOW)No IPA found. Building first...$(NC)"; \
		make build-release; \
		IPA_PATH=$$(bazelisk cquery --output=files //:PoemOfTheDay 2>&1 | grep "\.ipa" | head -1); \
	fi; \
	echo "$(BLUE)Uploading $$IPA_PATH...$(NC)"; \
	xcrun altool --upload-app -f "$$IPA_PATH" --type ios \
		--apiKey $(API_KEY) --apiIssuer $(API_ISSUER)
	@echo "$(GREEN)✓ Upload complete$(NC)"

build-and-upload: ## Build, test, and upload
	@echo "$(BLUE)Running full build and upload pipeline...$(NC)"
	@make build-release
	@make upload
	@echo "$(GREEN)✓ Build and upload complete$(NC)"
