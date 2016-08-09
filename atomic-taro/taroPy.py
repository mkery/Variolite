# a script attempting to run python scripts and capture the output

import subprocess
import sys


inScript = sys.argv[1]

p = subprocess.Popen(['python', inScript], stdout=subprocess.PIPE, stderr=subprocess.PIPE)

out, err = p.communicate()
print "Yay!"
print out
print err
