#!/usr/bin/env bash
# Audit an external, provider-neutral agent workspace without modifying it.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

usage() {
  cat <<'USAGE'
Usage: doctor.sh --config PATH

Check the configured target project, external instruction projections, and
provider skill projections. Exit status is the number of drift items.
USAGE
}

CONFIG=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --config|-c)
      [[ $# -ge 2 ]] || die "--config requires a path"
      CONFIG="$2"
      shift 2
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

hdr "$PROJECT_NAME — external agent workspace doctor"
info "workspace root: $WORKSPACE_ROOT"
info "target project: $TARGET_PATH"

if [[ ! -d "$TARGET_PATH" ]]; then
  drift "target project directory missing: $TARGET_PATH"
else
  ok "target project present"
fi

if [[ ! -d "$WORKSPACE_ROOT" ]]; then
  drift "workspace root missing: $WORKSPACE_ROOT"
fi

if [[ ! -f "$INSTRUCTION_SOURCE" ]]; then
  drift "instruction source missing: $INSTRUCTION_SOURCE"
fi

if [[ ! -d "$SKILLS_SOURCE" ]]; then
  drift "skills source missing: $SKILLS_SOURCE"
fi

assert_outside_project "$WORKSPACE_ROOT" "$TARGET_PATH" "workspace_root"
assert_outside_project "$INSTRUCTION_SOURCE" "$TARGET_PATH" "instruction_source"
assert_outside_project "$SKILLS_SOURCE" "$TARGET_PATH" "skills_source"

INSTRUCTION_DESTINATIONS=()
mapfile -t INSTRUCTION_DESTINATIONS < <(manifest_array instruction_destinations)
if [[ "${#INSTRUCTION_DESTINATIONS[@]}" -eq 0 ]]; then
  drift "instruction_destinations is empty"
fi

for destination_raw in "${INSTRUCTION_DESTINATIONS[@]}"; do
  destination="$(resolve_path "$destination_raw" "$WORKSPACE_ROOT")"
  assert_outside_project "$destination" "$TARGET_PATH" "instruction destination"
  if [[ ! -f "$destination" ]]; then
    drift "instruction projection missing: $destination"
  elif ! cmp -s "$INSTRUCTION_SOURCE" "$destination"; then
    drift "instruction projection differs: $destination"
  else
    ok "instruction projection synced: $(basename "$destination")"
  fi
done

SKILL_DESTINATIONS=()
mapfile -t SKILL_DESTINATIONS < <(manifest_array skill_destinations)
if [[ "${#SKILL_DESTINATIONS[@]}" -eq 0 ]]; then
  drift "skill_destinations is empty"
fi

shopt -s nullglob
SKILL_DIRS=("$SKILLS_SOURCE"/*/)
for destination_raw in "${SKILL_DESTINATIONS[@]}"; do
  destination_root="$(resolve_path "$destination_raw" "$WORKSPACE_ROOT")"
  assert_outside_project "$destination_root" "$TARGET_PATH" "skill destination"
  if [[ ! -d "$destination_root" ]]; then
    drift "provider skill root missing: $destination_root"
    continue
  fi
  for skill_dir in "${SKILL_DIRS[@]}"; do
    skill_name="$(basename "$skill_dir")"
    source_skill="$skill_dir/SKILL.md"
    [[ -f "$source_skill" ]] || continue
    destination_skill="$destination_root/$skill_name/SKILL.md"
    if [[ ! -f "$destination_skill" ]]; then
      drift "skill '$skill_name' missing from $destination_root"
    elif ! cmp -s "$source_skill" "$destination_skill"; then
      drift "skill '$skill_name' differs in $destination_root"
    else
      ok "skill '$skill_name' synced in $destination_raw"
    fi
  done
done

hdr "Summary"
if [[ "$DRIFT_COUNT" -eq 0 ]]; then
  ok "external agent workspace healthy — no drift detected"
  exit 0
fi

err "$DRIFT_COUNT drift item(s) found — run bootstrap.sh to repair"
exit "$DRIFT_COUNT"
