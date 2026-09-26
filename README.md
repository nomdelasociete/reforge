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

## Status

Scaffold / product brief. Implementation TBD after SPEC sign-off.
