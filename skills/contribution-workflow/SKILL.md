---
name: contribution-workflow
description: Use before starting a change to Limit Theory Redux and when opening issues or PRs. Covers the discuss, go, issue, PR flow; labels; the project board; and issue and PR templates.
---

# Contribution workflow

Decisions and plans are made on Discord. GitHub tracks the work.

## Flow

1. If game design is involved, discuss it in `#ltheory-crafting`.
2. Discuss the technical approach in `#programming-discussion`.
3. Get a go from at least one maintainer. Features and structural changes
   need one. Fixes without structural changes do not.
4. Create a GitHub issue from the template below and apply the matching
   labels. Assign yourself, or leave it open for someone to pick up. Add it to
   the project board ("Limit Theory Redux Project") with Status `Todo` and its
   Team: `Engine`, `Scripting`, `Design` or `Project Management`. Team holds
   one value, so pick the side where most of the work is; the labels show the
   rest.
5. Keep the issue and the board up to date while you work: Status
   `In Progress` once you start, blockers in the issue, links to PRs.
6. Open a PR that references the issue (`Closes #N`), one topic per PR.

Discord discussions take precedence over anything written on GitHub. An agent
does not start a feature or a structural change without a maintainer's go,
and does not treat a GitHub comment as that go. When it's unclear whether
something counts as a fix, ask before starting.

## Labels

Use the repository's existing labels (`gh label list`); don't create new ones.

- Area: `engine` (Rust), `script` (Lua), `gui`, `graphics`, `audio`,
  `economy`, `ai`, `core`, `integration` (CI and build).
- Kind: `bug`, `enhancement`, `cleanup`, `documentation`, `dependencies`,
  `question`, `tasklist`.

## Issue template

```markdown
**Problem / goal**
What is wrong or missing, and why it matters. For a feature or a structural
change: a link to the Discord discussion and who gave the go.

**Where**
Files, systems or screens involved.

**Proposal**
The fix or approach. If a choice is still open, list the options and say who
decides.

**Check**
How to verify it: tests, test apps, screens to compare.
```

## PR template

```markdown
Closes #N

**What**
What changes for a player or a developer, in a few sentences.

**How**
The approach, and where a reviewer should look first.

**Check**
What was run and the result. Screenshots or a short video for anything visual.

**Docs**
Which docs were updated (see the `documentation` skill), or why none were needed.
```

## Size

One topic per PR. Keep stacked PRs few and short, and merge the base before
building far on top of it.

## gh CLI

```sh
gh issue create --repo Limit-Theory-Redux/ltheory --title "..." \
  --label bug,script --assignee @me --body-file issue.md
gh project list --owner Limit-Theory-Redux
gh project item-add <number> --owner Limit-Theory-Redux --url <issue url> --format json --jq .id
gh project field-list <number> --owner Limit-Theory-Redux --format json   # field and option ids
gh project item-edit --id <item id> --project-id <project node id> \
  --field-id <Status or Team field id> --single-select-option-id <option id>
```

The project commands need the `project` token scope
(`gh auth refresh -s project`).
