PREFIX ?= /usr/local
EDITOR ?= vim
OPEN ?= open

SRCFILES = $(wildcard src/*.nim)
MANFILES = $(wildcard doc/man/*.1) $(wildcard doc/man/*.5)
MANFILES_GZ = $(addsuffix .gz, $(MANFILES))
MANFILES_HTML = doc/html/taskopen\(1\).html doc/html/taskopenrc\(5\).html

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

doc/html/taskopen\(1\).html: doc/man/taskopen.1 Makefile
	groff -mandoc -T html $< > $@

doc/html/taskopenrc\(5\).html: doc/man/taskopenrc.5 Makefile
	groff -mandoc -T html $< > $@

$(MANFILES_GZ): %.gz: % Makefile
	gzip -c $* > $@

install: $(MANFILES_GZ) $(MANFILES_HTML) taskopen
	mkdir -p $(DESTDIR)/$(PREFIX)/bin
	install -m 0755 taskopen $(DESTDIR)/$(PREFIX)/bin/taskopen
	mkdir -p $(DESTDIR)/$(PREFIX)/share/man/man1
	mkdir -p $(DESTDIR)/$(PREFIX)/share/man/man5
	install -m 0644 doc/man/taskopen.1.gz $(DESTDIR)/$(PREFIX)/share/man/man1/
	install -m 0644 doc/man/taskopenrc.5.gz $(DESTDIR)/$(PREFIX)/share/man/man5/
	mkdir -p $(DESTDIR)/$(PREFIX)/share/taskopen/doc/html
	install -m 0644 doc/html/* $(DESTDIR)/$(PREFIX)/share/taskopen/doc/html
	mkdir -p $(DESTDIR)/$(PREFIX)/share/taskopen/scripts
	install -m 755 scripts/* $(DESTDIR)/$(PREFIX)/share/taskopen/scripts/
	mkdir -p $(DESTDIR)/$(PREFIX)/share/taskopen/examples
	install -m 755 examples/* $(DESTDIR)/$(PREFIX)/share/taskopen/examples/

clean:
	rm -f $(MANFILES_GZ)
	rm -f $(MANFILES_HTML)
	rm taskopen

.PHONY: install clean
