# [RE]Forge

Omarchy / Hyprland / Wayland plugin: **RE**cord a selection, **Forge** it with any prompt, and paste the result back.

## What it does

Generic flow:

1. Capture the current selection
2. Run it through any prompt (freeform or a saved preset)
3. Show an overlay preview with word-level diff highlighting
4. Choose an action

**Enter** pastes / replaces the selection with the result.

Other actions: re-transform, copy, handoff to the Omarchy default agent, cancel.

**Presets** are saved prompts (grammar, translate, tone, explain, …) — not hardcoded product modes.

## Platform

Omarchy on Hyprland (Wayland).

## Spec

Full product / engineering cahier des charges (FR lead, sourced competitive research, UX, architecture, MVP vs later, acceptance criteria, open questions for JB):

→ **[SPEC.md](./SPEC.md)**

Locked product framing: [CONTEXT.md](./CONTEXT.md).

## Related prior art

Inspiration / adjacent tools (not required forks):

- [jankeesvw/omarchy-text-transform](https://github.com/jankeesvw/omarchy-text-transform)
- [ahasdemir/hypr-ai-grammar](https://github.com/ahasdemir/hypr-ai-grammar)
- Raycast [AI Commands](https://manual.raycast.com/ai/ai-commands) / Quick Fix
- Tinycast Quick Actions ([docs](https://raw.githubusercontent.com/abue-ammar/tinycast/main/docs/features/quick-actions.md); [PR #314](https://github.com/abue-ammar/tinycast/pull/314) diff UI — closed)
- [jankeesvw/omarchy-meeting-recorder](https://github.com/jankeesvw/omarchy-meeting-recorder) (Omarchy UX / bar-widget language)

Gap this targets: a Raycast-like overlay with diff preview and an action palette, on Omarchy’s default agent.

## Install

Omarchy Quattro 4.x, a default agent (`omarchy default agent`), `jq`, `wl-clipboard`, and `hyprctl`. This plugin does not store an API key. The transform runs the default agent with tools off, in an empty directory.

```bash
omarchy plugin add https://github.com/nomdelasociete/recast.git --enable
```

While the git remote has no release yet, a local checkout works the same way:

```bash
ln -sfn ~/Github/NomDeLaSociete/recast ~/.config/omarchy/plugins/nomdelasociete.reforge
# Validate the checkout. A plugin directory that is itself a symlink is rejected.
omarchy plugin validate ~/Github/NomDeLaSociete/recast
omarchy-shell shell rescanPlugins
omarchy plugin enable nomdelasociete.reforge
```

`keepLoaded` overlays pick up QML changes on a shell restart (`omarchy restart shell`).

One binding, in `~/.config/hypr/bindings.lua`:

```lua
o.bind(
  "SUPER + SHIFT + R",
  "[RE]Forge",
  os.getenv("HOME") .. "/.config/omarchy/plugins/nomdelasociete.reforge/bin/reforge summon"
)
```

Super+Shift+E and Super+Shift+P are already Email and Photos on Omarchy, so picker and freeform prompt live inside the overlay. The binding runs `bin/reforge summon`, which captures the selection before the overlay takes focus.

| Key | Action |
|-----|--------|
| Enter | Run the highlighted preset, run the prompt field, or cast a ready result |
| Ctrl+Enter | Cast, from any focus |
| Ctrl+R | Run the same prompt again |
| Ctrl+D | Toggle word diff / plain text |
| Ctrl+C | Copy the result, leave the overlay open |
| Ctrl+A | Continue in the Omarchy default agent |
| Tab | Presets, prompt, result |
| Esc | Cancel. Nothing is pasted |

**Super+Shift+R** and **Trigger → [RE]Forge** open the trigger page. It lists every command, the app you were in, and the selection. Enter runs the highlighted command. A command's own shortcut runs that command directly. **Esc** goes back one step: out of a shortcut, out of the editor, off the free prompt, off a result, off Usage, and then it closes. A filter clears before the page closes.

On the trigger page: **Ctrl+E** edits the highlighted command, **Ctrl+N** adds one, **Ctrl+K** sets its shortcut. Click the shortcut on a row to set it too. **Ctrl+S** saves an edit. **Ctrl+X** deletes it.

A prompt can contain `{app}` (the app that was in front) and `{selection}` (the selected text). If `{selection}` is not in the prompt, the selection is still sent with it.

Other prompts can have their own chord. Those chords are written to `~/.config/hypr/reforge.lua`, which `bindings.lua` loads. Each prompt has on/off, whether the result opens on the diff, which agent runs it (empty means the Omarchy default), and whether it is the default. **Ctrl+D** still toggles the diff for the result you are looking at.

The shipped default prompt translates French into English and anything else into French, with the diff off, because a full translation lights up every word. Spelling and the other edits keep the diff on. Turn any of that off per prompt.

Presets live in `~/.config/reforge/presets.json` (directory `700`, file `600`). The overlay is the editor. The file is created on first use. Move `~/.config/recast` to `~/.config/reforge` if presets were saved under the old name.

Terminals are best effort: copy and paste use Ctrl+Insert and Shift+Insert there, and many terminals still will not treat that as copy/paste of a selection. GUI apps are the ones Enter is meant for. After a cast, the result stays on the clipboard. If the window has gone, the overlay says so.

Grok takes the prompt as an argument, so the selection is briefly visible in the process list. The other supported agents take it on stdin. Crush is refused, because it cannot be started with tools off.

## Status

MVP overlay: capture, tools-off transform, word diff, cast, copy, re-transform, handoff, file-based presets.
