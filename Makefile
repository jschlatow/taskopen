PREFIX ?= /usr/local
EDITOR ?= vim
OPEN ?= open

DESTDIR ?=

SRCFILES = $(wildcard src/*.nim)
MANFILES_MD = $(wildcard doc/man/*.1.md) $(wildcard doc/man/*.5.md)
MANFILES    = $(MANFILES_MD:.md=)
MANFILES_GZ = $(addsuffix .gz, $(MANFILES))

EDITOR_PRESENT := $(shell which ${EDITOR} >/dev/null 2>&1 || echo "not found")
ifneq (,${EDITOR_PRESENT})
	EDITOR := nano
endif

OPEN_PRESENT := $(shell which ${OPEN} >/dev/null 2>&1 || echo "not found")
ifneq (,${OPEN_PRESENT})
OPEN=run-mailcap
endif

OPEN_PRESENT := $(shell which ${OPEN} >/dev/null 2>&1 || echo "not found")
ifneq (,${OPEN_PRESENT})
OPEN=xdg-open
endif

all: taskopen

taskopen: $(SRCFILES) Makefile
	nim c -d:versionGit -d:release -d:pathext:${PREFIX}/share/taskopen/scripts -d:editor:${EDITOR} -d:open:${OPEN} --outdir:./ src/taskopen.nim

$(MANFILES): %: %.md Makefile
	pandoc --standalone --to man $@.md -o $@

$(MANFILES_GZ): %.gz: % Makefile
	gzip -c $* > $@

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

.PHONY: install clean
