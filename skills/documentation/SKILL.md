---
name: documentation
description: Use when a change to Limit Theory Redux adds or changes behaviour, an API, a setting, a key binding, a tool or a workflow. Decides which docs to update in the same change, and how to write them.
---

# Documentation

Docs ship with the change that makes them true. A change that alters how
something works updates the docs in the same PR. Reviewers can ask for missing
docs the same way they ask for a missing test.

## Where docs live

| What changed | Update |
|---|---|
| Concepts or behaviour of an engine module | the README next to the code (e.g. `engine/lib/phx/src/ui/hmgui/README.md`) |
| A Rust API exposed to Lua | the `///` doc comments on the Rust item; they generate `engine/lib/phx/script/meta/*.lua` (never edit generated files) |
| An engine subsystem (renderer, threads, workers) | a page under `doc/engine/` |
| A game-layer subsystem (ECS, UI Router, scenarios) | a page under `doc/script/`, or the README in its `script/` folder |
| Controls and key bindings | `doc/GameControlKeys.txt` |
| Build, tooling, tests, contributor setup | `CONTRIBUTING.md` or the tool's own README |
| Game design: why the game works the way it does | the project wiki, not the repository |
| How agents should work on the project | this workspace (`skills/`, `profiles/ltheory/AGENT.md`) |

Link every new page from `doc/README.md`.

## Procedure

1. Before finishing a change, list what a reader would now find wrong or
   missing: concepts, APIs, settings, keys, commands, file locations.
2. Update or add those docs from the table above, in the same change.
3. If the change touches an area that has a skill in this workspace, check
   that the skill still matches the code. Fix it here, in a separate change to
   this workspace.
4. In the PR description, list the docs you updated, or say why none were needed.

## How to write

- Describe how the code works now, for someone new to it. No history ("we
  changed X"), dates, branch names or PR numbers; PR descriptions carry history.
- Start with what it is and when to use it, then a minimal example, then the
  details.
- Point to the source file for the full API instead of copying signatures
  that will drift.
- Keep pages short, one topic per page.

## Scope

Code comments are covered by `coding-standards`; issue and PR text by
`contribution-workflow`.
