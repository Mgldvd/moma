SHELL := /usr/bin/bash

SOURCES := $(wildcard src/core/*.sh src/components/*.sh src/preview/*.sh src/cli/*.sh)
SHELL_FILES := build.sh generate-screenshots.sh example.sh tests/smoke.sh $(SOURCES)
BATS_FILES := $(shell find tests -name '*.bats' -print | LC_ALL=C sort)

.PHONY: build test test-bats lint format check clean

build:
	./build.sh

test: build
	./tests/smoke.sh
	@if command -v bats >/dev/null 2>&1; then bats tests/unit tests/integration tests/contract; else printf '%s\n' 'Bats not installed; skipped Bats suites.'; fi

test-bats: build
	@command -v bats >/dev/null 2>&1 || { printf '%s\n' 'Bats is required.' >&2; exit 1; }
	bats tests/unit tests/integration tests/contract

lint: build
	bash -n $(SHELL_FILES) dist/moma
	@if command -v shellcheck >/dev/null 2>&1; then shellcheck $(SHELL_FILES) && shellcheck -s bash $(BATS_FILES); else printf '%s\n' 'ShellCheck not installed; skipped lint.'; fi

format:
	@command -v shfmt >/dev/null 2>&1 || { printf '%s\n' 'shfmt is required.' >&2; exit 1; }
	shfmt -w -i 4 -ci $(SHELL_FILES)
	shfmt -w -ln bats -i 4 -ci $(BATS_FILES)

check: build lint test

clean:
	rm -f dist/moma
