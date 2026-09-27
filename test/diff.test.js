const test = require("node:test")
const assert = require("node:assert/strict")
const { diffWords, charsChanged, toRichText, WORD_CAP } = require("../DiffEngine.js")

function kinds(source, result) {
  return diffWords(source, result).parts.map(function (p) {
    return p.kind + ":" + JSON.stringify(p.text)
  })
}

test("identical text is one unchanged run", function () {
  const d = diffWords("hello world", "hello world")
  assert.equal(d.capped, false)
  assert.deepEqual(d.parts, [{ kind: "same", text: "hello world" }])
})

test("a replaced word is a deletion then an addition", function () {
  const d = diffWords("teh cat", "the cat")
  assert.deepEqual(kinds("teh cat", "the cat"), [
    'del:"teh"',
    'add:"the"',
    'same:" cat"'
  ])
  assert.equal(d.capped, false)
})

test("insertion keeps the surrounding words", function () {
  assert.deepEqual(kinds("a c", "a b c"), [
    'same:"a"',
    'add:" b"',
    'same:" c"'
  ])
})

test("deletion drops the missing word", function () {
  assert.deepEqual(kinds("a b c", "a c"), [
    'same:"a"',
    'del:" b"',
    'same:" c"'
  ])
})

test("over the token cap degrades to whole text", function () {
  const word = "w "
  const big = word.repeat(WORD_CAP + 1)
  const d = diffWords(big, big + "tail")
  assert.equal(d.capped, true)
  assert.equal(d.parts[0].kind, "note")
  assert.equal(d.parts[1].kind, "del")
  assert.equal(d.parts[2].kind, "add")
  assert.equal(d.parts[1].text, big)
})

test("changed characters count insertions and deletions", function () {
  assert.equal(charsChanged("teh cat", "the cat"), 6)
  assert.equal(charsChanged("same", "same"), 0)
})

test("rich text escapes markup and colors the runs", function () {
  const d = diffWords("a <b>", "a <c>")
  const html = toRichText(d.parts, "#aa0000", "#00aa00", "#888888")
  assert.match(html, /line-through/)
  assert.match(html, /font-weight:700/)
  assert.match(html, /&lt;b&gt;/)
  assert.match(html, /&lt;c&gt;/)
  assert.doesNotMatch(html, /<b>/)
})
