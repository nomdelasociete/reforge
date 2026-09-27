import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Ui
import "DiffEngine.js" as DiffEngine

Item {
  id: root

  property string omarchyPath: Quickshell.env("OMARCHY_PATH")
  property var shell: null
  property var manifest: null

  property bool opened: false
  property string page: "trigger"
  property var usage: ({})
  property bool usageCursor: false
  property double lastBackMs: 0
  property string focusSection: "presets"
  property string status: "idle"
  property string sourceText: ""
  property string outputText: ""
  property string errorText: ""
  property string notice: ""
  property string presetName: ""
  property string instruction: ""
  property string agentLabel: ""
  property string filterText: ""
  property string appName: ""
  property string windowTitle: ""
  property string bindTargetId: ""
  property string requestedPreset: ""
  property string presetId: ""
  property string runAgent: ""
  property string windowAddress: ""
  property bool terminalTarget: false
  property bool showDiff: true
  property bool editing: false
  property bool captureBind: false
  property int editRow: 0
  property string editId: ""
  property string editName: ""
  property string editPrompt: ""
  property bool editEnabled: true
  property bool editDiff: true
  property string editAgent: ""
  property string editBind: ""
  property bool editDefault: false
  property var agentChoices: []
  property bool ticketReady: false
  property bool presetsReady: false
  property bool startedOnce: false
  property bool pendingRun: false
  property bool cancelRequested: false
  property int ignoreToken: -1
  property int presetIndex: 0
  property var presets: []
  property var filtered: []

  readonly property string pluginId: (manifest && manifest.id) || "nomdelasociete.recast"
  readonly property string binPath: root.fileUrl(Qt.resolvedUrl("bin/recast"))

  property color background: Color.menu.background
  property color foreground: Color.menu.text
  property color border: Color.menu.border
  property var borderSpec: Border.surfaceSpec("menu", "border", border, Math.max(1, Style.space(2)))
  property color scrim: Color.menu.scrim
  property color selectedBackground: Color.menu.selectedBackground
  property color selectedText: Color.menu.selectedText
  property color accentColor: Color.accent
  property color urgentColor: Color.urgent
  property color mutedColor: Color.muted
  readonly property int cornerRadius: Style.cornerRadius
  property string fontFamily: Style.font.menuFamily
  property int contentMargin: Style.spacing.panelPadding
  property int headerHeight: Math.max(Style.space(52), Style.font.title + Style.font.caption + Style.spacing.md * 3)
  property int contentSpacing: Style.spacing.md
  property int rowHeight: Math.max(Style.space(44), Style.font.body + Style.font.caption + Style.spacing.md)
  property int cardWidth: Math.min(Style.space(760), panel.width - Style.gapsOut * 2)
  property int cardHeight: Math.min(Style.space(560), panel.height - Style.gapsOut * 2)

  function fileUrl(url) {
    var s = String(url || "")
    if (s.indexOf("file://") === 0) s = s.slice(7)
    return decodeURIComponent(s)
  }

  function cssColor(c) {
    var match = String(c).match(/#([0-9a-fA-F]{6,8})/)
    if (!match) return "#888888"
    var hex = match[1]
    if (hex.length === 8) hex = hex.slice(2)
    return "#" + hex
  }

  function parseJson(raw) {
    try {
      var data = JSON.parse(raw || "")
      return data && typeof data === "object" ? data : {}
    } catch (e) {
      return {}
    }
  }

  function rebuildFilter() {
    var query = (root.filterText || "").toLowerCase()
    var out = []
    var list = root.presets || []
    for (var i = 0; i < list.length; i++) {
      var name = String(list[i].name || "")
      if (!query || name.toLowerCase().indexOf(query) !== -1) out.push(list[i])
    }
    root.filtered = out
    if (root.presetIndex >= out.length) root.presetIndex = 0
  }

  function open(payloadJson) {
    root.opened = true
    root.focusSection = "presets"
    root.status = "idle"
    root.sourceText = ""
    root.outputText = ""
    root.errorText = ""
    root.notice = ""
    root.presetName = ""
    root.instruction = ""
    root.agentLabel = ""
    root.filterText = ""
    root.requestedPreset = ""
    root.presetId = ""
    root.runAgent = ""
    root.windowAddress = ""
    root.terminalTarget = false
    root.showDiff = true
    root.page = "trigger"
    root.usageCursor = false
    root.editing = false
    root.captureBind = false
    root.ticketReady = false
    root.presetsReady = false
    root.startedOnce = false
    root.pendingRun = false
    root.cancelRequested = false
    root.presetIndex = 0
    promptField.text = ""
    if (runProc.running) {
      root.ignoreToken = runProc.token
      runProc.signal(15)
    }
    var payload = root.parseJson(payloadJson)
    if (payload.ticket) {
      ticketProc.command = [root.binPath, "take-ticket", String(payload.ticket)]
      ticketProc.running = true
    } else {
      root.errorText = "No selection was captured. Press Super+Shift+R with text selected."
      root.status = "error"
      root.ticketReady = true
    }
    presetProc.command = [root.binPath, "presets"]
    presetProc.running = true
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function close() {
    root.pendingRun = false
    root.cancelRequested = false
    if (runProc.running) {
      root.ignoreToken = runProc.token
      runProc.signal(15)
    }
    root.opened = false
  }

  function dismiss() {
    root.close()
    if (root.shell && typeof root.shell.hide === "function")
      root.shell.hide(root.pluginId)
  }

  function cancel() {
    var now = Date.now()
    if (now - root.lastBackMs < 80) return
    root.lastBackMs = now
    if (root.captureBind) {
      root.captureBind = false
      root.bindTargetId = ""
      return
    }
    if (root.editing) {
      root.editing = false
      root.page = "trigger"
      root.focusSection = "presets"
      keyCatcher.forceActiveFocus()
      return
    }
    if (promptField.activeFocus || root.focusSection === "prompt") {
      root.focusSection = "presets"
      keyCatcher.forceActiveFocus()
      return
    }
    if (root.page === "usage") {
      root.page = "trigger"
      root.usageCursor = true
      root.focusSection = "presets"
      keyCatcher.forceActiveFocus()
      return
    }
    if (root.status === "running" || root.status === "ready" || root.focusSection === "result") {
      if (runProc.running) {
        root.ignoreToken = runProc.token
        runProc.signal(15)
      }
      root.status = "idle"
      root.focusSection = "presets"
      root.errorText = ""
      root.page = "trigger"
      keyCatcher.forceActiveFocus()
      return
    }
    if (root.filterText) {
      root.filterText = ""
      return
    }
    root.dismiss()
  }

  function recordUsage(kind, chars) {
    if (usageProc.running) return
    usageProc.request = JSON.stringify({
      kind: kind,
      id: root.presetId || "prompt",
      name: root.presetName || "Prompt",
      chars: chars || 0
    }) + "\n"
    usageProc.command = [root.binPath, "record"]
    usageProc.running = true
  }

  function openUsage() {
    root.page = "usage"
    root.editing = false
    root.usageCursor = false
    root.focusSection = "presets"
    usageLoad.command = [root.binPath, "usage"]
    usageLoad.running = true
    keyCatcher.forceActiveFocus()
  }

  function groupInt(value) {
    var text = String(Math.max(0, Math.round(value || 0)))
    return text.replace(/\B(?=(\d{3})+(?!\d))/g, " ")
  }

  function usagePrompts() {
    return (root.usage && root.usage.prompts) || []
  }

  function usageUsesChars() {
    var prompts = root.usagePrompts()
    for (var i = 0; i < prompts.length; i++) {
      if ((prompts[i].charsChanged || 0) > 0) return true
    }
    return false
  }

  function usageBarValue(prompt) {
    if (!prompt) return 0
    return root.usageUsesChars() ? (prompt.charsChanged || 0) : (prompt.runs || 0)
  }

  function usageBarMax() {
    var prompts = root.usagePrompts()
    var max = 1
    for (var i = 0; i < prompts.length; i++) max = Math.max(max, root.usageBarValue(prompts[i]))
    return max
  }

  function actionSlices() {
    var usage = root.usage || {}
    var slices = []
    if ((usage.casts || 0) > 0) slices.push({ label: "Cast", value: usage.casts, color: root.cssColor(root.accentColor) })
    if ((usage.copies || 0) > 0) slices.push({ label: "Copy", value: usage.copies, color: root.cssColor(root.foreground) })
    if ((usage.handoffs || 0) > 0) slices.push({ label: "Handoff", value: usage.handoffs, color: root.cssColor(root.mutedColor) })
    return slices
  }

  function applyTicket(raw) {
    var data = root.parseJson(raw)
    root.requestedPreset = String(data.preset || "")
    root.appName = String(data.app || "")
    root.windowTitle = String(data.title || "")
    if (data.ok && data.text) {
      root.sourceText = String(data.text)
      root.windowAddress = String(data.window || "")
      root.terminalTarget = data.terminal === true
      root.errorText = ""
    } else {
      root.sourceText = ""
      root.errorText = ""
      root.notice = data.error || "Nothing was copied. Is any text selected?"
      root.status = "idle"
    }
    root.ticketReady = true
    root.maybeStart()
  }

  function applyPresets(raw) {
    var data = root.parseJson(raw)
    root.presets = data.presets || []
    if (!data.ok && data.error) root.notice = data.error
    root.rebuildFilter()
    root.presetsReady = true
    root.maybeStart()
  }

  function presetById(id) {
    for (var i = 0; i < root.presets.length; i++) {
      if (root.presets[i].id === id) return root.presets[i]
    }
    return null
  }

  function defaultPreset() {
    for (var i = 0; i < root.presets.length; i++) {
      if (root.presets[i].default && root.presets[i].enabled !== false) return root.presets[i]
    }
    return null
  }

  function selectPreset(preset) {
    if (!preset) return
    for (var i = 0; i < root.filtered.length; i++) {
      if (root.filtered[i].id === preset.id) {
        root.presetIndex = i
        return
      }
    }
  }

  function maybeStart() {
    if (!root.ticketReady || !root.presetsReady || root.startedOnce) return
    root.startedOnce = true
    var preset = root.requestedPreset ? root.presetById(root.requestedPreset) : root.defaultPreset()
    if (root.requestedPreset && !preset) root.notice = "That prompt is gone"
    if (preset && preset.enabled === false) {
      root.notice = "That prompt is off"
      root.focusSection = "presets"
      root.selectPreset(preset)
      return
    }
    root.focusSection = "presets"
    root.selectPreset(preset || root.defaultPreset())
    if (root.requestedPreset && root.sourceText && preset) root.startRun(preset)
  }

  function startRun(preset) {
    if (!preset || preset.enabled === false) return
    if (!root.sourceText) {
      root.notice = "Nothing selected"
      root.focusSection = "presets"
      return
    }
    var prompt = String(preset.prompt || "").replace(/^\s+|\s+$/g, "")
    if (!prompt) return
    root.presetId = String(preset.id || "")
    root.presetName = String(preset.name || "Prompt")
    root.instruction = prompt
    root.runAgent = String(preset.agent || "")
    root.showDiff = preset.diff !== false
    root.editing = false
    root.status = "running"
    root.outputText = ""
    root.errorText = ""
    root.notice = ""
    root.focusSection = "result"
    if (runProc.running) {
      root.pendingRun = true
      runProc.signal(15)
      return
    }
    root.launchRun()
  }

  function launchRun() {
    root.pendingRun = false
    runProc.token += 1
    runProc.request = JSON.stringify({
      text: root.sourceText,
      prompt: root.instruction,
      agent: root.runAgent,
      app: root.appName
    }) + "\n"
    runProc.command = [root.binPath, "run"]
    runProc.running = true
  }

  function finishRun(token, text, code) {
    if (token === root.ignoreToken) return
    if (root.pendingRun) {
      root.pendingRun = false
      if (root.opened) root.launchRun()
      return
    }
    if (token !== runProc.token || !root.opened) return
    var data = root.parseJson(text)
    if (data.ok && String(data.output || "").replace(/\s/g, "").length) {
      root.outputText = String(data.output)
      root.agentLabel = String(data.label || data.agent || "")
      root.status = "ready"
      root.errorText = ""
      root.focusSection = "result"
      root.page = "trigger"
      root.recordUsage("run", DiffEngine.charsChanged(root.sourceText, root.outputText))
      keyCatcher.forceActiveFocus()
      return
    }
    root.status = "error"
    if (code === 143) root.errorText = "Stopped"
    else root.errorText = data.error || "The agent returned nothing"
  }

  function retransform() {
    if (!root.sourceText || !root.instruction) return
    root.startRun({
      id: root.presetId,
      name: root.presetName || "Prompt",
      prompt: root.instruction,
      enabled: true,
      diff: root.showDiff,
      agent: root.runAgent
    })
  }

  function runPromptField() {
    root.startRun({
      id: "",
      name: "Prompt",
      prompt: promptField.text,
      enabled: true,
      diff: true,
      agent: ""
    })
  }

  function slug(name) {
    var s = String(name || "").toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "")
    return s.slice(0, 40) || "prompt"
  }

  function presetMeta(preset) {
    var bits = []
    if (preset.default) bits.push("default")
    if (preset.enabled === false) bits.push("off")
    if (preset.diff === false) bits.push("no diff")
    if (preset.agent) bits.push(preset.agent)
    if (preset.bind) bits.push(preset.bind)
    return bits.join("  ·  ")
  }

  function openEditor(index) {
    var preset = index >= 0 ? root.filtered[index] : null
    root.editing = true
    root.captureBind = false
    root.editRow = 0
    root.focusSection = "edit"
    if (preset) {
      root.editId = String(preset.id || "")
      root.editName = String(preset.name || "")
      root.editPrompt = String(preset.prompt || "")
      root.editEnabled = preset.enabled !== false
      root.editDiff = preset.diff !== false
      root.editAgent = String(preset.agent || "")
      root.editBind = String(preset.bind || "")
      root.editDefault = preset.default === true
    } else {
      root.editId = ""
      root.editName = ""
      root.editPrompt = ""
      root.editEnabled = true
      root.editDiff = true
      root.editAgent = ""
      root.editBind = ""
      root.editDefault = false
    }
    if (!agentProc.running) {
      agentProc.command = [root.binPath, "agents"]
      agentProc.running = true
    }
    Qt.callLater(function() {
      nameField.text = root.editName
      promptArea.text = root.editPrompt
      nameField.forceActiveFocus()
    })
  }

  function editPresetObject() {
    return {
      id: root.editId || root.slug(root.editName),
      name: String(root.editName || "").replace(/^\s+|\s+$/g, ""),
      prompt: String(root.editPrompt || "").replace(/^\s+|\s+$/g, ""),
      enabled: root.editEnabled,
      diff: root.editDiff,
      agent: root.editAgent,
      bind: root.editBind,
      default: root.editDefault
    }
  }

  function saveEditor() {
    var next = root.editPresetObject()
    if (!next.name || !next.prompt) {
      root.notice = "A prompt needs a name and text"
      return
    }
    var list = []
    var replaced = false
    for (var i = 0; i < root.presets.length; i++) {
      var item = root.presets[i]
      if (item.id === root.editId && root.editId) {
        list.push(next)
        replaced = true
      } else if (next.default) {
        var copy = {}
        for (var key in item) copy[key] = item[key]
        copy.default = false
        list.push(copy)
      } else {
        list.push(item)
      }
    }
    if (!replaced) list.push(next)
    if (saveProc.running) return
    saveProc.request = JSON.stringify({ presets: list }) + "\n"
    saveProc.command = [root.binPath, "save"]
    saveProc.running = true
  }

  function finishSave(raw) {
    var data = root.parseJson(raw)
    if (!data.ok) {
      root.notice = data.error || "Could not save"
      return
    }
    root.presets = data.presets || []
    root.rebuildFilter()
    root.editing = false
    root.captureBind = false
    root.focusSection = "presets"
    root.notice = "Saved"
    root.selectPreset(root.presetById(root.editId) || root.defaultPreset())
    keyCatcher.forceActiveFocus()
  }

  function deleteEditor() {
    if (!root.editId) {
      root.editing = false
      root.focusSection = "presets"
      return
    }
    var list = []
    for (var i = 0; i < root.presets.length; i++) {
      if (root.presets[i].id !== root.editId) list.push(root.presets[i])
    }
    if (!list.length) {
      root.notice = "Keep at least one prompt"
      return
    }
    if (saveProc.running) return
    saveProc.request = JSON.stringify({ presets: list }) + "\n"
    saveProc.command = [root.binPath, "save"]
    saveProc.running = true
  }

  function agentLabelFor(id) {
    for (var i = 0; i < root.agentChoices.length; i++) {
      if (root.agentChoices[i].id === id) return root.agentChoices[i].label
    }
    return id ? id : "Default"
  }

  function cycleAgent(direction) {
    var ids = []
    for (var i = 0; i < root.agentChoices.length; i++) ids.push(root.agentChoices[i].id)
    if (!ids.length) ids = [""]
    var index = ids.indexOf(root.editAgent)
    if (index < 0) index = 0
    index = (index + direction + ids.length) % ids.length
    root.editAgent = ids[index]
  }

  function optionLabel(index) {
    return ["Enabled", "Diff", "Agent", "Key", "Default"][index] || ""
  }

  function optionValue(index) {
    if (index === 0) return root.editEnabled ? "on" : "off"
    if (index === 1) return root.editDiff ? "on" : "off"
    if (index === 2) return root.agentLabelFor(root.editAgent)
    if (index === 3) return root.captureBind ? "press a chord…" : (root.editBind || "none")
    return root.editDefault ? "yes" : "no"
  }

  function activateOption(index) {
    if (root.captureBind && index !== 3) root.captureBind = false
    root.editRow = index
    nameField.focus = false
    promptArea.focus = false
    keyCatcher.forceActiveFocus()
    root.toggleEditRow()
  }

  function toggleEditRow() {
    if (root.editRow === 0) root.editEnabled = !root.editEnabled
    else if (root.editRow === 1) root.editDiff = !root.editDiff
    else if (root.editRow === 2) root.cycleAgent(1)
    else if (root.editRow === 3) {
      root.bindTargetId = ""
      root.captureBind = true
    }
    else if (root.editRow === 4) root.editDefault = !root.editDefault
  }

  function chordFromEvent(event) {
    var parts = []
    if (event.modifiers & Qt.MetaModifier) parts.push("SUPER")
    if (event.modifiers & Qt.AltModifier) parts.push("ALT")
    if (event.modifiers & Qt.ControlModifier) parts.push("CTRL")
    if (event.modifiers & Qt.ShiftModifier && parts.length) parts.push("SHIFT")
    if (!parts.length) return ""
    var key = ""
    if (event.key >= Qt.Key_A && event.key <= Qt.Key_Z) key = String.fromCharCode(event.key)
    else if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9) key = String.fromCharCode(event.key)
    else if (event.key >= Qt.Key_F1 && event.key <= Qt.Key_F12) key = "F" + (event.key - Qt.Key_F1 + 1)
    else return ""
    parts.push(key)
    var chord = parts.join(" + ")
    if (chord === "SUPER + SHIFT + R") {
      root.notice = "Super+Shift+R opens [RE]Cast"
      return ""
    }
    return chord
  }

  function remember(name) {
    if (rememberProc.running) return
    rememberProc.request = JSON.stringify({ name: name }) + "\n"
    rememberProc.command = [root.binPath, "remember"]
    rememberProc.running = true
  }

  function copyResult() {
    if (!root.outputText || copyProc.running) return
    copyProc.request = JSON.stringify({ text: root.outputText }) + "\n"
    copyProc.command = [root.binPath, "copy"]
    copyProc.running = true
  }

  function cast() {
    if (root.status !== "ready" || !root.outputText || putProc.running) return
    root.notice = ""
    root.opened = false
    putProc.request = JSON.stringify({
      text: root.outputText,
      window: root.windowAddress,
      terminal: root.terminalTarget
    }) + "\n"
    putProc.command = [root.binPath, "put"]
    putProc.running = true
  }

  function finishCast(raw) {
    var data = root.parseJson(raw)
    if (data.ok) {
      root.recordUsage("cast", 0)
      root.dismiss()
      return
    }
    root.opened = true
    root.status = "ready"
    root.notice = data.error || "Could not paste. The answer is on your clipboard"
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function handoff() {
    if (!root.sourceText && !root.outputText) return
    if (handoffProc.running) return
    handoffProc.request = JSON.stringify({
      prompt: root.instruction,
      text: root.sourceText,
      output: root.outputText
    }) + "\n"
    handoffProc.command = [root.binPath, "handoff"]
    handoffProc.running = true
    root.recordUsage("handoff", 0)
    root.dismiss()
  }

  function cycle(direction) {
    var order = ["presets", "prompt", "result"]
    var index = order.indexOf(root.focusSection)
    if (index < 0) index = 0
    index = (index + direction + order.length) % order.length
    root.focusSection = order[index]
    if (root.focusSection === "prompt") promptField.forceActiveFocus()
    else keyCatcher.forceActiveFocus()
  }

  function move(direction) {
    if (root.focusSection === "presets" && root.page === "trigger") {
      if (direction > 0 && !root.usageCursor && root.presetIndex >= root.filtered.length - 1) {
        root.usageCursor = true
        return
      }
      if (direction < 0 && root.usageCursor) {
        root.usageCursor = false
        return
      }
      root.usageCursor = false
      if (!root.filtered.length) return
      var next = root.presetIndex + direction
      if (next < 0) next = root.filtered.length - 1
      if (next >= root.filtered.length) next = 0
      root.presetIndex = next
      presetList.positionViewAtIndex(next, ListView.Contain)
      return
    }
    if (root.focusSection === "result") {
      var limit = Math.max(0, resultFlick.contentHeight - resultFlick.height)
      resultFlick.contentY = Math.max(0, Math.min(limit, resultFlick.contentY + direction * 48))
    }
  }

  function activate() {
    if (root.usageCursor && root.page === "trigger") {
      root.openUsage()
      return
    }
    if (root.focusSection === "presets") {
      var row = root.filtered[root.presetIndex]
      if (!row) return
      if (row.enabled === false) root.openEditor(root.presetIndex)
      else root.startRun(row)
      return
    }
    root.cast()
  }

  function contextLine() {
    var app = root.appName || "No app"
    var text = String(root.sourceText || "").replace(/\s+/g, " ").replace(/^\s+|\s+$/g, "")
    if (text.length > 72) text = text.slice(0, 72) + "…"
    if (!text) text = "No selection"
    return app + "  ·  " + text
  }

  function savePresets(list) {
    if (saveProc.running) return
    saveProc.request = JSON.stringify({ presets: list }) + "\n"
    saveProc.command = [root.binPath, "save"]
    saveProc.running = true
  }

  function beginBind() {
    var row = root.filtered[root.presetIndex]
    if (!row) return
    root.bindTargetId = row.id
    root.captureBind = true
    root.notice = "Key for " + row.name
  }

  function finishBind(chord) {
    var target = root.bindTargetId
    root.captureBind = false
    root.bindTargetId = ""
    if (!target) {
      root.editBind = chord || ""
      return
    }
    var list = []
    for (var i = 0; i < root.presets.length; i++) {
      var item = {}
      var key
      for (key in root.presets[i]) item[key] = root.presets[i][key]
      if (item.id === target) item.bind = chord || ""
      else if (chord && item.bind === chord) item.bind = ""
      list.push(item)
    }
    root.savePresets(list)
  }

  function headerTitle() {
    if (root.page === "usage") return "Usage"
    if (root.editing) return "Edit"
    if (root.status === "running") return "Running"
    if (root.status === "ready") return "Ready"
    if (root.status === "error") return "Error"
    return "Trigger"
  }

  function footerText() {
    if (root.captureBind) return "Press Super, Alt, or Ctrl plus a key  ·  Backspace clears  ·  Esc back"
    if (root.page === "usage") return "Esc back"
    if (root.editing) return (root.notice ? root.notice + "  ·  " : "") + "Click a setting to change it  ·  Ctrl+S save  ·  Esc back"
    if (root.notice) return root.notice
    if (root.status === "running") return "Esc back  ·  Ctrl+R run again"
    if (root.status === "ready" || root.focusSection === "prompt") return root.focusSection === "prompt"
      ? "Enter runs this prompt  ·  Esc back"
      : "Enter cast  ·  Ctrl+R again  ·  Ctrl+D diff  ·  Ctrl+C copy  ·  Ctrl+A agent  ·  Esc back"
    return "Enter run  ·  Ctrl+E edit  ·  Ctrl+U usage  ·  Esc close"
  }

  readonly property string diffHtml: {
    if (!root.outputText) return ""
    var diff = DiffEngine.diffWords(root.sourceText, root.outputText)
    return DiffEngine.toRichText(diff.parts, root.cssColor(root.urgentColor), root.cssColor(root.accentColor), root.cssColor(root.mutedColor))
  }

  onFilterTextChanged: {
    root.presetIndex = 0
    root.rebuildFilter()
  }

  Process {
    id: ticketProc
    stdout: StdioCollector {
      id: ticketOut
      waitForEnd: true
    }
    onExited: Qt.callLater(function() { root.applyTicket(ticketOut.text) })
  }

  Process {
    id: presetProc
    stdout: StdioCollector {
      id: presetOut
      waitForEnd: true
    }
    onExited: Qt.callLater(function() { root.applyPresets(presetOut.text) })
  }

  Process {
    id: runProc
    property int token: 0
    property string request: ""
    stdinEnabled: true
    stdout: StdioCollector {
      id: runOut
      waitForEnd: true
    }
    onStarted: write(request)
    onExited: function(exitCode) {
      var finishedToken = runProc.token
      var text = runOut.text
      Qt.callLater(function() { root.finishRun(finishedToken, text, exitCode) })
    }
  }

  Process {
    id: copyProc
    property string request: ""
    stdinEnabled: true
    stdout: StdioCollector { waitForEnd: true }
    onStarted: write(request)
    onExited: function(exitCode) {
      if (exitCode === 0) {
        root.notice = "Copied"
        root.recordUsage("copy", 0)
      }
    }
  }

  Process {
    id: putProc
    property string request: ""
    stdinEnabled: true
    stdout: StdioCollector {
      id: putOut
      waitForEnd: true
    }
    onStarted: write(request)
    onExited: Qt.callLater(function() { root.finishCast(putOut.text) })
  }

  Process {
    id: saveProc
    property string request: ""
    stdinEnabled: true
    stdout: StdioCollector {
      id: saveOut
      waitForEnd: true
    }
    onStarted: write(request)
    onExited: Qt.callLater(function() { root.finishSave(saveOut.text) })
  }

  Process {
    id: agentProc
    stdout: StdioCollector {
      id: agentOut
      waitForEnd: true
    }
    onExited: Qt.callLater(function() {
      var data = root.parseJson(agentOut.text)
      if (data.agents) root.agentChoices = data.agents
    })
  }

  Process {
    id: rememberProc
    property string request: ""
    stdinEnabled: true
    stdout: StdioCollector { waitForEnd: true }
    onStarted: write(request)
  }

  Process {
    id: usageProc
    property string request: ""
    stdinEnabled: true
    stdout: StdioCollector { waitForEnd: true }
    onStarted: write(request)
  }

  Process {
    id: usageLoad
    stdout: StdioCollector {
      id: usageOut
      waitForEnd: true
    }
    onExited: Qt.callLater(function() {
      var data = root.parseJson(usageOut.text)
      if (data.ok) root.usage = data
    })
  }

  Process {
    id: handoffProc
    property string request: ""
    stdinEnabled: true
    stdout: StdioCollector { waitForEnd: true }
    onStarted: write(request)
  }

  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "nomdelasociete-recast"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    Shortcut {
      sequence: "Escape"
      context: Qt.WindowShortcut
      enabled: root.opened
      onActivated: root.cancel()
    }

    Rectangle {
      anchors.fill: parent
      color: root.scrim
    }

    MouseArea {
      anchors.fill: parent
      onClicked: root.dismiss()
    }

    BorderSurface {
      id: card
      width: root.cardWidth
      height: root.cardHeight
      radius: root.cornerRadius
      anchors.centerIn: parent
      color: root.background
      borderSpec: root.borderSpec
      padding: root.contentMargin

      MouseArea { anchors.fill: parent; onClicked: {} }

      Item {
        id: keyCatcher
        anchors.fill: parent
        focus: true
        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
          var ctrl = (event.modifiers & Qt.ControlModifier)
            && !(event.modifiers & Qt.AltModifier)
            && !(event.modifiers & Qt.MetaModifier)
          if (root.captureBind) {
            if (event.key === Qt.Key_Escape) root.cancel()
            else if (event.key === Qt.Key_Backspace) root.finishBind("")
            else {
              var captured = root.chordFromEvent(event)
              if (captured) root.finishBind(captured)
            }
            event.accepted = true
            return
          }
          if (root.editing) {
            if (event.key === Qt.Key_Escape) {
              root.cancel()
              event.accepted = true
              return
            }
            if (ctrl && event.key === Qt.Key_S) {
              root.saveEditor()
              event.accepted = true
              return
            }
            if (nameField.activeFocus || promptArea.activeFocus) {
              if (event.key === Qt.Key_Down) {
                root.editRow = 0
                nameField.focus = false
                promptArea.focus = false
                keyCatcher.forceActiveFocus()
                event.accepted = true
              }
              return
            }
            if (ctrl && (event.key === Qt.Key_X || event.text === "x" || event.text === "X")) {
              root.deleteEditor()
              event.accepted = true
              return
            }
            if (event.key === Qt.Key_Up) { root.editRow = Math.max(0, root.editRow - 1); event.accepted = true; return }
            if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) { root.editRow = Math.min(4, root.editRow + 1); event.accepted = true; return }
            if (event.key === Qt.Key_Left) { if (root.editRow === 2) root.cycleAgent(-1); event.accepted = true; return }
            if (event.key === Qt.Key_Right) { if (root.editRow === 2) root.cycleAgent(1); event.accepted = true; return }
            if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
              root.toggleEditRow()
              event.accepted = true
              return
            }
            return
          }
          if (event.key === Qt.Key_Escape) {
            root.cancel()
            event.accepted = true
            return
          }
          if (ctrl && event.key === Qt.Key_U && !root.editing && root.page === "trigger") {
            root.openUsage()
            event.accepted = true
            return
          }
          if (ctrl && (event.key === Qt.Key_E) && root.focusSection === "presets") {
            root.openEditor(root.presetIndex)
            event.accepted = true
            return
          }
          if (ctrl && (event.key === Qt.Key_N) && root.focusSection === "presets") {
            root.openEditor(-1)
            event.accepted = true
            return
          }
          if (ctrl && (event.key === Qt.Key_K) && root.focusSection === "presets") {
            root.beginBind()
            event.accepted = true
            return
          }
          if (ctrl && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
            root.cast()
            event.accepted = true
            return
          }
          if (ctrl && (event.key === Qt.Key_R || event.text === "r" || event.text === "R")) {
            root.retransform()
            event.accepted = true
            return
          }
          if (promptField.activeFocus) return

          if (ctrl && (event.key === Qt.Key_D || event.text === "d" || event.text === "D")) {
            if (root.outputText) root.showDiff = !root.showDiff
            event.accepted = true
            return
          }
          if (ctrl && (event.key === Qt.Key_C || event.text === "c" || event.text === "C")) {
            root.copyResult()
            event.accepted = true
            return
          }
          if (ctrl && (event.key === Qt.Key_A || event.text === "a" || event.text === "A")) {
            root.handoff()
            event.accepted = true
            return
          }
          if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
            root.cycle((event.modifiers & Qt.ShiftModifier) || event.key === Qt.Key_Backtab ? -1 : 1)
            event.accepted = true
            return
          }
          if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.activate()
            event.accepted = true
            return
          }
          if (event.key === Qt.Key_Up || event.key === Qt.Key_Down) {
            root.move(event.key === Qt.Key_Up ? -1 : 1)
            event.accepted = true
            return
          }
          if (root.focusSection === "presets" && Util.editsFilter(event, root.filterText)) {
            root.filterText = Util.editedFilter(event, root.filterText)
            event.accepted = true
            return
          }
          if (root.focusSection === "presets" && event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 32 && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) {
            root.filterText += event.text
            event.accepted = true
          }
        }

      Column {
        anchors.fill: parent
        anchors.topMargin: card.contentTopInset
        anchors.rightMargin: card.contentRightInset
        anchors.bottomMargin: card.contentBottomInset
        anchors.leftMargin: card.contentLeftInset
        spacing: root.contentSpacing

        Item {
          width: parent.width
          height: root.headerHeight

          Column {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.spacing.xs

            Text {
              width: parent.width
              textFormat: Text.PlainText
              text: "[RE]Cast  ·  " + root.headerTitle()
                + (root.status === "running" || root.status === "ready" || root.editing ? (root.presetName ? "  ·  " + root.presetName : "") : "")
                + (root.agentLabel && root.status !== "idle" ? "  ·  " + root.agentLabel : "")
                + (root.focusSection === "presets" && root.filterText ? "  ·  " + root.filterText : "")
              color: root.status === "error" ? root.urgentColor : root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.title
              elide: Text.ElideRight
            }

            Text {
              width: parent.width
              visible: !root.editing && root.status !== "running"
              textFormat: Text.PlainText
              text: root.contextLine()
              color: root.mutedColor
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              elide: Text.ElideRight
            }
          }
        }

        Item {
          id: body
          width: parent.width
          height: parent.height - root.headerHeight - (root.editing ? 0 : promptField.implicitHeight) - footer.implicitHeight - root.contentSpacing * 3

          ListView {
            id: presetList
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: usageEntry.top
            visible: root.page === "trigger" && !root.editing && root.focusSection === "presets" && root.status !== "running" && root.status !== "ready"
            model: root.filtered
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            delegate: Rectangle {
              required property int index
              required property var modelData
              width: presetList.width
              height: root.rowHeight
              radius: root.cornerRadius
              color: !root.usageCursor && index === root.presetIndex && root.focusSection === "presets" ? root.selectedBackground : "transparent"

              Text {
                id: keyLabel
                anchors.right: parent.right
                anchors.rightMargin: Style.spacing.rowPaddingX
                anchors.verticalCenter: parent.verticalCenter
                textFormat: Text.PlainText
                text: modelData.bind || "set key"
                color: modelData.bind ? root.accentColor : root.mutedColor
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
              }

              Column {
                anchors.left: parent.left
                anchors.right: keyLabel.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Style.spacing.rowPaddingX
                anchors.rightMargin: Style.spacing.sm
                spacing: 0

                Text {
                  width: parent.width
                  textFormat: Text.PlainText
                  text: modelData.name
                  color: modelData.enabled === false
                    ? root.mutedColor
                    : (index === root.presetIndex && root.focusSection === "presets" ? root.selectedText : root.foreground)
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  elide: Text.ElideRight
                }

                Text {
                  width: parent.width
                  visible: root.presetMeta(modelData) !== ""
                  textFormat: Text.PlainText
                  text: root.presetMeta(modelData)
                  color: root.mutedColor
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  elide: Text.ElideRight
                }
              }

              MouseArea {
                anchors.left: parent.left
                anchors.right: keyLabel.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                onClicked: {
                  root.presetIndex = index
                  root.focusSection = "presets"
                  if (modelData.enabled === false) root.openEditor(index)
                  else root.startRun(modelData)
                }
              }

              MouseArea {
                anchors.fill: keyLabel
                onClicked: {
                  root.presetIndex = index
                  root.focusSection = "presets"
                  root.beginBind()
                }
              }
            }
          }

          Text {
            anchors.fill: parent
            visible: presetList.visible && root.filtered.length === 0
            textFormat: Text.PlainText
            text: "No matching prompt"
            color: root.mutedColor
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
          }

          Flickable {
            id: resultFlick
            anchors.fill: parent
            visible: root.page === "trigger" && !root.editing && (root.status === "running" || root.status === "ready" || root.focusSection === "result")
            clip: true
            contentWidth: width
            contentHeight: resultText.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            Text {
              id: resultText
              width: resultFlick.width
              textFormat: root.showDiff && root.status === "ready" ? Text.RichText : Text.PlainText
              wrapMode: Text.Wrap
              text: root.status === "running"
                ? "Running…"
                : (root.status === "error"
                  ? root.errorText
                  : (root.showDiff ? root.diffHtml : root.outputText))
              color: root.status === "error" ? root.urgentColor : root.foreground
              font.family: Style.font.family
              font.pixelSize: Style.font.body
            }
          }

          Rectangle {
            id: usageEntry
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: visible ? root.rowHeight : 0
            visible: root.page === "trigger" && !root.editing && root.status !== "running" && root.status !== "ready" && root.focusSection === "presets"
            radius: root.cornerRadius
            color: root.usageCursor ? root.selectedBackground : "transparent"

            Text {
              anchors.left: parent.left
              anchors.leftMargin: Style.spacing.rowPaddingX
              anchors.verticalCenter: parent.verticalCenter
              textFormat: Text.PlainText
              text: "Usage"
              color: root.usageCursor ? root.selectedText : root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
            }

            Text {
              anchors.right: parent.right
              anchors.rightMargin: Style.spacing.rowPaddingX
              anchors.verticalCenter: parent.verticalCenter
              textFormat: Text.PlainText
              text: root.usage.runs ? root.groupInt(root.usage.runs) + " runs" : "Ctrl+U"
              color: root.mutedColor
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.openUsage()
            }
          }

          Flickable {
            id: usageFlick
            anchors.fill: parent
            visible: root.page === "usage"
            clip: true
            contentWidth: width
            contentHeight: usageColumn.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            Column {
              id: usageColumn
              width: usageFlick.width
              spacing: Style.spacing.lg

              Text {
                width: parent.width
                visible: !(root.usage.runs > 0)
                textFormat: Text.PlainText
                text: "No runs yet"
                color: root.mutedColor
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
              }

              Text {
                width: parent.width
                visible: root.usage.runs > 0
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                text: root.groupInt(root.usage.runs) + " runs  ·  "
                  + root.groupInt(root.usage.charsChanged) + " characters changed"
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
              }

              Row {
                width: parent.width
                spacing: Style.spacing.lg
                visible: root.actionSlices().length > 1

                Canvas {
                  id: actionPie
                  width: Style.space(72)
                  height: Style.space(72)
                  property int paintKey: (root.usage.casts || 0) + (root.usage.copies || 0) * 17 + (root.usage.handoffs || 0) * 31
                  onPaintKeyChanged: requestPaint()
                  onWidthChanged: requestPaint()
                  onVisibleChanged: requestPaint()
                  onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    var slices = root.actionSlices()
                    var total = 0
                    for (var i = 0; i < slices.length; i++) total += slices[i].value
                    if (total <= 0) return
                    var start = -Math.PI / 2
                    var cx = width / 2
                    var cy = height / 2
                    var radius = Math.min(width, height) / 2 - 1
                    for (var s = 0; s < slices.length; s++) {
                      var sweep = slices[s].value / total * Math.PI * 2
                      ctx.beginPath()
                      ctx.moveTo(cx, cy)
                      ctx.arc(cx, cy, radius, start, start + sweep)
                      ctx.closePath()
                      ctx.fillStyle = slices[s].color
                      ctx.fill()
                      start += sweep
                    }
                  }
                }

                Column {
                  width: parent.width - actionPie.width - parent.spacing
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: Style.spacing.sm

                  Repeater {
                    model: root.actionSlices()
                    delegate: Row {
                      required property var modelData
                      width: parent.width
                      spacing: Style.spacing.sm

                      Rectangle {
                        width: Style.space(8)
                        height: Style.space(8)
                        radius: Style.space(2)
                        anchors.verticalCenter: parent.verticalCenter
                        color: modelData.color
                      }

                      Text {
                        textFormat: Text.PlainText
                        text: modelData.label + "  " + root.groupInt(modelData.value)
                        color: root.foreground
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.body
                      }
                    }
                  }
                }
              }

              Column {
                width: parent.width
                spacing: Style.spacing.md
                visible: root.usagePrompts().length > 0

                Text {
                  width: parent.width
                  textFormat: Text.PlainText
                  text: root.usageUsesChars() ? "Characters changed" : "Runs"
                  color: root.mutedColor
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                }

                Repeater {
                  model: root.usagePrompts()
                  delegate: Column {
                    required property var modelData
                    width: usageColumn.width
                    spacing: Style.spacing.xs

                    Row {
                      width: parent.width
                      Text {
                        width: parent.width * 0.72
                        textFormat: Text.PlainText
                        text: modelData.name || modelData.id
                        color: root.foreground
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.body
                        elide: Text.ElideRight
                      }
                      Text {
                        width: parent.width * 0.28
                        horizontalAlignment: Text.AlignRight
                        textFormat: Text.PlainText
                        text: root.groupInt(root.usageBarValue(modelData))
                        color: root.mutedColor
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                      }
                    }

                    Rectangle {
                      width: parent.width
                      height: Style.space(6)
                      radius: height / 2
                      color: root.selectedBackground

                      Rectangle {
                        width: Math.max(Style.space(2), parent.width * root.usageBarValue(modelData) / root.usageBarMax())
                        height: parent.height
                        radius: height / 2
                        color: root.accentColor
                      }
                    }
                  }
                }
              }
            }
          }

          Column {
            id: editor
            anchors.fill: parent
            visible: root.editing
            spacing: Style.spacing.sm

            TextField {
              id: nameField
              width: parent.width
              placeholderText: "Name"
              font.family: root.fontFamily
              onTextChanged: root.editName = text
              onActiveFocusChanged: {
                if (activeFocus) root.editRow = -1
              }
            }

            Text {
              id: variableHint
              width: parent.width
              textFormat: Text.PlainText
              wrapMode: Text.Wrap
              text: "{app} is the app in front. {selection} is the selected text. Put either where you want them in the prompt."
              color: root.mutedColor
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }

            Flickable {
              id: promptFlick
              width: parent.width
              height: Math.max(Style.space(70), editor.height - nameField.height - variableHint.height - editOptions.height - Style.spacing.sm * 3)
              contentWidth: width
              contentHeight: promptArea.implicitHeight
              clip: true
              boundsBehavior: Flickable.StopAtBounds

              TextArea {
                id: promptArea
                width: promptFlick.width
                placeholderText: "Prompt"
                wrapMode: TextArea.Wrap
                color: root.foreground
                placeholderTextColor: root.mutedColor
                font.family: Style.font.family
                font.pixelSize: Style.font.body
                background: Rectangle { color: "transparent" }
                onTextChanged: root.editPrompt = text
                onActiveFocusChanged: {
                  if (activeFocus) root.editRow = -1
                }
              }
            }

            Column {
              id: editOptions
              width: parent.width
              spacing: Style.spacing.xs

              Repeater {
                model: 5

                Rectangle {
                  required property int index
                  property bool hovered: false
                  width: editOptions.width
                  height: Math.max(Style.space(32), Style.font.body + Style.spacing.lg)
                  radius: root.cornerRadius
                  color: (root.editRow === index || hovered) ? root.selectedBackground : "transparent"

                  Text {
                    anchors.left: parent.left
                    anchors.leftMargin: Style.spacing.rowPaddingX
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * 0.42
                    textFormat: Text.PlainText
                    text: root.optionLabel(index)
                    color: root.editRow === index ? root.selectedText : root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                    elide: Text.ElideRight
                  }

                  Text {
                    anchors.right: parent.right
                    anchors.rightMargin: Style.spacing.rowPaddingX
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * 0.5
                    horizontalAlignment: Text.AlignRight
                    textFormat: Text.PlainText
                    text: root.optionValue(index)
                    color: root.editRow === index ? root.selectedText : root.accentColor
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                    elide: Text.ElideRight
                  }

                  MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onContainsMouseChanged: parent.hovered = containsMouse
                    onClicked: root.activateOption(index)
                  }
                }
              }
            }
          }
        }

        TextField {
          id: promptField
          width: parent.width
          visible: !root.editing
          placeholderText: "Freeform prompt"
          font.family: root.fontFamily
          Keys.priority: Keys.BeforeItem
          Keys.onEscapePressed: function(event) {
            root.cancel()
            event.accepted = true
          }
          onAccepted: root.runPromptField()
          onActiveFocusChanged: {
            if (activeFocus) root.focusSection = "prompt"
          }
        }

        Text {
          id: footer
          width: parent.width
          textFormat: Text.PlainText
          wrapMode: Text.Wrap
          text: root.footerText()
          color: root.mutedColor
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
      }
      }
    }
  }
}
