.PHONY: help \
	commit diff push pull gitlog \
	ios-sim ios-device ios-device-no-sign \
	ios-local-build ios-local-run
# =========================
# Help
# =========================
help: ## List available commands
	@echo ""
	@echo "Available commands:"
	@echo ""
	@grep -hE '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'
	@echo ""

# =========================
# Git
# =========================
commit: ## Commit using predefined message file
	git add .
	git commit -F ~/commit.md

diff: ## Show staged diff and line count
	git add .
	git diff --cached > ~/diff
	wc -l ~/diff

push: ## Push current branch or specified branch (make push branch=xxx)
	@branch=$${branch:-$$(git branch --show-current)}; \
	if [ -z "$$branch" ]; then \
		echo "Branch not found"; \
		exit 1; \
	fi; \
	git push origin $$branch

pull: ## Pull current branch or specified branch (make pull branch=xxx)
	@branch=$${branch:-$$(git branch --show-current)}; \
	if [ -z "$$branch" ]; then \
		echo "Branch not found"; \
		exit 1; \
	fi; \
	git pull origin $$branch

gitlog: ## Show git log in one line format
	git log --oneline

pullmain: ## Pull latest changes from main branch
	git checkout main && git pull origin main

# =========================
# iOS Build
# =========================
ios-local-build: ## Build local iOS app for simulator (no signing required)
	flutter build ios --simulator

ios-local-run: ## Run app locally on iOS simulator (iPhone 15)
	flutter run -d "iPhone 15"

ios-sim: ## Build iOS app for simulator
	flutter build ios --simulator

ios-device: ## Build iOS app for physical device (requires Apple provisioning)
	flutter build ios

ios-device-no-sign: ## Build iOS app for physical device without codesign
	flutter build ios --no-codesign
