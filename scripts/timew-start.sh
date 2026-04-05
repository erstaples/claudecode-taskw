#!/usr/bin/env bash
# timew-start.sh — Start or resume a Timewarrior tracking interval
#
# Usage:
#   timew-start.sh <project> <task> [type]
#   timew-start.sh --resume

set -euo pipefail

STATE_FILE="${HOME}/.claude-timew-current"
VALID_TYPES=("bugfix" "feature" "chore" "review" "investigation")

die() {
    echo "ERROR: $*" >&2
    exit 1
}

check_timew() {
    if ! command -v timew &>/dev/null; then
        die "Timewarrior (timew) is not installed or not on PATH.
Install it from https://timewarrior.net/ or via your package manager:
  macOS:  brew install timewarrior
  Ubuntu: sudo apt install timewarrior
  Fedora: sudo dnf install timew"
    fi

    # Require timew >= 1.4 (needed for dom.active)
    local ver
    ver=$(timew --version 2>/dev/null | grep -oP '\d+\.\d+' | head -1)
    local major minor
    major=$(echo "$ver" | cut -d. -f1)
    minor=$(echo "$ver" | cut -d. -f2)
    if [[ "$major" -lt 1 ]] || { [[ "$major" -eq 1 ]] && [[ "$minor" -lt 4 ]]; }; then
        die "Timewarrior >= 1.4 required (found $ver). Please upgrade."
    fi
}

normalize_kebab() {
    # lowercase, spaces to hyphens, strip non-alphanumeric except hyphens
    echo "$*" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-'
}

validate_type() {
    local t="$1"
    for v in "${VALID_TYPES[@]}"; do
        [[ "$t" == "$v" ]] && return 0
    done
    die "Invalid type '$t'. Valid types: ${VALID_TYPES[*]}"
}

stop_if_running() {
    local active
    active=$(timew get dom.active 2>/dev/null || echo "0")
    if [[ "$active" == "1" ]]; then
        echo "Stopping current timer first..."
        timew stop
    fi
}

start_tracking() {
    local project="$1"
    local task="$2"
    local type="$3"

    stop_if_running

    timew start "project:${project}" "task:${task}" "type:${type}"

    # Write state file
    cat > "$STATE_FILE" <<EOF
PROJECT=${project}
TASK=${task}
TYPE=${type}
EOF

    echo ""
    echo "Time tracking started:"
    echo "  Project : ${project}"
    echo "  Task    : ${task}"
    echo "  Type    : ${type}"
}

main() {
    check_timew

    if [[ "${1:-}" == "--resume" ]]; then
        [[ -f "$STATE_FILE" && -s "$STATE_FILE" ]] || \
            die "No saved task state found at $STATE_FILE. Use 'timew-start.sh <project> <task> [type]' to start a new task."

        local project task type
        project=$(grep '^PROJECT=' "$STATE_FILE" | cut -d= -f2-)
        task=$(grep '^TASK=' "$STATE_FILE" | cut -d= -f2-)
        type=$(grep '^TYPE=' "$STATE_FILE" | cut -d= -f2-)

        [[ -n "$project" && -n "$task" ]] || \
            die "State file $STATE_FILE is incomplete or corrupt. Start a new task instead."

        echo "Resuming: ${project}/${task} (${type:-feature})"
        start_tracking "$project" "$task" "${type:-feature}"
        return
    fi

    [[ $# -ge 2 ]] || die "Usage: timew-start.sh <project> <task> [type]
       timew-start.sh --resume"

    local project task type
    project=$(normalize_kebab "$1")
    task=$(normalize_kebab "$2")
    type=$(normalize_kebab "${3:-feature}")

    [[ -n "$project" ]] || die "Project name cannot be empty."
    [[ -n "$task" ]]    || die "Task description cannot be empty."

    validate_type "$type"

    start_tracking "$project" "$task" "$type"
}

main "$@"
