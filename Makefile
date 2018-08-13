
all: doc

clean:
	rm -rf _site

init:
	bundle install --path .gems

update:
	bundle update

serve:
	bundle exec jekyll serve

fullclean: clean
	rm -rf .gems .bundle

# generate usage.md & config.md from rst files in pgbouncer repo

FIX = python _build/md-fix.py
SRC = ../pgbouncer
DOC = $(SRC)/doc

doc:
	pandoc -f rst -t markdown < $(DOC)/config.rst | $(FIX) _build/frag-config-web > config.md
	pandoc -f rst -t markdown < $(DOC)/usage.rst | $(FIX) _build/frag-usage-web > usage.md
	pandoc -f rst -t markdown --wrap=preserve < $(SRC)/NEWS.rst | $(FIX) _build/frag-changelog-web > changelog.md
	sed -e '/^[+]/s/[+]/|/g' $(SRC)/README.rst | \
	pandoc -f rst -t markdown | sed -e '1,/^---/d' | $(FIX) _build/frag-install-web > install.md
	python _build/downloads.py > _data/downloads.json
	$(SHELL) ./_build/mk-sha.sh

check-sha:
	for d in downloads/files/*.*; do cd $$d; sha256sum -c *.sha256; cd ..; done


