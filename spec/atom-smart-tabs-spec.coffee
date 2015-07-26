AtomSmartTabs = require '../lib/atom-smart-tabs'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "AtomSmartTabs", ->
  [workspaceElement, activationPromise] = []

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = atom.packages.activatePackage('atom-smart-tabs')

  describe "atom-smart-tabs:getIndent", ->
    it "reports 0,0 on a blank line", ->
      indent = AtomSmartTabs.getIndent('')
      expect(indent).toEqual(tabs: 0, spaces: 0)

    it "reports the number of starting tabs/spaces on a line", ->
      indent = AtomSmartTabs.getIndent("\t\t\tHello")
      expect(indent).toEqual(tabs: 3, spaces: 0)

      indent = AtomSmartTabs.getIndent("\t\tworld\t")
      expect(indent).toEqual(tabs: 2, spaces: 0)

      indent = AtomSmartTabs.getIndent("  \t\tHello\tworld")
      expect(indent).toEqual(tabs: 0, spaces: 2)

      indent = AtomSmartTabs.getIndent("\t   Hello world   \t\t")
      expect(indent).toEqual(tabs: 1, spaces: 3)

  describe "atom-smart-tabs:getIndentChange", ->
    it "adds a tab when both indents are the same", ->
      prev = tabs: 0, spaces: 0
      next = tabs: 0, spaces: 0
      indent = AtomSmartTabs.getIndentChange(prev, next)
      expect(indent).toEqual(tabs: 1, spaces: 0)

      prev = tabs: 2, spaces: 0
      next = tabs: 2, spaces: 0
      indent = AtomSmartTabs.getIndentChange(prev, next)
      expect(indent).toEqual(tabs: 3, spaces: 0)

      prev = tabs: 3, spaces: 3
      next = tabs: 3, spaces: 3
      indent = AtomSmartTabs.getIndentChange(prev, next)
      expect(indent).toEqual(tabs: 4, spaces: 3)

    it "aligns to the previous line if the next line is lower in indent", ->
      prev = tabs: 1, spaces: 0
      next = tabs: 0, spaces: 0
      indent = AtomSmartTabs.getIndentChange(prev, next)
      expect(indent).toEqual(prev)

      prev = tabs: 2, spaces: 3
      next = tabs: 1, spaces: 12
      indent = AtomSmartTabs.getIndentChange(prev, next)
      expect(indent).toEqual(prev)

      prev = tabs: 3, spaces: 5
      next = tabs: 3, spaces: 2
      indent = AtomSmartTabs.getIndentChange(prev, next)
      expect(indent).toEqual(prev)

    it "increments by a tab if the next line is equal or higher in indent", ->
      prev = tabs: 1, spaces: 0
      next = tabs: 1, spaces: 1
      indent = AtomSmartTabs.getIndentChange(prev, next)
      expect(indent).toEqual(tabs: 2, spaces: 1)

      prev = tabs: 2, spaces: 8
      next = tabs: 3, spaces: 0
      indent = AtomSmartTabs.getIndentChange(prev, next)
      expect(indent).toEqual(tabs: 4, spaces: 0)

      prev = tabs: 2, spaces: 4
      next = tabs: 2, spaces: 4
      indent = AtomSmartTabs.getIndentChange(prev, next)
      expect(indent).toEqual(tabs: 3, spaces: 4)
  describe "atom-smart-tabs:getOutdentChange", ->
    it "returns 0,0 when attempting to outdent 0,0", ->
      prev = tabs: 0, spaces: 0
      next = tabs: 0, spaces: 0
      indent = AtomSmartTabs.getOutdentChange(prev, next)
      expect(indent).toEqual(tabs: 0, spaces: 0)

    it "removes all spaces when both indents are the same but have spaces", ->
      prev = tabs: 0, spaces: 4
      next = tabs: 0, spaces: 4
      indent = AtomSmartTabs.getOutdentChange(prev, next)
      expect(indent).toEqual(tabs: 0, spaces: 0)

      prev = tabs: 2, spaces: 2
      next = tabs: 2, spaces: 2
      indent = AtomSmartTabs.getOutdentChange(prev, next)
      expect(indent).toEqual(tabs: 2, spaces: 0)

    it "outdents to the previous level when both indents are the same but the next has more spaces", ->
      prev = tabs: 1, spaces: 0
      next = tabs: 1, spaces: 5
      indent = AtomSmartTabs.getOutdentChange(prev, next)
      expect(indent).toEqual(tabs: 1, spaces: 0)

      prev = tabs: 3, spaces: 3
      next = tabs: 3, spaces: 5
      indent = AtomSmartTabs.getOutdentChange(prev, next)
      expect(indent).toEqual(tabs: 3, spaces: 3)

    it "outdents to the previous level when the next line has 1 more tab than previous and no spaces", ->
      prev = tabs: 1, spaces: 0
      next = tabs: 2, spaces: 0
      indent = AtomSmartTabs.getOutdentChange(prev, next)
      expect(indent).toEqual(tabs: 1, spaces: 0)

      prev = tabs: 1, spaces: 4
      next = tabs: 2, spaces: 0
      indent = AtomSmartTabs.getOutdentChange(prev, next)
      expect(indent).toEqual(tabs: 1, spaces: 4)

    it "removes a tab when both indents are the same but have no spaces", ->
      prev = tabs: 1, spaces: 0
      next = tabs: 1, spaces: 0
      indent = AtomSmartTabs.getOutdentChange(prev, next)
      expect(indent).toEqual(tabs: 0, spaces: 0)

      prev = tabs: 3, spaces: 0
      next = tabs: 3, spaces: 0
      indent = AtomSmartTabs.getOutdentChange(prev, next)
      expect(indent).toEqual(tabs: 2, spaces: 0)

    it "removes all spaces if the next line is same or lower in indent", ->
      prev = tabs: 1, spaces: 0
      next = tabs: 0, spaces: 5
      indent = AtomSmartTabs.getOutdentChange(prev, next)
      expect(indent).toEqual(tabs: 0, spaces: 0)

      prev = tabs: 2, spaces: 3
      next = tabs: 2, spaces: 2
      indent = AtomSmartTabs.getOutdentChange(prev, next)
      expect(indent).toEqual(tabs: 2, spaces: 0)

      prev = tabs: 2, spaces: 2
      next = tabs: 2, spaces: 2
      indent = AtomSmartTabs.getOutdentChange(prev, next)
      expect(indent).toEqual(tabs: 2, spaces: 0)

    it "decrements by a tab if the next line has no spaces", ->
      prev = tabs: 2, spaces: 3
      next = tabs: 1, spaces: 0
      indent = AtomSmartTabs.getOutdentChange(prev, next)
      expect(indent).toEqual(tabs: 0, spaces: 0)

      prev = tabs: 2, spaces: 3
      next = tabs: 2, spaces: 0
      indent = AtomSmartTabs.getOutdentChange(prev, next)
      expect(indent).toEqual(tabs: 1, spaces: 0)
