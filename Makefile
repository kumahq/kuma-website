SHELL := /usr/bin/env bash

define newline


endef
RUBY_VERSION := "$(shell ruby -v)"
RUBY_VERSION_REQUIRED := "$(shell cat .ruby-version)"
RUBY_MATCH := $(shell [[ "$(shell ruby -v)" =~ "ruby $(shell cat .ruby-version)" ]] && echo matched)

.PHONY: ruby-version-check
ruby-version-check:
ifndef RUBY_MATCH
	$(error ruby $(RUBY_VERSION_REQUIRED) is required. Found $(RUBY_VERSION). $(newline)Run `rbenv install $(RUBY_VERSION_REQUIRED)`)$(newline)
endif

# Installs npm packages and gems.
install: ruby-version-check
	yarn install
	bundle install

run: ruby-version-check
	bundle exec foreman start

test:
	bundle exec rspec

build: ruby-version-check
	bundle exec jekyll build --config jekyll.yml --profile

# Cleans up all temp files in the build.
# Run `make clean` locally whenever you're updating dependencies, or to help
# troubleshoot build issues.
clean:
	-rm -rf dist
	-rm -rf app/.jekyll-cache
	-rm -rf app/.jekyll-metadata
	-rm -rf .jekyll-cache/vite

kill-ports:
	@echo '[DEPRECATED]: This target is deprecated because the "run" target now correctly handles kill signals, closing these ports automatically.'
	@printf "  Existing Jekyll Processes on Port 4000 : %s\n" "$$(lsof -ti:4000 | tr '\n' ' ' || echo 'None')"
	@printf "  Existing Vite Processes on Port 3036   : %s\n" "$$(lsof -ti:3036 | tr '\n' ' ' || echo 'None')"
	@echo 'If you still want to terminate these processes, use the "kill-ports-force" target. [WARNING]: If you are using Firefox, this action may unexpectedly kill your browser processes.'

kill-ports-force:
	@JEKYLL_PROCESS=$$(lsof -ti:4000) && kill -9 $$JEKYLL_PROCESS || true
	@VITE_PROCESS=$$(lsof -ti:3036) && kill -9 $$VITE_PROCESS || true
