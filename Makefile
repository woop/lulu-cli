PREFIX ?= $(HOME)/.local

.PHONY: build install uninstall clean

build:
	swift build -c release

install: build
	mkdir -p $(PREFIX)/bin
	cp .build/release/lulu-cli $(PREFIX)/bin/

uninstall:
	rm -f $(PREFIX)/bin/lulu-cli

clean:
	swift package clean
