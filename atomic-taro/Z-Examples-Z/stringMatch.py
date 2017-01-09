import re
import difflib
import sys


def matchString(s):
    pat = re.compile('(hello|cat)\\ world')
    if pat.match(s):
      return True
    return False

print matchString(sys.argv[1])
