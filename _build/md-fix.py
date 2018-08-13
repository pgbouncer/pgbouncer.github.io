#! /usr/bin/env python

"""Postprocess pandoc rst2md output to something sane.
"""

import sys, re

# rst: `Foo bar`_ -> md: [Foo bar](#foo-bar)
def fixlink(m):
    txt = m.group(1)
    if txt[0] == '[':
        return txt
    ref = txt.lower().replace(' ', '-')
    ref = ref.replace('_', '')
    return '[%s](#%s)' % (txt, ref)

for fn in sys.argv[1:]:
    sys.stdout.write(open(fn, 'r').read())

for ln in sys.stdin:
    ln = ln.replace('\\', '')               # pandoc is overeager with \
    ln = re.sub(r'^(\s+)[~]', r':\1', ln)       # use def list
    ln = re.sub(r'`([^`]+)`_', fixlink, ln) # fix local links
    if ln[0] == '|' and ln[-2] != '|':
        ln = ln.rstrip() + ' '
    ln = re.sub(r'\[([^]]*)\]{\.title-ref}', r'\1', ln)
    sys.stdout.write(ln)

