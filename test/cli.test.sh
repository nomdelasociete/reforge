#!/usr/bin/env bash
# Exercises the recast CLI without sending keystrokes or calling a model.
set -uo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
bin="$root/bin/recast"
tmp=$(mktemp -d)
export XDG_CONFIG_HOME="$tmp/config"
export XDG_STATE_HOME="$tmp/state"
export XDG_RUNTIME_DIR="$tmp/run"
mkdir -p "$XDG_RUNTIME_DIR"
fail=0

check() {
  local name="$1"
  shift
  if "$@"; then
    printf 'ok  %s\n' "$name"
  else
    printf 'FAIL %s\n' "$name" >&2
    fail=1
  fi
}

agent=$("$bin" agent)
check "agent ready" jq -e '.ok == true and .agent == "grok" and .ready == true' <<<"$agent"

presets=$("$bin" presets)
check "translate is the default" jq -e '.ok == true and .presets[0].id == "translate" and .presets[0].default == true and .presets[0].diff == false and (.presets | length) >= 2' <<<"$presets"
check "presets file mode" test "$(stat -c '%a' "$XDG_CONFIG_HOME/recast/presets.json")" = 600

export RECAST_NO_RELOAD=1
export RECAST_BINDS_FILE="$tmp/recast.lua"
export RECAST_BINDINGS_LUA="$tmp/bindings.lua"
printf '%s\n' '-- user' > "$RECAST_BINDINGS_LUA"
printf '%s\n' '{"presets":[{"id":"translate","name":"Translate FR/EN","prompt":"If French, English.","enabled":true,"diff":false,"agent":"","bind":"SUPER + ALT + T","default":true}]}' | "$bin" save >/dev/null
check "writes a prompt keybind" grep -q 'summon translate' "$RECAST_BINDS_FILE"
bad=$(printf '%s\n' '{"presets":[{"id":"translate","name":"T","prompt":"p","enabled":true,"diff":false,"agent":"","bind":"SUPER + SHIFT + R","default":true}]}' | "$bin" save)
check "rejects the general chord" jq -e '.ok == false' <<<"$bad"

expanded=$(printf '%s\n' '{"text":"bonjour","prompt":"In {app}: {selection}","app":"Firefox"}' | "$bin" expand)
check "fills app and selection" jq -e '.prompt == "In Firefox: bonjour"' <<<"$expanded"

printf '%s\n' '{"kind":"run","id":"translate","name":"Translate FR/EN","chars":6}' | "$bin" record >/dev/null
printf '%s\n' '{"kind":"cast","id":"translate","name":"Translate FR/EN","chars":0}' | "$bin" record >/dev/null
usage=$("$bin" usage)
check "records a run and a cast" jq -e '.runs == 1 and .casts == 1 and .charsChanged == 6 and .prompts[0].id == "translate"' <<<"$usage"

outside=$("$bin" take-ticket /etc/passwd)
check "rejects outside ticket" jq -e '.ok == false' <<<"$outside"

mkdir -p -m 700 "$XDG_RUNTIME_DIR/recast"
ticket=$(mktemp "$XDG_RUNTIME_DIR/recast/ticket.XXXXXX")
printf '%s\n' '{"ok":true,"text":"hello","window":"0x1","terminal":false}' >"$ticket"
taken=$("$bin" take-ticket "$ticket")
check "reads a ticket" jq -e '.ok == true and .text == "hello" and .window == "0x1"' <<<"$taken"
check "deletes a ticket" test ! -e "$ticket"

bad_window=$(printf '%s\n' '{"text":"hi","window":"nope"}' | "$bin" put)
check "rejects a bad window" jq -e '.ok == false and (.error | test("window"))' <<<"$bad_window"

rm -rf "$tmp"
exit "$fail"
