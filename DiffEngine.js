// Word-level diff for the overlay. Pure JavaScript so node can test it
// and QML can import it. Tokens are whitespace or non-whitespace runs,
// so the rendered text can be joined back into the original.

var WORD_CAP = 4000

function tokenize(text) {
  var s = String(text || "")
  if (!s) return []
  var parts = s.match(/\s+|\S+/g)
  return parts || []
}

function escapeHtml(s) {
  return String(s)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
}

function mergeParts(ops) {
  var parts = []
  for (var i = 0; i < ops.length; i++) {
    var op = ops[i]
    var last = parts.length ? parts[parts.length - 1] : null
    if (last && last.kind === op.kind) last.text += op.text
    else parts.push({ kind: op.kind, text: op.text })
  }
  return parts
}

function diffWords(source, result) {
  var a = tokenize(source)
  var b = tokenize(result)
  if (a.length > WORD_CAP || b.length > WORD_CAP) {
    return {
      capped: true,
      parts: [
        { kind: "note", text: "Change is large, so this shows the whole text instead of word by word.\n" },
        { kind: "del", text: String(source || "") },
        { kind: "add", text: String(result || "") }
      ]
    }
  }

  var n = a.length
  var m = b.length
  var width = m + 1
  var dp = new Array((n + 1) * width)
  function at(i, j) { return dp[i * width + j] }
  function set(i, j, v) { dp[i * width + j] = v }

  var i
  var j
  for (i = 0; i <= n; i++) set(i, 0, 0)
  for (j = 0; j <= m; j++) set(0, j, 0)
  for (i = 1; i <= n; i++) {
    for (j = 1; j <= m; j++) {
      if (a[i - 1] === b[j - 1]) set(i, j, at(i - 1, j - 1) + 1)
      else set(i, j, Math.max(at(i - 1, j), at(i, j - 1)))
    }
  }

  // Walk backwards. On a tie, consume the result token first so the
  // reversed script shows the deletion and then the addition.
  var ops = []
  i = n
  j = m
  while (i > 0 && j > 0) {
    if (a[i - 1] === b[j - 1]) {
      ops.push({ kind: "same", text: a[i - 1] })
      i--
      j--
    } else if (at(i, j - 1) >= at(i - 1, j)) {
      ops.push({ kind: "add", text: b[j - 1] })
      j--
    } else {
      ops.push({ kind: "del", text: a[i - 1] })
      i--
    }
  }
  while (i > 0) {
    ops.push({ kind: "del", text: a[i - 1] })
    i--
  }
  while (j > 0) {
    ops.push({ kind: "add", text: b[j - 1] })
    j--
  }
  ops.reverse()
  return { capped: false, parts: mergeParts(ops) }
}

function charsChanged(source, result) {
  var diff = diffWords(source, result)
  if (diff.capped) return Math.abs(String(result || "").length - String(source || "").length)
  var count = 0
  var parts = diff.parts || []
  for (var i = 0; i < parts.length; i++) {
    if (parts[i].kind === "del" || parts[i].kind === "add") count += String(parts[i].text || "").length
  }
  return count
}

function toRichText(parts, delColor, addColor, noteColor) {
  var html = ""
  for (var i = 0; i < (parts || []).length; i++) {
    var p = parts[i]
    var t = escapeHtml(p.text).replace(/\n/g, "<br/>")
    if (p.kind === "del") {
      html += '<span style="color:' + delColor + ';text-decoration:line-through;">' + t + "</span>"
    } else if (p.kind === "add") {
      html += '<span style="color:' + addColor + ';font-weight:700;">' + t + "</span>"
    } else if (p.kind === "note") {
      html += '<span style="color:' + (noteColor || delColor) + ';">' + t + "</span>"
    } else {
      html += t
    }
  }
  return html
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    WORD_CAP: WORD_CAP,
    tokenize: tokenize,
    diffWords: diffWords,
    charsChanged: charsChanged,
    toRichText: toRichText,
    escapeHtml: escapeHtml
  }
}
