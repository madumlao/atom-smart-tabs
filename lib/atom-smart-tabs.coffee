AtomSmartTabsView = require './atom-smart-tabs-view'
{CompositeDisposable} = require 'atom'

module.exports = AtomSmartTabs =
  atomSmartTabsView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @atomSmartTabsView = new AtomSmartTabsView(state.atomSmartTabsViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @atomSmartTabsView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-smart-tabs:toggle': => @toggle()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-smart-tabs:indent': => @indent()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-smart-tabs:outdent': => @outdent()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @atomSmartTabsView.destroy()

  serialize: ->
    atomSmartTabsViewState: @atomSmartTabsView.serialize()

  toggle: ->
    console.log 'AtomSmartTabs was toggled!'

  indent: ->
    console.log 'AtomSmartTabs Indent'
    editor = atom.workspace.getActivePaneItem()
    cursor = editor.getLastCursor()
    savedPosition = cursor.getScreenPosition()

    # if no text is selected, indent only the current line
    if editor.getSelectedText().length == 0
      editor.moveToBeginningOfLine()
      editor.selectToEndOfLine()

    selections = editor.getSelections()
    checkpoint = editor.createCheckpoint()
    @indentSelection(selection) for selection in selections
    editor.groupChangesSinceCheckpoint(checkpoint)

  indentSelection: (selection) ->
    editor = atom.workspace.getActivePaneItem()

    text = selection.getText()
    range = selection.getBufferRowRange()
    start = range[0]
    n = range[1]

    while n >= start
      if n == 0
        prev = ""
      else
        prev = editor.lineTextForBufferRow(n - 1)

      prevIndent = @getIndent(prev)
      next = editor.lineTextForBufferRow(n)
      nextIndent = @getIndent(next)

      # replace the text with the indented form
      newIndent = @getIndentChange(prevIndent, nextIndent)
      @indentLine(n, newIndent.tabs, newIndent.spaces)

      n--

  indentLine: (line, tabs, spaces) ->
    editor = atom.workspace.getActivePaneItem()
    text = editor.lineTextForBufferRow(line)

    newText = ""
    newText += "\t" while tabs-- > 0
    newText += " " while spaces-- > 0
    newText += text.replace(/^\t* */, '')
    return editor.setTextInBufferRange([[line, 0], [line, text.length]], newText)

  getIndent: (text) ->
    i = 0
    tabs = 0
    tabs++ while text.charAt(i++) == "\t"

    spaces = 0
    i-- # also count the last non-tab
    spaces++ while text.charAt(i++) == " "
    return tabs: tabs, spaces: spaces

  getIndentChange: (prev, next) ->
    if prev.tabs == next.tabs && prev.spaces == next.spaces
      return tabs: prev.tabs+1, spaces: prev.spaces
    else if prev.tabs > next.tabs
      return prev
    else if prev.tabs == next.tabs && prev.spaces > next.spaces
      return prev
    return tabs: next.tabs+1, spaces: next.spaces

  getOutdentChange: (prev, next) ->
    if prev.tabs+1 == next.tabs && next.spaces == 0
      return prev
    else if prev.tabs == next.tabs
      if prev.spaces < next.spaces
        return prev
      else if next.spaces > 0
        return tabs: prev.tabs, spaces: 0
      else if prev.tabs > 0
        return tabs: prev.tabs - 1, spaces: 0
      else
        return tabs: 0, spaces: 0
    else if next.spaces > 0
      return tabs: next.tabs, spaces: 0
    else if next.tabs > 0
      return tabs: next.tabs - 1, spaces: 0
    else
      return tabs: 0, spaces: 0

  outdent: ->
    console.log 'AtomSmartTabs Outdent'
    editor = atom.workspace.getActivePaneItem()
    cursor = editor.getLastCursor()
    savedPosition = cursor.getScreenPosition()

    # if no text is selected, indent only the current line
    if editor.getSelectedText().length == 0
      editor.moveToBeginningOfLine()
      editor.selectToEndOfLine()

    selections = editor.getSelections()
    checkpoint = editor.createCheckpoint()
    @outdentSelection(selection) for selection in selections
    editor.groupChangesSinceCheckpoint(checkpoint)

  outdentSelection: (selection) ->
    editor = atom.workspace.getActivePaneItem()

    text = selection.getText()
    range = selection.getBufferRowRange()
    start = range[0]
    n = range[1]

    while n >= start
      if n == 0
        prev = ""
      else
        prev = editor.lineTextForBufferRow(n - 1)

      prevIndent = @getIndent(prev)
      next = editor.lineTextForBufferRow(n)
      nextIndent = @getIndent(next)

      # replace the text with the indented form
      newIndent = @getOutdentChange(prevIndent, nextIndent)
      @indentLine(n, newIndent.tabs, newIndent.spaces)

      n--
