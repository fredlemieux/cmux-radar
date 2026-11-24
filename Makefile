# cmux-radar — every local and CI task goes through here. `make help` lists them.
SHELL := /bin/bash
TEST_FLAGS := $(shell scripts/swift-test-flags.sh)

.DEFAULT_GOAL := help

.PHONY: help
help: ## List tasks
	@grep -hE '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F ':.*## ' '{printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

.PHONY: bootstrap
bootstrap: ## Install tools (Homebrew) and git hooks
	brew bundle --file=Brewfile
	scripts/check-tool-versions.sh
	# Absolute path: a relative one doesn't resolve inside linked worktrees, which then run no hooks.
	git config --local core.hooksPath "$$(git rev-parse --path-format=absolute --git-common-dir)/hooks"
	lefthook install --force

.PHONY: format
format: ## Format all Swift files in place
	swiftformat .

.PHONY: lint
lint: ## Format check + SwiftLint (strict)
	swiftformat --lint .
	scripts/swiftlint.sh lint --strict --quiet

.PHONY: build
build: ## Build all targets (warnings are errors)
	swift build $(TEST_FLAGS)

.PHONY: test
test: ## Run all tests
	swift test $(TEST_FLAGS)

.PHONY: snapshots-record
snapshots-record: ## Re-record every snapshot reference image
	RADAR_RECORD_SNAPSHOTS=1 swift test $(TEST_FLAGS) || true
	@echo "Re-run 'make test' to verify the recorded images."

.PHONY: catalog
catalog: ## Launch the component catalog (Storybook); COMPONENT=Name opens one directly
	COMPONENT="$(COMPONENT)" swift run $(TEST_FLAGS) RadarCatalog

.PHONY: check
check: lint build test ## Everything CI runs. Run before every push.

.PHONY: mutate
mutate: ## Mutation testing, full run (slow)
	scripts/mutate.sh

.PHONY: mutate-changed
mutate-changed: ## Mutation testing on sources changed since origin/main
	scripts/mutate.sh --changed origin/main
