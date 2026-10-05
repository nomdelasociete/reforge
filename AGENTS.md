# [RE]Forge — agent rules

These override improvisation. Break one and the change is not done.

## Prove the path

Do not say a behavior works until that path was run.

- Overlay: open it, put focus in the control the user named, press the key, check the result. Tab into the free prompt and then Esc is a different test from Esc on the list.
- A green unit test of a helper is not a test of the card.
- If you did not look at the card, do not describe how it looks.
- If the check fails, say it failed. Do not narrate a fix you did not re-run.

## UI

Match the overlays people already use: clipboard, emojis, menu. Open those files before copying a pattern.

- Title, rows, footer line. `Color` and `Style` tokens only. No hex.
- No decorative mark, no rectangle “logo”, no glyph you have not seen rendered on this card.
- Do not claim another plugin’s design unless you opened that plugin and the change matches it.
- A chart, if asked for, is bars or a pie drawn with those same tokens. No second palette.

## Selection

Wayland primary selection is leftover text. It stays after the highlight is gone.

Capture only a copy made when the app opens. If that copy is empty, the header says no selection. Never show the previous launch’s text.

## Keys

Esc goes back one level: shortcut capture, editor, free prompt, result, Usage, filter. At the root it closes.

One press, one step. Test Esc from the focused control, not from a sibling that happens to have a key handler.

## Git

Finished work is a commit on the branch. Do not leave a completed change as untracked files.

Push to `origin` when the user asked for the work to be on the remote.

Do not rewrite `~/.config`, restart the shell, or seed `~/.local/state/reforge` as a drive-by. If a check needs that, restore it before you stop, and say what you touched.
