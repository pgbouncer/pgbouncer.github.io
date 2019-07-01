
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

# get some files from pgbouncer repo

SRC = ../pgbouncer
DOC = $(SRC)/doc

doc:
	cat _build/frag-config-web $(DOC)/config.md > config.md
	cat _build/frag-usage-web $(DOC)/usage.md > usage.md
	cat _build/frag-changelog-web $(SRC)/NEWS.md > changelog.md
	sed -e '1,/^---/d' $(SRC)/README.md | cat _build/frag-install-web - > install.md
	python _build/downloads.py > _data/downloads.json
	$(SHELL) ./_build/mk-sha.sh

check-sha:
	for d in downloads/files/*.*; do cd $$d; sha256sum -c *.sha256; cd ..; done


