DESTDIR ?= /
PREFIX ?= /usr

install:
	install -D -m 755 checkrun.sh $(DESTDIR)/$(PREFIX)/bin/checkrun

.PHONY: install
