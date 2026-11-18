# workspace

`workspace` is a portable workspace layer for keeping repositories, agent
instructions, skills, and provider projections organized outside the source
repositories they support. It gives a project a stable, repeatable layout that
can be recreated across devices, keeps generated agent files out of code
repositories, and makes branch/worktree usage explicit.

The module provides initialization, synchronization, drift auditing, and
provider projection without coupling the workspace to a particular project,
service, task system, secret store, language toolchain, or model provider. A
manifest names the target checkout, external workspace directory, canonical
instructions, and provider skill directories to project.

## Layout

Keep the target checkout and the agent workspace as separate directories:

```text
<workspace>/
├── AGENT.md                 canonical, provider-neutral instructions
├── AGENTS.md                generated projection for AGENTS-aware tools
├── CLAUDE.md                generated projection for Claude Code
├── .agents/skills/          explicit provider projection
└── .claude/skills/          explicit provider projection

<project-repository>/       existing checkout; never written by this module
```

`AGENT.md` is the canonical source. `AGENTS.md` and `CLAUDE.md` are copies for
tools that look for those names. The repository-level `skills/` directory is
the canonical source for shared provider-neutral `SKILL.md` files; a profile
may add its own skills and configured provider directories receive merged
copies.

Important discovery detail: a sibling module is not automatically discovered
when an agent is launched with the project repository as its current working
directory. Launch the agent from the external workspace root, or configure
that root in the provider. A multi-root editor workspace can still open both
directories. The module never creates a symlink or pointer inside the target
repository.

## Manifest

The manifest is a deliberately small top-level TOML subset:

```toml
project_name = "Example Project"
workspace_root = "../example-project-workspace"
target_path = "../example-project"
instruction_source = "AGENT.md"
instruction_destinations = ["AGENT.md", "AGENTS.md", "CLAUDE.md"]
skills_source = "skills"
skill_destinations = [".agents/skills", ".claude/skills"]
```

Relative source paths are resolved from the manifest directory. Destination
paths are resolved from `workspace_root`. Absolute paths and `$HOME`/`~` are
accepted. Every generated destination is checked and rejected if it resolves
inside `target_path`.

## Initialize

For a new project, scaffold an external workspace first:

```sh
bash module/init.sh \
  --output ../example-project-workspace \
  --project-name "Example Project" \
  --target ../example-project
```

Initialization creates only missing files. Run `bootstrap.sh` to project the
instructions and skills, then `doctor.sh` to audit the result.

## Template example

The checked-in example is intentionally fictional and contains no machine-
specific paths or project data. Copy `examples/project-template/`, edit its
manifest for a real checkout, and keep that profile outside the target
repository.

```sh
bash module/bootstrap.sh \
  --config examples/project-template/workspace.toml
bash module/doctor.sh \
  --config examples/project-template/workspace.toml
```

Then launch the agent/editor from the generated external workspace root and
open the target checkout as the project folder.

The repository includes `skills/workspace-usage`, which documents setup,
daily sync, drift repair, branch/worktree handling, and safety. The template
profile uses the shared skills directory directly. Workspace-managed commits
follow Conventional Commits and must keep generated projections, secrets, and
target-repository files out of the staged diff.

## Limit Theory Redux profile

This fork includes a relative Limit Theory Redux profile. The expected layout
is portable across machines:

```text
<parent>/
├── ltheory/              target source checkout
└── workspace/             this external workspace checkout
```

`workspace.toml` points to `../ltheory`, while the canonical project guidance
lives in `profiles/ltheory/AGENT.md` and the project skill lives in
`skills/ltheory-project/`. Nothing is written inside the target checkout.

The root `AGENT.md`, `AGENTS.md`, `CLAUDE.md`, `.agents/skills/` and
`.claude/skills/` are generated projections and are git-ignored, so a fresh
clone has no agent instructions until bootstrap runs. From this workspace
root, run:

```sh
bash module/bootstrap.sh --config workspace.toml
bash module/doctor.sh --config workspace.toml
```

Then launch the agent or editor from this workspace root and open `../ltheory`
as the project directory. If the two checkouts are not siblings on another
machine, update only the relative `target_path` in `workspace.toml`.

## Branches and worktrees

The target path is branch-agnostic. Switching branches in the same checkout
does not require a workspace change because the module never selects or edits a
Git branch.

For simultaneous `git worktree` checkouts, use a separate profile/config per
worktree when their instructions or skills differ. A shared external workspace
is safe only when those files are intentionally identical; otherwise the last
bootstrap would project one worktree's guidance for all users.

## Safety properties

- No network access or repository cloning.
- No project-specific task tracker, integration server, provider SDK, or
  secret dependency.
- No writes inside the target repository; the guard is enforced at runtime.
- No destructive pruning: unrelated skills and provider metadata are kept.
- `doctor.sh` is read-only and returns the number of drift items.

## Local verification

```sh
bash tests/test.sh
```

The fixture test creates a temporary target and external workspace, runs the
real bootstrap and doctor scripts, verifies both provider projections, and
confirms that an invalid destination inside the target is rejected.
