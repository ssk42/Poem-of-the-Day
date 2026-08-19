.PHONY: help build build-release test unit-test ui-test coverage clean deep-clean install ci \
        asc-check next-build build-release-stamped upload testflight \
        metadata-validate metadata-pull metadata-diff metadata-push \
        screenshots-upload release-status release-check testflight-feedback

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

# --- App Store Connect (asc) ------------------------------------------------
# All targets read credentials via scripts/asc-env.sh, which maps this repo's
# existing APP_STORE_CONNECT_* variables onto the ASC_* names the CLI expects.
# See docs/APP_STORE_CONNECT.md.

ASC_ENV := source scripts/asc-env.sh
APP_VERSION := $(shell sed -n 's/^build --define=app_version=//p' .bazelrc)

asc-check: ## Verify asc is installed and credentials work
	@echo "$(BLUE)Checking App Store Connect access...$(NC)"
	@command -v asc >/dev/null 2>&1 || { echo "$(YELLOW)asc not found. Install: brew install asc$(NC)"; exit 1; }
	@$(ASC_ENV) && asc auth status --output table
	@echo "$(GREEN)✓ App Store Connect reachable$(NC)"

next-build: ## Show the next safe build number from App Store Connect
	@$(ASC_ENV) && asc builds next-build-number 		--app "$$ASC_APP_ID" 		--version "$(APP_VERSION)" 		--platform IOS 		--initial-build-number 1 		--output table

build-release-stamped: ## Build release IPA stamped with the next build number
	@echo "$(BLUE)Resolving next build number...$(NC)"
	@$(ASC_ENV) && NEXT=$$(asc builds next-build-number 		--app "$$ASC_APP_ID" --version "$(APP_VERSION)" --platform IOS 		--initial-build-number 1 --output json | python3 -c "import json,sys;print(json.load(sys.stdin)['nextBuildNumber'])"); 	echo "$(BLUE)Building $(APP_VERSION) ($$NEXT)...$(NC)"; 	bazelisk build --config=release 		--define=app_version="$(APP_VERSION)" 		--define=build_number="$$NEXT" 		//:PoemOfTheDay
	@echo "$(GREEN)✓ Release build stamped and complete$(NC)"

upload: build-release-stamped ## Build a stamped IPA and upload it to TestFlight
	@$(ASC_ENV) && IPA_PATH=$$(bazelisk cquery --config=release --output=files //:PoemOfTheDay 2>/dev/null | grep '\.ipa$$' | head -1); 	if [ -z "$$IPA_PATH" ] || [ ! -f "$$IPA_PATH" ]; then IPA_PATH="bazel-bin/PoemOfTheDay.ipa"; fi; 	echo "$(BLUE)Uploading $$IPA_PATH...$(NC)"; 	asc builds upload --app "$$ASC_APP_ID" --ipa "$$IPA_PATH" --wait --poll-interval 15s --output table
	@echo "$(GREEN)✓ Upload complete$(NC)"

testflight: ## Build, upload, and distribute to a TestFlight group (GROUP=...)
	@if [ -z "$(GROUP)" ]; then echo "$(YELLOW)Usage: make testflight GROUP=\"Internal Testers\"$(NC)"; exit 1; fi
	@$(ASC_ENV) && asc workflow run testflight_beta 		VERSION:$(APP_VERSION) TESTFLIGHT_GROUP:"$(GROUP)"
	@echo "$(GREEN)✓ Distributed to $(GROUP)$(NC)"

metadata-validate: ## Validate App Store metadata files (no credentials needed)
	@echo "$(BLUE)Validating metadata...$(NC)"
	@asc metadata validate --dir ./metadata --output table
	@echo "$(GREEN)✓ Metadata valid$(NC)"

metadata-pull: ## Pull live App Store metadata into ./metadata (overwrites)
	@$(ASC_ENV) && asc metadata pull 		--app "$$ASC_APP_ID" --version "$(APP_VERSION)" --platform IOS 		--dir ./metadata --force --output table
	@echo "$(GREEN)✓ Metadata pulled$(NC)"

metadata-diff: metadata-validate ## Preview metadata changes without applying them
	@$(ASC_ENV) && asc metadata push 		--app "$$ASC_APP_ID" --version "$(APP_VERSION)" --platform IOS 		--dir ./metadata --dry-run --output table

metadata-push: metadata-validate ## Push ./metadata to App Store Connect
	@$(ASC_ENV) && asc metadata push 		--app "$$ASC_APP_ID" --version "$(APP_VERSION)" --platform IOS 		--dir ./metadata --output table
	@echo "$(GREEN)✓ Metadata pushed$(NC)"

screenshots-upload: ## Upload App Store screenshots for all device sizes
	@echo "$(BLUE)Uploading screenshots...$(NC)"
	@$(ASC_ENV) && asc screenshots upload 		--app "$$ASC_APP_ID" --version "$(APP_VERSION)" 		--path ./AppStoreScreenshots/iPhone_6.5 --device-type IPHONE_65 		--max-screenshots 10 --replace --output table
	@$(ASC_ENV) && asc screenshots upload 		--app "$$ASC_APP_ID" --version "$(APP_VERSION)" 		--path ./AppStoreScreenshots/iPhone_6.3 --device-type IPHONE_61 		--max-screenshots 10 --replace --output table
	@echo "$(GREEN)✓ Screenshots uploaded$(NC)"

release-status: ## Show the App Store release pipeline dashboard
	@$(ASC_ENV) && asc status --app "$$ASC_APP_ID" --output table

release-check: ## Run App Store submission readiness checks
	@$(ASC_ENV) && asc validate --app "$$ASC_APP_ID" --version "$(APP_VERSION)" --output table

testflight-feedback: ## Show recent TestFlight feedback and crashes
	@$(ASC_ENV) && asc testflight feedback list --app "$$ASC_APP_ID" --output table
	@$(ASC_ENV) && asc testflight crashes list --app "$$ASC_APP_ID" --sort -createdDate --limit 10 --output table

