test:
	./test.sh

falsisign.tar.gz:
	cp $$(guix pack  -S /opt/bin=bin -e '(load "guix.scm")') ./falsisign.tar.gz

upload: falsisign.tar.gz
	scp falsisign.tar.gz root@vps:/srv/dump.rdklein.fr/
