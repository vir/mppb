#H=/home/deb
H=/tmp/home
SCRIPTS=pushqueue.sh startbuild.pl rep.sh build_task.sh create.sh mk_pbuilder_symlinks.sh update.sh

.PHONY: install
install:
	install -d $(H)
	install $(SCRIPTS) $(H)/
	install pbuilderrc $(H)/.pbuilderrc
	install -d $(H)/pbuilder-hooks
	install pbuilder-hooks/* $(H)/pbuilder-hooks/
	install -d $(H)/control
	install -m 644 control/*.css $(H)/control
	install -m 755 control/*.pl $(H)/control
#	install lighttpd-debian-repository.conf /etc/lighttpd/conf-available/20-debian-repository.conf
#	/usr/sbin/lighttpd-enable-mod debian-repository
#crontab
#doc/NEW-STABLE.txt
