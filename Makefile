PREFIX ?= /usr/local/
PERLPATH := $(shell which perl)

$(phony all): manfiles taskopen.pl

taskopen.pl: manfiles
	sed s',#PATH_EXT=.*,&\nPATH_EXT=$(PREFIX)/share/taskopen/scripts,' taskopen > taskopen.pl
	sed -i'.bak' s',/usr/bin/perl,$(PERLPATH),' taskopen.pl

manfiles:
	gzip -c doc/man/taskopen.1 > doc/man/taskopen.1.gz
	gzip -c doc/man/taskopenrc.5 > doc/man/taskopenrc.5.gz

install: taskopen.pl
	mkdir -p $(DESTDIR)/$(PREFIX)/bin
	install -m 0755 taskopen.pl $(DESTDIR)/$(PREFIX)/bin/taskopen
	mkdir -p $(DESTDIR)/$(PREFIX)/share/man/man1
	mkdir -p $(DESTDIR)/$(PREFIX)/share/man/man5
	install -m 0644 doc/man/taskopen.1.gz $(DESTDIR)/$(PREFIX)/share/man/man1/
	install -m 0644 doc/man/taskopenrc.5.gz $(DESTDIR)/$(PREFIX)/share/man/man5/
	mkdir -p $(DESTDIR)/$(PREFIX)/share/taskopen/doc/html
	install -m 0644 doc/html/* $(DESTDIR)/$(PREFIX)/share/taskopen/doc/html
	mkdir -p $(DESTDIR)/$(PREFIX)/share/taskopen/scripts
	install -m 755 scripts/* $(DESTDIR)/$(PREFIX)/share/taskopen/scripts/

clean:
	rm -f taskopen.pl
	rm -f doc/man/taskopen.1.gz
	rm -f doc/man/taskopenrc.5.gz

.PHONY: install clean manfiles
