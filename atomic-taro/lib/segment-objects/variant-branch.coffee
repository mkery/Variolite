{Point, Range, TextBuffer} = require 'atom'
JsDiff = require 'diff'
crypto = require 'crypto'
GitUtils = require './git-utils'

'''
Represents a single variant of exploratory code.
'''

'''
  TODO: - commit only when the code has changed (track change sets)
        - compare multiple
        - travel to different versions and commits
        - output data is not recorded with commits
        - can make a commit even when nothing has changed D:
        - Is currentVersion maintained when traveling in commits?
        - How to deal with variant boxes that were dissolved but existed in the past?
'''

module.exports =
class VariantBranch

  # {active: true, id: id, title: title, subtitle: 0, text: text, date: date, branches: [], commits: [], nested: []}
  constructor: (params) ->
    @id = crypto.randomBytes(20).toString('hex')
    @title = params?.title?
    @text = params?.text?
    @date = params?.date?
    @commits = []
    @nested = []
