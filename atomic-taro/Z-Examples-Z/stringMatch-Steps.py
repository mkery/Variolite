import re
import difflib
import sys


def matchString(s):
    print difflib.SequenceMatcher(None, s, 'hello world').ratio()





matchString("hello world")
