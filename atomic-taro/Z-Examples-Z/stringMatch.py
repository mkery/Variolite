import re
import difflib



#%%^%%v0
def matchString(s):
  pat = re.compile('(hello|cats)\\ world');
  if pat.match(s):
    return True
  return False
#^^%^^



print matchString('hello world')
