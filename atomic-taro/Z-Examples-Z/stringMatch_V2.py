import re
import difflib


def matchString(s):
  return difflib.SequenceMatcher(None, s, 'hello world').ratio()

  pat = re.compile('(hello|cat)\\ world')
  if pat.match(s):
    return True
  return False

print matchString('hello world')
