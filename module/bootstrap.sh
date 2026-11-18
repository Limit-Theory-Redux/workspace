#!/usr/bin/env bash
# Bootstrap an external, provider-neutral agent workspace.
#
# This script only writes the configured external workspace and provider
# projection directories. It never writes into the target repository.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

usage() {
  cat <<'USAGE'
Usage: bootstrap.sh --config PATH [--dry-run]

Synchronise an external instruction file and provider skill projections from
the manifest directory into an external project workspace. The target project
is checked but never modified.
USAGE
}

CONFIG=""
DRY_RUN=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --config|-c)
      [[ $# -ge 2 ]] || die "--config requires a path"
      CONFIG="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      die "unknown argument: $1 (use --help for usage)"
      ;;
  esac
done

[[ -n "$CONFIG" ]] || { usage >&2; exit 2; }
load_manifest "$CONFIG"

PROJECT_NAME="$(manifest_get project_name)"
WORKSPACE_ROOT_RAW="$(manifest_get workspace_root)"
TARGET_PATH_RAW="$(manifest_get target_path)"
INSTRUCTION_SOURCE_RAW="$(manifest_get instruction_source)"
SKILLS_SOURCE_RAW="$(manifest_get skills_source)"

[[ -n "$PROJECT_NAME" ]] || die "project_name is required in $MANIFEST_FILE"
[[ -n "$WORKSPACE_ROOT_RAW" ]] || die "workspace_root is required in $MANIFEST_FILE"
[[ -n "$TARGET_PATH_RAW" ]] || die "target_path is required in $MANIFEST_FILE"
[[ -n "$INSTRUCTION_SOURCE_RAW" ]] || die "instruction_source is required in $MANIFEST_FILE"
[[ -n "$SKILLS_SOURCE_RAW" ]] || die "skills_source is required in $MANIFEST_FILE"

WORKSPACE_ROOT="$(resolve_path "$WORKSPACE_ROOT_RAW" "$MANIFEST_DIR")"
TARGET_PATH="$(resolve_path "$TARGET_PATH_RAW" "$MANIFEST_DIR")"
INSTRUCTION_SOURCE="$(resolve_path "$INSTRUCTION_SOURCE_RAW" "$MANIFEST_DIR")"
SKILLS_SOURCE="$(resolve_path "$SKILLS_SOURCE_RAW" "$MANIFEST_DIR")"

if [[ "$DRY_RUN" == "0" ]]; then
  mkdir -p "$WORKSPACE_ROOT"
else
  step "would create workspace root $WORKSPACE_ROOT"
fi

if [[ ! -d "$TARGET_PATH" ]]; then
  warn "target project directory does not exist yet: $TARGET_PATH"
else
  ok "target project found: $TARGET_PATH"
fi

assert_outside_project "$WORKSPACE_ROOT" "$TARGET_PATH" "workspace_root"
assert_outside_project "$INSTRUCTION_SOURCE" "$TARGET_PATH" "instruction_source"
assert_outside_project "$SKILLS_SOURCE" "$TARGET_PATH" "skills_source"

hdr "$PROJECT_NAME — external agent workspace"
info "workspace root: $WORKSPACE_ROOT"
info "target project: $TARGET_PATH"

INSTRUCTION_DESTINATIONS=()
mapfile -t INSTRUCTION_DESTINATIONS < <(manifest_array instruction_destinations)
if [[ "${#INSTRUCTION_DESTINATIONS[@]}" -eq 0 ]]; then
  die "instruction_destinations must contain at least one path"
fi

for destination_raw in "${INSTRUCTION_DESTINATIONS[@]}"; do
  destination="$(resolve_path "$destination_raw" "$WORKSPACE_ROOT")"
  assert_outside_project "$destination" "$TARGET_PATH" "instruction destination"
  copy_file "$INSTRUCTION_SOURCE" "$destination" "$DRY_RUN"
done

[[ -d "$SKILLS_SOURCE" ]] || die "skills_source directory not found: $SKILLS_SOURCE"

SKILL_DESTINATIONS=()
mapfile -t SKILL_DESTINATIONS < <(manifest_array skill_destinations)
if [[ "${#SKILL_DESTINATIONS[@]}" -eq 0 ]]; then
  die "skill_destinations must contain at least one provider directory"
fi

shopt -s nullglob
SKILL_DIRS=("$SKILLS_SOURCE"/*/)
if [[ "${#SKILL_DIRS[@]}" -eq 0 ]]; then
  warn "skills_source contains no skill directories: $SKILLS_SOURCE"
fi

for destination_raw in "${SKILL_DESTINATIONS[@]}"; do
  destination_root="$(resolve_path "$destination_raw" "$WORKSPACE_ROOT")"
  assert_outside_project "$destination_root" "$TARGET_PATH" "skill destination"
  if [[ "$DRY_RUN" == "0" ]]; then
    mkdir -p "$destination_root"
  else
    step "would create provider skill root $destination_root"
  fi

  for skill_dir in "${SKILL_DIRS[@]}"; do
    skill_name="$(basename "$skill_dir")"
    if [[ ! -f "$skill_dir/SKILL.md" ]]; then
      warn "skill '$skill_name' has no SKILL.md — skipping"
      continue
    fi
    destination_skill="$destination_root/$skill_name"
    assert_outside_project "$destination_skill" "$TARGET_PATH" "skill destination"
    if [[ "$DRY_RUN" == "1" ]]; then
      step "would sync skill '$skill_name' → $destination_skill"
      continue
    fi
    mkdir -p "$destination_skill"
    # Merge into the provider projection. Existing unrelated skills and
    # provider metadata are preserved; this module never prunes by default.
    cp -R -- "$skill_dir/." "$destination_skill/"
    ok "skill '$skill_name' synced to $destination_raw"
  done
done

hdr "Done"
ok "external agent workspace bootstrap complete"
info "Run '$SCRIPT_DIR/doctor.sh --config $MANIFEST_FILE' to audit drift."
