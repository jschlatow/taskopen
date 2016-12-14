PREFIX=${PREFIX:-/usr}

$(phony all): manfiles taskopen.pl

taskopen.pl: manfiles
	sed s',#PATH_EXT=.*,&\nPATH_EXT=$(PREFIX)/share/taskopen/scripts,' taskopen > taskopen.pl

manfiles:
	gzip -c doc/man/taskopen.1 > doc/man/taskopen.1.gz
	gzip -c doc/man/taskopenrc.5 > doc/man/taskopenrc.5.gz

install: taskopen.pl
	mkdir -p $(PREFIX)/bin
	install -m 0755 taskopen.pl $(PREFIX)/bin/taskopen
	mkdir -p $(PREFIX)/share/man/{man1,man5}
	install -m 0644 doc/man/taskopen.1.gz $(PREFIX)/share/man/man1/
	install -m 0644 doc/man/taskopenrc.5.gz $(PREFIX)/share/man/man5/
	mkdir -p $(PREFIX)/share/taskopen/doc/html
	install -m 0644 doc/html/* $(PREFIX)/share/taskopen/doc/html
	mkdir -p $(PREFIX)/share/taskopen/scripts
	install -m 755 scripts/* $(PREFIX)/share/taskopen/scripts/

clean:
	rm -f taskopen.pl
	rm -f doc/man/taskopen.1.gz
	rm -f doc/man/taskopenrc.5.gz

.PHONY: install clean manfiles
