#! /usr/bin/env python

import os
import json
import re
import glob
import sys

from distutils.version import StrictVersion

date_map = {}
for m in re.finditer(r'^[*][*]([-0-9]+) *- *\w+ *([0-9.]+) *-', open('changelog.md', 'r').read(), re.M):
    date_map[m.group(2)] = m.group(1)

vermap = {}
for fn in glob.glob('downloads/files/*/*'):
    ext = fn.split('.')[-1]
    if ext not in ('tgz', 'gz'):
        continue
    parts = fn.split('/')
    ver = parts[-2]
    vermap[ver] = fn

data = {"series": []}
lastserie = ''
for ver in sorted(vermap.keys(), key=StrictVersion, reverse=True):
    fn = vermap[ver]
    basever = '%s.%s' % tuple(ver.split('.')[:2])
    basename = parts[-1]
    if basever != lastserie:
        lastserie = basever
        data['series'].append([])

    parts = fn.split('/')
    url = fn.split('/', 1)[1]  # cut 'downloads'
    data['series'][-1].append({
        'basever': basever,
        'version': ver,
        'date': date_map[ver],
        'tgz_basename': parts[-1],
        'tgz_file': url,
        'tgz_size': os.stat(fn).st_size
    })

print(json.dumps(data, indent=2, sort_keys=True))
