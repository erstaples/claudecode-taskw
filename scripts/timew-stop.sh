#!/usr/bin/env bash
# timew-stop.sh — Stop the current Timewarrior timer
#
# Usage:
#   timew-stop.sh           # stop and preserve state
#   timew-stop.sh --done    # stop and clear state (task complete)

set -euo pipefail

STATE_FILE="${HOME}/.claude-timew-current"

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
}

main() {
    check_timew

    local done_flag=0
    [[ "${1:-}" == "--done" ]] && done_flag=1

    # Check if a timer is running
    local active
    active=$(timew get dom.active 2>/dev/null || echo "0")
    if [[ "$active" != "1" ]]; then
        echo "No timer is currently running."
        exit 0
    fi

    # Read context before stopping
    local project="" task="" type=""
    if [[ -f "$STATE_FILE" && -s "$STATE_FILE" ]]; then
        project=$(grep '^PROJECT=' "$STATE_FILE" | cut -d= -f2- || true)
        task=$(grep '^TASK=' "$STATE_FILE" | cut -d= -f2- || true)
        type=$(grep '^TYPE=' "$STATE_FILE" | cut -d= -f2- || true)
    fi

    timew stop

    echo ""
    if [[ -n "$project" ]]; then
        echo "Stopped tracking: ${project}/${task} (${type})"
    else
        echo "Timer stopped."
    fi

    echo ""
    echo "Recent intervals:"
    timew summary :day 2>/dev/null || true

    if [[ "$done_flag" -eq 1 ]]; then
        if [[ -f "$STATE_FILE" ]]; then
            rm -f "$STATE_FILE"
            echo ""
            echo "Task marked complete. State cleared."
        fi
    else
        echo ""
        echo "State preserved at $STATE_FILE — use '/task resume' to continue later."
    fi
}

main "$@"
