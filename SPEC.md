# [RE]Cast — Cahier des charges produit / engineering

> **Statut :** brief verrouillé (JB) + recherche concurrentielle — *pas encore d’implémentation*.  
> **Repo :** https://github.com/nomdelasociete/recast  
> **Date :** 2026-09-26 (CEST)  
> **Langue :** FR (lead) ; termes techniques Omarchy / UX en EN quand c’est l’idiome du projet.

---

## 1. Vision

**[RE]Cast** est un plugin Omarchy (Hyprland / Wayland) qui :

1. **RE**cord — capture la sélection (ou le clipboard en fallback) dans n’importe quelle app.
2. **Cast** — envoie le texte à un prompt (libre ou preset nommé), affiche le résultat dans un **overlay** devant l’utilisateur avec **diff word-level**, puis **cast** le texte transformé (remplacer / coller / copier / handoff agent).

### Promesse produit

> *Sélection → raccourci → transformation (any prompt) → preview + diff → action.*

Ce n’est **pas** un chat. Ce n’est **pas** un correcteur figé. C’est un **lanceur de transforms** génériques, où les « modes » (orthographe, ton, traduction…) ne sont que des **presets = prompts nommés**.

### Brand

| Partie | Sens |
|--------|------|
| **RE** | Record — capturer la sélection |
| **Cast** | Cast — renvoyer le texte transformé |

Aligné avec le framing déjà dans [`CONTEXT.md`](./CONTEXT.md) et [`README.md`](./README.md).

---

## 2. Non-goals

Explicitement **hors scope** tant que JB n’élargit pas le brief :

- Chat conversationnel multi-tours avec historique (style Raycast AI Chat / Tinycast AI Chat).
- Fournisseur LLM dédié avec gestion de clés API dans le plugin (Gemini/OpenAI BYOK) — on s’appuie sur **`omarchy default agent`** (comme text-transform / meeting-recorder chapters).
- Remplacement silencieux *sans* overlay (mode « Quick Fix direct ») en MVP — le preview+diff est le différenciateur.
- Support X11 / macOS / Windows.
- Extension Raycast, Tinycast fork, ou packaging hors plugin Omarchy Quattro.
- Agent avec tools activés pendant le transform (sécurité : tools off, cf. prior art jankeesvw).
- Édition collaborative, sync cloud des presets, marketplace de prompts.

---

## 3. Notes concurrentielles (avec sources)

### 3.1 Raycast — AI Commands / Quick Fix / Fix Spelling

**Sources :**

