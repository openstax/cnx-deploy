#!/usr/bin/env python

""" 2018-02-26

    tempCleaner.py

    Author: Scott Batchelder

    This tool is designed to clean out the /tmp/ directory on servers that
    use that space, but do not clean up after themselves(pdf_gen). This
    tool will only delete directories that have the pattern"/tmp/tmp*/"
    and that are older than 7 days.  An entry for this tool should be added
    to the 'crontab' so that it runs once per day.

    Make sure to execute as the proper user:
       % sudo -u www-data "./tempCleaner.py

    version 1
"""

import os
import time
import shutil
import re

base = r"/tmp"
now = time.time()

for dirpath, dirnames, files in os.walk(base):
    for dirname in dirnames:
        if "tmp" in dirname.lower():
            f = os.path.join(dirpath, dirname)
            if os.stat(f).st_mtime < now - 7*86400:
                shutil.rmtree(f)
                # print "### Delete dir: " + f

for g in os.listdir(base):
    g = os.path.join(base, g)
    r = re.compile('modexport|col')
    s = re.compile('stderr|stdout')
    if r.search(g):
        if s.search(g):
            if os.stat(g).st_mtime < now - 14: # *86400:
                os.remove(g)
                # print "### Delete: " + g
