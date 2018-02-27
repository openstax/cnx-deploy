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
       % sudo -u www-data ./tempCleaner.py

    version 1
"""

import os
import time
import shutil
import re
import errno

oneWeek = 604800   # one week in seconds
twoWeeks = 1209600  # two weeks in seconds
base = "/tmp"
now = time.time()

regex = re.compile('(modexport|col).*\.std(err|out)')

for name in os.listdir(base):
    f = os.path.join(base,name)
    if os.path.isfile(f):
        if regex.search(f): 
            if os.stat(f).st_mtime < now - twoWeeks:
                try: 
                    # os.remove(f)
                    print "### Delete: " + f
                except (IOError, OSError), err:
                    print 'ERROR: ' os.strerror(err.errno)  
                    print 'errno: ', err.errno
    if os.path.isdir(f):
        if name.lower().startswith("tmp"):
            if os.stat(f).st_mtime < now - oneWeek:
                try: 
                    # shutil.rmtree(f)
                    print "### Delete dir: " + f
                except (IOError, OSError), err:
                    print 'ERROR: ' os.strerror(err.errno)
                    print 'errno: ', err.errno