- [AI Commands | Raycast Manual](https://manual.raycast.com/ai/ai-commands)
- [Raycast v0.61 — Quick Fix](https://www.raycast.com/changelog/macos-beta/0-61) (2026-05-20)
- Extension [Language Tool — Check Selected Text](https://www.raycast.com/lucastaonline/raycast-language-tool) (review-then-replace)
- Extension [llm-quick-actions](https://github.com/ivnvxd/llm-quick-actions) (Transform / Transform Preview)

**Flow documenté :**

1. Sélectionner du texte (ou champ focus).
2. Lancer une AI Command (Root Search) **ou** Quick Fix (hotkey dédié).
3. Quick Fix = Fix Spelling and Grammar **in-place** (remplace directement) ; permissions Accessibility macOS.
4. AI Commands custom : prompt + `{selection}` / arguments ; **Output Behavior** = *Open in Raycast* **ou** *Replace Selection* ; option **Highlight Editing Changes**.
5. Depuis la fenêtre de résultat : copy, paste, continuer la conversation avec Raycast AI.

**Built-ins utiles comme catalogue d’exemples de presets :** Improve Writing, Fix Spelling and Grammar, Explain in Simple Terms, Change Tone (Professional / Friendly), Find Bugs, Summarize Webpage, Ask About Webpage.

**À emporter pour [RE]Cast :**

| Raycast | [RE]Cast |
|---------|----------|
| AI Commands = prompts nommés | Presets = prompts nommés |
| Quick Fix = hotkey → replace direct | MVP : hotkey → **toujours** overlay+diff (pas de silent replace) |
| Highlight Editing Changes | Diff word-level dans l’overlay (exigence JB) |
| Continue in AI Chat | Action « Continuer dans l’agent Omarchy default » |
| Replace Selection | Enter = replace/paste sélection |

### 3.2 Tinycast — Quick Actions / text injection / diff (PR)

**Sources :**

- [README Tinycast](https://github.com/abue-ammar/tinycast/blob/main/README.md)
- [docs/features/quick-actions.md](https://raw.githubusercontent.com/abue-ammar/tinycast/main/docs/features/quick-actions.md)
- [DeepWiki — Quick Actions & Text Injection](https://deepwiki.com/abue-ammar/tinycast/7.7-quick-actions-and-text-injection)
- [PR #314 — Add in-place AI text transforms](https://github.com/abue-ammar/tinycast/pull/314) (**closed / non mergé** — design précieux, pas code à forker)

**Quick Actions shippés (docs actuelles) :**

| Action | Engine | Résultat par défaut | Diff |
|--------|--------|---------------------|------|
| Fix Grammar | AI provider | replace direct | oui |
| Rewrite | AI provider | floating panel | oui |
| Translate | Apple Translation | panel | non |
| Summarize | AI provider | panel (toujours) | non |
| Custom | AI provider | panel (switchable) | non |

**Injection (macOS) :** Accessibility (`kAXSelectedTextAttribute`) → typing chunks → pasteboard lease (⌘V + restore). Sélection : AX d’abord, sinon ⌘C synthétique avec garde `changeCount`.

**PR #314 (non mergée) — patterns UX à citer, pas à copier :**

- Dual mode : Direct in-place **ou** Interactive palette.
- Toggle `[Diff | Text]` (`⌘D`) ; deletions = rouge + strikethrough ; additions = vert + bold ; LCS word-level (`AIDiffEngine`).
- Actions palette : Insert `↵`, Copy `⌘C`, Regenerate `⌘R`, refinement multi-tour.
- Philosophie auteur : *pas* un chat client — strictement in-place transform.

**À emporter :**

- Diff word-level + toggle texte brut = cœur de l’overlay [RE]Cast.
- « One run at a time », sélection capturée *avant* de cacher le launcher/overlay.
- Custom action = name + prompt (+ glyph) — même modèle de données que nos presets.
- Sur Wayland : pas d’AX macOS → s’appuyer sur clipboard / primary selection + `wtype` / Ctrl+C–Ctrl+V (cf. plugins Omarchy existants) ; marquer les détails API **à vérifier**.

### 3.3 Omarchy Quattro — plugins, shell, theming, bindings

**Sources (officielles) :**

- [Shell Plugins — Omarchy Manual](https://omarchy.org/manual/shell-plugins/)
- [Develop a Plugin](https://plugins.omarchy.org/develop.html)
- [Dotfiles — bindings.lua](https://omarchy.org/manual/dotfiles/)
- [AI — default agent](https://omarchy.org/manual/ai/)
- Source : [`shell/README.md` (branche quattro)](https://github.com/basecamp/omarchy/blob/quattro/shell/README.md), [`docs/theming.md`](https://github.com/basecamp/omarchy/blob/quattro/docs/theming.md), [`docs/omarchy-shell.md`](https://github.com/basecamp/omarchy/blob/quattro/docs/omarchy-shell.md)

**Faits verrouillés (ne pas inventer au-delà) :**

- Shell = un processus Quickshell long-lived `omarchy-shell` ; plugins = QML + `manifest.json` (`schemaVersion: 1`).
- Kinds documentés : `bar-widget`, `panel`, `overlay`, `menu`, `service`, `bar`.
- Plugins 3p dans `~/.config/omarchy/plugins/<id>/` ; enable ⇔ id présent dans `~/.config/omarchy/shell.json`.
- Install : `omarchy plugin add <git-url> [--enable]` ; validate : `omarchy plugin validate` ; bar : `omarchy bar move <id> --section …`.
- Theming : `Color` / `Style` QML depuis `colors.toml` + `shell.toml` ; préférer `BorderSurface` / tokens shell.
- Keybindings user : `~/.config/hypr/bindings.lua` via `o.bind(...)` (Quattro ; ne plus compter sur `bindings.conf` seul).
- Default agent : `omarchy default agent <name>` ; launch task : `omarchy agent prompt "…"` ; hotkey agent : `Super + Shift + Ctrl + A` (manuel AI).
- IPC documenté : `omarchy-shell shell summon|hide|toggle <id>`, `rescanPlugins`, etc. — signatures exactes des payloads **à vérifier** dans `$OMARCHY_PATH/shell/README.md` au moment d’implémenter.

### 3.4 jankeesvw/omarchy-meeting-recorder — UX « génial » (référence visuelle)

**Sources :**

- [README](https://github.com/jankeesvw/omarchy-meeting-recorder) (v1.4+)
- Plugin : [`plugin/manifest.json`](https://github.com/jankeesvw/omarchy-meeting-recorder/blob/main/plugin/manifest.json), [`plugin/Widget.qml`](https://github.com/jankeesvw/omarchy-meeting-recorder/blob/main/plugin/Widget.qml)

**Patterns UX / UI à réutiliser comme *langage* (pas comme feature set) :**

| Pattern | Détail observé |
|---------|----------------|
| **Bar widget live** | Caché au repos ; visible seulement pendant un état utile (recording / paused / transcribing) ; dot pulsant + waveform + clock ; click → ramène la fenêtre |
| **Compact / full** | Ctrl+M : fenêtre → strip minimal (clock + waves) ; hors du chemin |
| **Thème Omarchy** | Lit `colors.toml` ; speakers / waves / animation suivent le thème actif (Tokyo Night, Catppuccin, etc.) |
| **États explicites** | Ready → Recording → Paused → Transcribing (animation + %) → Done ; jamais un spinner anonyme |
| **Keyboard-first** | Raccourcis documentés ; Enter = action primaire sur done (copy transcript) |
| **Agent default sans tools** | Chapters via `omarchy-default-agent` headless, tools off, cwd vide, borné temps/taille ; agents sans switch tools refusés |
| **CLI pour bindings** | `start` / `pause` / `stop` / `compact` / `watch` (NDJSON) → le widget et Hyprland parlent la même surface |
| **Manifest bar-widget** | `jankeesvw.meeting-recorder`, `defaultSection: "right"`, entry `Widget.qml` |

**Leçon pour [RE]Cast :** même sobriété visuelle (tokens `Color`/`Style`), feedback d’état pendant le run agent (bar ou overlay), surface CLI/`omarchy-shell` pour les keybindings, agent default tools-off.

### 3.5 Prior art Omarchy text — réutiliser vs gap

#### [jankeesvw/omarchy-text-transform](https://github.com/jankeesvw/omarchy-text-transform)

**Réutiliser (idées / patterns, pas fork obligatoire) :**

- Backend = **`omarchy default agent`** (pas de clé API dans le plugin).
- Presets = name + prompt (+ auto-copy) éditables ; ship minimal (fix typos, shorter, translate).
- Agents supportés avec tools off explicite (Claude `--tools ""`, Pi `--no-tools`, etc.) ; Crush / Antigravity **refusés**.
- Sélection in-place : `grab` / `put` via hyprctl + Ctrl+C / Ctrl+V ; fenêtre mémorisée par adresse.
- Bindings documentés : `omarchy-shell shell toggle jankeesvw.text-transform`, `… paste`, `… transform`, `… replace`.
- Panel keyboard-first ; close pendant run OK ; flèches bar restent lit pendant le travail ; stop tue l’agent.

**Gap vs [RE]Cast (ce que JB veut en plus) :**

- Pas d’**overlay** type Raycast/Tinycast devant le texte avec **diff word-level**.
- Panel = input/output boxes ; pas de « cast » immédiat sur sélection avec preview des changements.
- Pas d’action « continue in default agent » (conversation / handoff) depuis le résultat.
- UX orientée clipboard/panel plutôt que sélection → preview → Enter replace.

#### [ahasdemir/hypr-ai-grammar](https://github.com/ahasdemir/hypr-ai-grammar)

**Réutiliser :**

- Lecture sélection Wayland : primary selection puis clipboard (`wl-clipboard`).
- Remplacement in-place via paste (`wtype` / stack clipboard).
- Bar panel avec Quick Actions + custom prompt.
- Bindings.lua exemples (`ALT + SPACE`, `non_consuming = true`).

**Gap / écarts :**

- Lié à **Gemini API key** (BYOK) — hors modèle Omarchy-agent de [RE]Cast.
- Remplacement **direct** sans overlay/diff (corrige et colle).
- Modes plutôt figés (Fix / Enhance / Formal…) même s’il y a custom prompt — pas le framing « presets only ».

#### Positionnement [RE]Cast

```
text-transform ── agent Omarchy + presets ────────────┐
hypr-ai-grammar ── sélection Wayland + in-place ──────┤
Raycast / Tinycast PR ── overlay + diff + actions ────┼──► [RE]Cast
meeting-recorder ── polish UI Omarchy + bar state ────┘
```

---

## 4. UX flows + proposition de keybindings (Omarchy-compliant)

### 4.1 Flow principal (MVP)

```
[App focus]  sélection texte
     │
     ▼
[Hotkey]  RE]Cast summon (preset last-used OU picker)
     │
     ├─ Capture sélection (primary → clipboard → fallback Ctrl+C)  « RE »
     ├─ Mémoriser fenêtre/cible Wayland (adresse hyprctl — à vérifier)
     ▼
[Overlay]  devant tout
     │  • Titre preset / prompt court
     │  • Zone résultat (streaming si possible)
     │  • Diff word-level (toggle Diff | Texte)
     │  • Footer actions + hints clavier
     ▼
[Actions]
     Enter     → Cast : replace/paste dans la cible  « Cast »
     Ctrl+R    → Re-transform (même prompt)
     Ctrl+C    → Copy résultat (sans fermer, ou fermer — à trancher)
     Ctrl+A    → Continue in Omarchy default agent (handoff)
     Esc       → Cancel (rien n’est collé)
```

### 4.2 Flow « freeform prompt »

1. Hotkey « prompt libre » **ou** overlay ouvert → focus champ prompt.
2. Taper instructions (« rewrite as a curt Slack reply ») + Enter.
3. Même overlay résultat / diff / actions.

### 4.3 Flow « preset picker »

1. Hotkey « picker » → liste fuzzy des presets (comme Root Search Raycast / palette Tinycast).
2. Enter sur un preset → run immédiat sur la sélection déjà capturée.
3. Option : `o.bind` par preset hotkey (ex. Fix Spelling dédié) pour le path 1-key.

### 4.4 Proposition de keybindings (`~/.config/hypr/bindings.lua`)

> Conventions inspirées de text-transform / hypr-ai-grammar / manuel Omarchy. **À valider avec JB** (conflits Super+…).

```lua
-- Summon overlay : capture sélection + last preset (ou picker si aucun)
o.bind(
  "SUPER + SHIFT + R",
  "[RE]Cast",
  "omarchy-shell shell summon nomdelasociete.recast '{}'",  -- payload exact à vérifier
  { non_consuming = true }
)

-- Picker de presets
o.bind(
  "SUPER + SHIFT + P",
  "[RE]Cast presets",
  "omarchy-shell shell summon nomdelasociete.recast '{\"mode\":\"picker\"}'",
  { non_consuming = true }
)

-- Prompt libre
o.bind(
  "SUPER + SHIFT + E",
  "[RE]Cast prompt",
  "omarchy-shell shell summon nomdelasociete.recast '{\"mode\":\"prompt\"}'",
  { non_consuming = true }
)
```

**Dans l’overlay (une fois focus) :**

| Raccourci | Action |
|-----------|--------|
| `Enter` | Cast — replace / paste sélection |
| `Ctrl+Enter` | Cast + fermer (si Enter seul = commit champ prompt) — *à clarifier* |
| `Ctrl+R` | Re-transform |
| `Ctrl+C` | Copier le résultat |
| `Ctrl+D` | Toggle Diff / Texte (héritage Tinycast PR ⌘D) |
| `Ctrl+A` | Continuer dans l’agent Omarchy default |
| `Tab` | Cycle focus (prompt / résultat / actions) |
| `Esc` | Cancel |

**Bar (optionnel MVP+) :** widget discret — idle = glyph `[RE]` ; running = spinner / pulse (langage meeting-recorder) ; click = reouvrir overlay du dernier run.

### 4.5 Règles UX dures

1. **Capturer la sélection avant** d’afficher l’overlay (sinon l’overlay vole le focus / la sélection) — leçon Tinycast `targetApp` avant hide palette.
2. **Un run à la fois** ; re-transform annule / remplace le précédent.
3. **Enter ne cast jamais** tant que le modèle n’a pas produit de résultat (disabled / no-op).
4. **Cancel** restaure le clipboard utilisateur si on l’a emprunté (lease) — pattern Tinycast / text-transform.
5. **Pas de silent success** : échec agent / pas de sélection / agent sans tools → message clair dans l’overlay (ou notification), pas de no-op.

---

## 5. Principes UI (Omarchy + leçons meeting-recorder)

1. **Tokens only** — couleurs / radius / typo via `Color` et `Style` (pas de hex en dur). Suivre le thème live.
2. **Overlay, pas fenêtre app** — kind Quattro `overlay` (fullscreen scrim) **ou** `panel` flottant centré ; choix final **à vérifier** vs focus Wayland et « always on top ». Préférence produit JB : *overlay in front*.
3. **Hiérarchie visuelle sobre**
   - Header : nom preset + modèle/agent (discret)
   - Corps : résultat + diff
   - Footer : actions primaires à droite, secondaires à gauche (langage Raycast / Tinycast panel)
4. **Diff lisible**
   - Suppressions : strikethrough + couleur `urgent` / rouge thème
   - Ajouts : bold + accent / vert thème
   - Toggle Diff | Texte pour les gros changements
5. **États** : Idle capture → Running (progress indéterminé ou stream) → Ready → Error — aussi explicites que Ready/Recording/Transcribing du meeting-recorder.
6. **Keyboard-first** ; souris optionnelle ; Escape = sortie universelle (`PanelKeyCatcher` / équivalent overlay).
7. **Bar widget** (si présent) : *hidden when idle* ou glyph minimal — comme meeting-recorder qui ne s’affiche que pendant un état utile.
8. **Pas de chrome inutil** : pas de sidebar settings dans l’overlay MVP ; settings = fichier config + éventuellement panel bar gear (comme text-transform).

---

## 6. Features — MVP vs later

### 6.1 MVP (doit shipper)

| # | Feature | Exemple concret |
|---|---------|-----------------|
| M1 | Capture sélection Wayland (primary → clipboard → Ctrl+C fallback) | Sélection dans Slack / Browser / Neovim (best-effort) |
| M2 | Run via `omarchy default agent` tools-off | Même contrat que text-transform / meeting-recorder `ask` |
| M3 | Overlay résultat + **diff word-level** | Orthographe : `teh` ~~teh~~ **the** |
| M4 | Actions : Enter cast, re-transform, copy, cancel | Enter remplace la sélection dans la fenêtre mémorisée |
| M5 | Action handoff « Continue in default agent » | Ouvre l’agent avec contexte sélection + résultat + prompt |
| M6 | Presets = JSON name+prompt (+ hotkey optionnel later) | Ship : Fix spelling, Translate FR↔EN, Shorter, Professional tone, Explain simply |
| M7 | Prompt libre dans l’overlay | « Make this a polite decline » |
| M8 | Install plugin Quattro (`manifest.json` + entry overlay/panel) | `omarchy plugin add https://github.com/nomdelasociete/recast.git --enable` |
| M9 | Bindings.lua documentés dans le README | Super+Shift+R |
| M10 | Gestion erreurs agent / pas de sélection / timeout | Message dans overlay + Esc |

**Exemples de presets shippés (prompts indicatifs — à peaufiner) :**

- **Fix spelling & grammar** — corrige sans changer le ton ; sortie = texte seul.
- **Translate to English** / **Traduire en français**.
- **Make shorter** — condensed, même sens.
- **Professional tone** / **Friendly tone**.
- **Explain simply** — paraphrase claire.
- **Rewrite** — improve clarity, keep meaning.

### 6.2 Later (post-MVP)

| Feature | Note |
|---------|------|
| Hotkey par preset | Comme Raycast Quick Fix / Tinycast per-action shortcuts |
| Streaming token-by-token dans l’overlay | Si l’agent CLI le permet — **à vérifier** par agent |
| Bar widget état running | Dot / pulse meeting-recorder-style |
| Historique local des N derniers transforms | Privacy : opt-in |
| Import / export presets | JSON ; pas cloud |
| Diff char-level pour typos 1 caractère | Affinage |
| Mode « direct cast » (skip overlay) pour un preset | Opt-in dangereux ; hors MVP volontairement |
| Multi-sélection / batch | Non prioritaire |
| Preserved formatting rich text | Raycast expérimental ; Wayland très fragmenté — plus tard |

---

## 7. Architecture technique

> Toute API non citée dans les docs officielles ou READMEs ci-dessus est marquée **à vérifier**.

### 7.1 Vue d’ensemble

```
┌─────────────────────────────────────────────────────────┐
│  Omarchy shell (Quickshell)                             │
│  ┌─────────────────┐   ┌──────────────────────────────┐ │
│  │ bar-widget?     │   │ overlay / panel  [RE]Cast UI │ │
│  │ (état running)  │   │  - DiffEngine (QML/JS/Rust?) │ │
│  └────────┬────────┘   │  - Actions / key catcher     │ │
│           │            └───────────────┬──────────────┘ │
│           └──────── IPC / Process ─────┘                │
└────────────────────────────┬────────────────────────────┘
                             │
         ┌───────────────────┼───────────────────┐
         ▼                   ▼                   ▼
  wl-clipboard /        omarchy default      hyprctl
  wtype / ydotool?      agent (tools off)    (fenêtre cible)
  primary selection     stdin prompt         address remember
         │                   │                   │
         └──────────── Cast: paste/replace ──────┘
```

### 7.2 Capture sélection (Wayland)

**Stratégie proposée (alignée hypr-ai-grammar + text-transform) :**

1. Lire `wl-paste --primary` (sélection primaire).
2. Sinon `wl-paste` (clipboard).
3. Sinon synthétiser Ctrl+C vers la fenêtre active (`wtype` / `ydotool` / hyprland dispatch — **à vérifier** ce qu’Omarchy ship et ce que text-transform `grab` utilise exactement).
4. Ne jamais confondre « clipboard inchangé » avec « copie réussie » (leçon Tinycast `changeCount`) — sur Wayland, heuristique équivalente **à vérifier** (timestamp clipboard / contenu avant-après).

### 7.3 Agent

- Utiliser le **default agent** Omarchy (`omarchy default agent` / `omarchy-default-agent` selon binaire — **à vérifier** le wrapper exact côté text-transform `bin/text-transform`).
- **Tools off** obligatoire ; refuser les agents qui ne le permettent pas (liste text-transform comme référence).
- Prompt : envelopper la sélection entre marqueurs « untrusted material » ; exiger **texte transformé seul** (pas de preamble / fences) — même invariant que Tinycast `QuickActionPrompt` / text-transform.
- Cwd jetable vide ; bornes temps + taille stdout.
- Handoff « Continue in agent » : **à vérifier** — candidats documentés :
  - `omarchy agent prompt "…"` (manuel AI) — lance en mode unattended ;
  - ouvrir un terminal agent avec contexte pré-rempli ;
  - surface IPC agents panel — **à vérifier** dans `$OMARCHY_PATH/shell/plugins/agents/`.

### 7.4 Overlay / shell packaging

**Option A (préférée produit) :** `kinds: ["overlay"]` + `entryPoints.overlay` — fullscreen scrim, contenu centré.  
**Option B :** `kinds: ["panel"]` ou bar-widget qui charge un `Panel.qml` (pattern clock / text-transform).  
**Option C :** `bar-widget` + `overlay` multi-kind (autorisé par le manuel : un plugin peut déclarer plusieurs kinds).

Décision d’implémentation : prototypage A vs B sur focus/keyboard grab Wayland — **à vérifier** avec un spike.

### 7.5 Diff engine

- Algorithme : LCS word-level (comme Tinycast PR `AIDiffEngine` / docs `TextDiffEngine`).
- Implémentation possible : JS/QML pur pour MVP ; ou petit binaire Rust si perf — **choix ouvert**.
- Cap de tokens pour éviter O(n²) mémoire (Tinycast documente un plafond + dégradation whole-text).

### 7.6 Cast (écriture)

1. Remettre le résultat dans le clipboard (`wl-copy`).
2. Focus fenêtre cible mémorisée (`hyprctl dispatch focuswindow address:…` — **à vérifier**).
3. Synthétiser Ctrl+V (`wtype` / équivalent).
4. Option : restaurer l’ancien clipboard après délai (lease) — **à vérifier** fiabilité vs apps lentes.

Limites connues (text-transform README) : terminals ne traitent souvent pas Ctrl+C/V comme copy/paste ; documenter les apps supportées / non supportées.

### 7.7 Config

- Presets : `~/.config/recast/presets.json` (mode 600) — hors repo plugin (comme text-transform `transformations.json`).
- Pas de secrets dans le plugin (pas de clé API).

---

## 8. Packaging / install

### 8.1 Layout repo cible

```
recast/
├── README.md
├── CONTEXT.md
├── SPEC.md                 ← ce document
├── LICENSE
├── manifest.json           # Omarchy plugin root (requis pour `omarchy plugin add`)
├── Overlay.qml             # ou Panel.qml / BarWidget.qml — selon kind choisi
├── …                       # DiffEngine, services, assets
└── preview.png             # optionnel, directory plugins
```

> Aujourd’hui le repo n’a que README + CONTEXT ; le code plugin arrive après validation SPEC.

### 8.2 `manifest.json` (ébauche — ids à figer avec JB)

```json
{
  "schemaVersion": 1,
  "id": "nomdelasociete.recast",
  "name": "[RE]Cast",
  "version": "0.1.0",
  "author": "Jean-Baptiste Ronssin / nomdelasociete",
  "license": "MIT",
  "description": "Record a selection, transform with any prompt, cast it back with a diff overlay.",
  "kinds": ["overlay"],
  "entryPoints": { "overlay": "Overlay.qml" }
}
```

Si bar widget ajouté : `"kinds": ["overlay", "bar-widget"]` + bloc `barWidget` (`defaultSection`: `"right"`, `allowMultiple`: false).

### 8.3 Install utilisateur

```bash
omarchy plugin add https://github.com/nomdelasociete/recast.git --enable
# si bar-widget :
omarchy bar move nomdelasociete.recast --section right

# keybindings : documentés dans README → éditer ~/.config/hypr/bindings.lua
```

Prérequis documentés : Omarchy Quattro 4.x, default agent configuré, `wl-clipboard`, outil de frappe synthétique **à préciser**, `jq` si scripts shell.

Validation : `omarchy plugin validate .` + `qmllint` comme dans [Develop a Plugin](https://plugins.omarchy.org/develop.html).

### 8.4 Distribution

- Git public + `omarchy plugin add` (mécanisme officiel).
- Listing ultérieur sur [omarchyplugins.com](https://omarchyplugins.com) / Omahub — after MVP.

---

## 9. Critères d’acceptance (MVP)

1. **Install** : `omarchy plugin add` + enable sans erreur ; `omarchy plugin list` montre `nomdelasociete.recast` enabled.
2. **Capture** : avec du texte sélectionné dans au moins 3 apps graphiques courantes (ex. browser, Slack/Discord, éditeur GUI), le hotkey ouvre l’overlay avec ce texte comme source.
3. **Transform** : un preset « Fix spelling » produit un résultat non vide via le default agent ; overlay affiche le texte.
4. **Diff** : pour une typo volontaire (`teh` → `the`), le mode Diff montre suppression + addition word-level.
5. **Cast** : Enter remplace la sélection d’origine (ou colle à la place) dans l’app source ; Esc ne modifie pas l’app.
6. **Re-transform** : Ctrl+R relance et met à jour overlay + diff.
7. **Copy** : Ctrl+C met le résultat dans le clipboard utilisateur.
8. **Handoff** : l’action « Continue in agent » lance / focus l’agent default avec un contexte utilisable (sélection + résultat) — détail exact **à vérifier** mais action visible et non no-op.
9. **Prompt libre** : l’utilisateur peut saisir un prompt ad hoc et obtenir un cast.
10. **Preset CRUD minimal** : ajouter / éditer / supprimer un preset sans rebuild du plugin (fichier config).
11. **Thème** : overlay lisible sur au moins un thème dark et un thème light Omarchy (tokens).
12. **Sécurité** : le process agent du transform tourne tools-off ; pas de clé API stockée par le plugin.
13. **Cancel / error** : agent down ou timeout → message ; pas de paste partiel silencieux.

---

## 10. Open questions pour JB

1. **Plugin id final** : `nomdelasociete.recast` vs `jbr.recast` vs autre namespace ?
2. **Kind shell** : overlay fullscreen vs panel ancré vs combo bar-widget+overlay ?
3. **Hotkeys** : Super+Shift+R / P / E OK, ou alignement strict sur une seule touche type Raycast Quick Fix ?
4. **Handoff agent** : que doit-il coller exactement dans l’agent (prompt template) ? Mode unattended `omarchy agent prompt` ou session interactive ?
5. **Clipboard lease** : après Cast, laisser le résultat sur le clipboard (filet de sécu text-transform) ou restaurer l’ancien ?
6. **Apps cibles** : Neovim / terminals in-scope MVP ou explicitement « best effort, GUI apps only » ?
7. **Streaming** : bloquant MVP ou nice-to-have ?
8. **Licence / auteur** dans manifest : JB seul, nomdelasociete, Yoshu ?
9. **Réutiliser code** text-transform (`grab`/`put`, agent runners) via copie MIT vs réécriture propre ?
10. **Nom des presets shippés** : EN only, FR, ou bilingues ?
11. **Bar widget idle** : visible (glyph) ou hidden until first use / while running ?
12. **Confirm Cast** sur diffs massifs (>N% changé) — overlay suffit, ou dialog ?

---

## 11. Sources (index)

| Sujet | URL |
|-------|-----|
| Raycast AI Commands | https://manual.raycast.com/ai/ai-commands |
| Raycast Quick Fix changelog | https://www.raycast.com/changelog/macos-beta/0-61 |
| Raycast Language Tool extension | https://www.raycast.com/lucastaonline/raycast-language-tool |
| llm-quick-actions | https://github.com/ivnvxd/llm-quick-actions |
| Tinycast README | https://github.com/abue-ammar/tinycast |
| Tinycast quick-actions.md | https://raw.githubusercontent.com/abue-ammar/tinycast/main/docs/features/quick-actions.md |
| Tinycast PR #314 (diff UI, closed) | https://github.com/abue-ammar/tinycast/pull/314 |
| Omarchy shell plugins | https://omarchy.org/manual/shell-plugins/ |
| Omarchy develop plugin | https://plugins.omarchy.org/develop.html |
| Omarchy dotfiles / bindings.lua | https://omarchy.org/manual/dotfiles/ |
| Omarchy AI / default agent | https://omarchy.org/manual/ai/ |
| Meeting recorder | https://github.com/jankeesvw/omarchy-meeting-recorder |
| Text transform | https://github.com/jankeesvw/omarchy-text-transform |
| hypr-ai-grammar | https://github.com/ahasdemir/hypr-ai-grammar |
| Ce repo | https://github.com/nomdelasociete/recast |

---

*Fin du cahier des charges. Toute API Omarchy non confirmée ci-dessus reste « à vérifier » avant code.*
