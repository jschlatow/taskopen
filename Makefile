PREFIX ?= /usr/local
EDITOR ?= vim
OPEN ?= open

DESTDIR ?=
VERSION ?= $(shell git describe --tags HEAD)

SRCFILES = $(wildcard src/*.nim)
MANFILES_MD = $(wildcard doc/man/*.1.md) $(wildcard doc/man/*.5.md)
MANFILES    = $(MANFILES_MD:.md=)
MANFILES_GZ = $(addsuffix .gz, $(MANFILES))

EDITOR_PRESENT := $(shell which $(firstword ${EDITOR}) >/dev/null 2>&1 || echo "not found")
ifneq (,${EDITOR_PRESENT})
	EDITOR := nano
endif

OPEN_PRESENT := $(shell which $(firstword ${OPEN}) >/dev/null 2>&1 || echo "not found")
ifneq (,${OPEN_PRESENT})
OPEN=run-mailcap
endif

OPEN_PRESENT := $(shell which $(firstword ${OPEN}) >/dev/null 2>&1 || echo "not found")
ifneq (,${OPEN_PRESENT})
OPEN=xdg-open
endif

all: taskopen

taskopen: $(SRCFILES) Makefile
	nim c -d:version:$(VERSION) -d:release -d:pathext:'${PREFIX}/share/taskopen/scripts' -d:editor:'${EDITOR}' -d:open:'${OPEN}' --outdir:./ src/taskopen.nim

$(MANFILES_GZ): %.gz: % Makefile
	gzip -c $* > $@

manpages: $(MANFILES_MD)
	pandoc --standalone --to man doc/man/taskopen.1.md -o doc/man/taskopen.1
	pandoc --standalone --to man doc/man/taskopenrc.5.md -o doc/man/taskopenrc.5

install: $(MANFILES_GZ) taskopen
	mkdir -p $(DESTDIR)$(PREFIX)/bin
	mkdir -p $(DESTDIR)$(PREFIX)/share/man/man1
	mkdir -p $(DESTDIR)$(PREFIX)/share/man/man5
	install -m 0755 taskopen $(DESTDIR)$(PREFIX)/bin/taskopen
	install -m 0644 doc/man/taskopen.1.gz $(DESTDIR)$(PREFIX)/share/man/man1/taskopen.1.gz
	install -m 0644 doc/man/taskopenrc.5.gz $(DESTDIR)$(PREFIX)/share/man/man5/taskopenrc.5.gz
	mkdir -p $(DESTDIR)$(PREFIX)/share/taskopen/scripts/
	cp -r scripts/* $(DESTDIR)$(PREFIX)/share/taskopen/scripts/
	chmod -R 755 $(DESTDIR)$(PREFIX)/share/taskopen/scripts
	mkdir -p $(DESTDIR)$(PREFIX)/share/taskopen/examples
	cp -r examples/* $(DESTDIR)$(PREFIX)/share/taskopen/examples
	chmod -R 755 $(DESTDIR)$(PREFIX)/share/taskopen/examples

clean:
	rm -f $(MANFILES_GZ)
	rm taskopen

.PHONY: install clean release
