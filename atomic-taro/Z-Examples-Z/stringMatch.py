


def matchString(s):
  pat = re.compile('(foo|bar)\\.trailingString');
  if pat.match(s):
    print "matches!"
