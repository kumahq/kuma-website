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
	npm install -g netlify-cli
	yarn install
	bundle install

run: ruby-version-check
	bundle exec foreman start

build: ruby-version-check
	bundle exec jekyll build --config jekyll.yml

serve:
	netlify dev

# Cleans up all temp files in the build.
# Run `make clean` locally whenever you're updating dependencies, or to help
# troubleshoot build issues.
clean:
	-rm -rf dist
	-rm -rf app/.jekyll-cache
