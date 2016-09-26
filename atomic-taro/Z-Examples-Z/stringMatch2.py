import re
import difflib


def matchString(s):
  return difflib.SequenceMatcher(None, s, 'hello world').ratio()



print matchString('hello')
