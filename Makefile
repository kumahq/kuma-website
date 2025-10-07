SHELL := /usr/bin/env bash

define newline


endef
RUBY_VERSION := "$(shell ruby -v)"
RUBY_VERSION_REQUIRED := "$(shell cat .ruby-version)"
RUBY_MATCH := $(shell [[ "$(shell ruby -v)" =~ "ruby $(shell cat .ruby-version)" ]] && echo matched)

MISE := $(shell which mise)
MUFFET=$(shell $(MISE) which muffet)

LINK_CHECK_TARGET ?= http://localhost:7777
EXCLUDE_EXTERNAL_LINKS ?= false

.PHONY: ruby-version-check
ruby-version-check:
ifndef RUBY_MATCH
	$(error ruby $(RUBY_VERSION_REQUIRED) is required. Found $(RUBY_VERSION). $(newline)Run `make install`)$(newline)
endif

.PHONY: mise/check/install
mise/check/install:
	@command -v mise >/dev/null 2>&1 || { \
		echo "Error: 'mise' is not installed. See installation instructions at:"; \
	    echo "  https://mise.jdx.dev/installing-mise.html"; \
		exit 1; \
	}

# Installs yarn, npm packages and gems.
.PHONY: install
install: mise/check/install
	$(MISE) install
	yarn install
	bundle install

.PHONY: run
run: ruby-version-check
	bundle exec foreman start

.PHONY: run/clean
run/clean: clean run

test:
	bundle exec rspec

build: ruby-version-check
	exe/build

.PHONY: serve/clean
serve/clean: clean serve

.PHONY: serve
serve:
	yarn netlify serve

# Cleans up all temp files in the build.
# Run `make clean` locally whenever you're updating dependencies, or to help
# troubleshoot build issues.
clean:
	-rm -rf dist
	-rm -rf .netlify
	-rm -rf .jekyll-cache
	-rm -rf app/.jekyll-{cache,metadata}

kill-ports:
	@echo '[DEPRECATED]: This target is deprecated because the "run" target now correctly handles kill signals, closing these ports automatically.'
	@printf "  Existing Jekyll Processes on Port 4000 : %s\n" "$$(lsof -ti:4000 | tr '\n' ' ' || echo 'None')"
	@printf "  Existing Vite Processes on Port 3036   : %s\n" "$$(lsof -ti:3036 | tr '\n' ' ' || echo 'None')"
	@echo 'If you still want to terminate these processes, use the "kill-ports-force" target. [WARNING]: If you are using Firefox, this action may unexpectedly kill your browser processes.'

kill-ports-force:
	@JEKYLL_PROCESS=$$(lsof -ti:4000) && kill -9 $$JEKYLL_PROCESS || true
	@VITE_PROCESS=$$(lsof -ti:3036) && kill -9 $$VITE_PROCESS || true


.PHONY: links/check
links/check:
	$(MUFFET) \
		$(LINK_CHECK_TARGET) \
		--buffer-size 8192 \
		--exclude http://127.0.0.1:7777/docs/1. \
		--exclude 127.0.0.1 \
		--exclude 'http://localhost:7777/vite-dev/*' \
		$(if $(filter true,$(EXCLUDE_EXTERNAL_LINKS)),--exclude 'https?://(?:\[[0-9A-Fa-f:]+\]|\d{1,3}(?:\.\d{1,3}){3}|[A-Za-z0-9-]+\.[A-Za-z0-9.-]+)(?::\d+)?(?:/[^\s]*)?') \
		--include 'https?://localhost(?::\d+)?(?:/[^\s]*)?' \
		--header 'Accept: */*' \
		--max-connections-per-host 8 \
		--max-response-body-size 100000000 \
		--skip-tls-verification \
		--rate-limit 50 \
		--max-retries 5 \
		--timeout 100