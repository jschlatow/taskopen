
$(phony all): taskopen.pl

taskopen.pl:
	sed '/#PATH_EXT=/ a\
	PATH_EXT=$(PREFIX)/share/taskopen/scripts' taskopen > taskopen.pl

install: taskopen.pl
	mkdir -p $(DESTDIR)/$(PREFIX)/bin
	install -m 0755 taskopen.pl $(DESTDIR)/$(PREFIX)/bin/taskopen
	mkdir -p $(DESTDIR)/$(PREFIX)/share/taskopen/doc/{man,html}
	install -m 0644 doc/man/* $(DESTDIR)/$(PREFIX)/share/taskopen/doc/man
	install -m 0644 doc/html/* $(DESTDIR)/$(PREFIX)/share/taskopen/doc/html
	mkdir -p $(DESTDIR)/$(PREFIX)/share/taskopen/scripts
	install -m 755 scripts/* $(DESTDIR)/$(PREFIX)/share/taskopen/scripts/

clean:
	rm taskopen.pl

.PHONY: install clean
