
$(phony all): taskopen.pl

taskopen.pl: clean
	sed '/#PATH_EXT=/ a\
	PATH_EXT=$(PREFIX)/share/taskopen/scripts' taskopen > taskopen.pl

install: taskopen.pl
	mkdir -p $(DESTDIR)/$(PREFIX)/bin
	install -m 0755 taskopen.pl $(DESTDIR)/$(PREFIX)/bin/taskopen
	mkdir -p $(DESTDIR)/$(PREFIX)/share/man/{man1,man5}
	install -m 0644 doc/man/taskopen.1 $(DESTDIR)/$(PREFIX)/share/man/man1/
	gzip $(DESTDIR)/$(PREFIX)/share/man/man1/taskopen.1
	install -m 0644 doc/man/taskopenrc.5 $(DESTDIR)/$(PREFIX)/share/man/man5/
	gzip $(DESTDIR)/$(PREFIX)/share/man/man5/taskopenrc.5
	mkdir -p $(DESTDIR)/$(PREFIX)/share/taskopen/doc/html
	install -m 0644 doc/html/* $(DESTDIR)/$(PREFIX)/share/taskopen/doc/html
	mkdir -p $(DESTDIR)/$(PREFIX)/share/taskopen/scripts
	install -m 755 scripts/* $(DESTDIR)/$(PREFIX)/share/taskopen/scripts/

clean:
	rm taskopen.pl

.PHONY: install clean
