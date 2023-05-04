
all: doc

clean:
	rm -rf _site

init:
	bundle config set path '.gems'
	bundle install

update:
	bundle update

serve:
	bundle exec jekyll serve

fullclean: clean
	rm -rf .gems .bundle

# get some files from pgbouncer repo

PYTHON = python3

SRC = ../pgbouncer
DOC = $(SRC)/doc

doc:
	cat _build/frag-config-web $(DOC)/config.md > config.md
	cat _build/frag-usage-web $(DOC)/usage.md > usage.md
	cat _build/frag-changelog-web $(SRC)/NEWS.md > changelog.md
	sed -e '1,/^---/d' $(SRC)/README.md | cat _build/frag-install-web - > install.md
	$(PYTHON) _build/downloads.py > _data/downloads.json
	$(SHELL) ./_build/mk-sha.sh

check-sha:
	for d in downloads/files/*.*; do cd $$d; sha256sum -c *.sha256; cd ..; done


