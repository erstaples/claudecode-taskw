#!/usr/bin/env bash
# timew-report.sh — Generate a formatted Timewarrior time report
#
# Usage:
#   timew-report.sh [period] [filter...]
#
# Periods: today, yesterday, week, lastweek, month, lastmonth
# Filters: project:<name>, type:<category>, or any timew tag

set -euo pipefail

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

period_to_range() {
    case "$1" in
        today)     echo ":day" ;;
        yesterday) echo ":yesterday" ;;
        week)      echo ":week" ;;
        lastweek)  echo ":lastweek" ;;
        month)     echo ":month" ;;
        lastmonth) echo ":lastmonth" ;;
        *)         echo "" ;;  # caller handles unknown
    esac
}

main() {
    check_timew

    local period="${1:-today}"
    shift || true  # remaining args are filters

    local range
    range=$(period_to_range "$period")

    local period_label="$period"
    local extra_filter=""

    if [[ -z "$range" ]]; then
        # Unknown period — treat as a project name filter, default to week range
        extra_filter="project:${period}"
        range=":week"
        period_label="week (project:${period})"
    fi

    # Collect any additional filter args
    local filters=("$@")
    [[ -n "$extra_filter" ]] && filters=("$extra_filter" "${filters[@]}")

    echo "================================================"
    echo " Timewarrior Report — ${period_label}"
    echo "================================================"
    echo ""

    echo "--- Summary ---"
    timew summary "$range" "${filters[@]}" 2>/dev/null || echo "(no data for this period)"

    echo ""
    echo "--- Per-Project Totals ---"
    # Get unique project tags and run summary for each
    local projects
    projects=$(timew export "$range" "${filters[@]}" 2>/dev/null \
        | grep -oP '"project:[^"]*"' \
        | sort -u \
        | tr -d '"' || true)

    if [[ -z "$projects" ]]; then
        echo "(no project tags found)"
    else
        while IFS= read -r proj; do
            echo ""
            echo "  ${proj}:"
            timew summary "$range" "$proj" "${filters[@]}" 2>/dev/null \
                | tail -n +2 \
                | sed 's/^/    /' || true
        done <<< "$projects"
    fi

    echo ""
    echo "--- Per-Type Totals ---"
    local types
    types=$(timew export "$range" "${filters[@]}" 2>/dev/null \
        | grep -oP '"type:[^"]*"' \
        | sort -u \
        | tr -d '"' || true)

    if [[ -z "$types" ]]; then
        echo "(no type tags found)"
    else
        while IFS= read -r typ; do
            echo ""
            echo "  ${typ}:"
            timew summary "$range" "$typ" "${filters[@]}" 2>/dev/null \
                | tail -n +2 \
                | sed 's/^/    /' || true
        done <<< "$types"
    fi

    echo ""
    echo "--- Raw Export ---"
    echo "To export raw JSON for this period:"
    local filter_str="${filters[*]:-}"
    echo "  timew export $range ${filter_str}"
}

main "$@"
