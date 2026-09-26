# [RE]Cast

Omarchy / Hyprland / Wayland plugin: **RE**cord a selection, transform it with any prompt, **Cast** the result back.

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

## Related prior art

Inspiration / adjacent tools (not required forks):

- [jankeesvw/omarchy-text-transform](https://github.com/jankeesvw/omarchy-text-transform)
- [ahasdemir/hypr-ai-grammar](https://github.com/ahasdemir/hypr-ai-grammar)

Gap this targets: a Raycast-like overlay with diff preview and an action palette.

## Status

Scaffold / product brief. Implementation TBD.

See [CONTEXT.md](./CONTEXT.md) for the locked product framing.
