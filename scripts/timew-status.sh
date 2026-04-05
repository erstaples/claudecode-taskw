#!/usr/bin/env bash
# timew-status.sh — Show current Timewarrior tracking state

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

    echo "=== Timewarrior Status ==="
    echo ""

    local active
    active=$(timew get dom.active 2>/dev/null || echo "0")

    if [[ "$active" == "1" ]]; then
        echo "Status: RUNNING"
        echo ""
        echo "Current interval:"
        timew get dom.active.tag.count &>/dev/null && timew 2>/dev/null || true
    else
        echo "Status: STOPPED"
    fi

    echo ""

    # Show saved state and check for discrepancies
    if [[ -f "$STATE_FILE" && -s "$STATE_FILE" ]]; then
        local project task type
        project=$(grep '^PROJECT=' "$STATE_FILE" | cut -d= -f2- || true)
        task=$(grep '^TASK=' "$STATE_FILE" | cut -d= -f2- || true)
        type=$(grep '^TYPE=' "$STATE_FILE" | cut -d= -f2- || true)

        echo "Saved context (~/.claude-timew-current):"
        echo "  Project : ${project:-<not set>}"
        echo "  Task    : ${task:-<not set>}"
        echo "  Type    : ${type:-<not set>}"

        # Warn if timew is stopped but state file exists (possible manual stop)
        if [[ "$active" != "1" ]]; then
            echo ""
            echo "NOTE: Timer is stopped but saved context exists."
            echo "      Use '/task resume' to resume, or '/task start' for a new task."
        fi
    else
        echo "No saved context (no active or paused task)."
    fi

    echo ""
    echo "=== Today's Summary ==="
    timew summary :day 2>/dev/null || echo "(no intervals today)"
}

main "$@"
