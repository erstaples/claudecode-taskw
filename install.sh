#!/usr/bin/env bash
# install.sh — Install the Timewarrior Claude Code skill
#
# Usage:
#   ./install.sh [--skill-dir <path>]
#
# Default install path: ~/.claude/skills/timewarrior/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_SKILL_DIR="${HOME}/.claude/skills/timewarrior"

die() {
    echo "ERROR: $*" >&2
    exit 1
}

check_timew() {
    echo "Checking Timewarrior installation..."

    if ! command -v timew &>/dev/null; then
        die "Timewarrior (timew) is not installed or not on PATH.
Install it first:
  macOS:  brew install timewarrior
  Ubuntu: sudo apt install timewarrior
  Fedora: sudo dnf install timew
Then re-run this installer."
    fi

    local ver
    ver=$(timew --version 2>/dev/null | grep -oP '\d+\.\d+' | head -1)
    local major minor
    major=$(echo "$ver" | cut -d. -f1)
    minor=$(echo "$ver" | cut -d. -f2)

    if [[ "$major" -lt 1 ]] || { [[ "$major" -eq 1 ]] && [[ "$minor" -lt 4 ]]; }; then
        die "Timewarrior >= 1.4 is required (found $ver).
Please upgrade: https://timewarrior.net/docs/install/"
    fi

    echo "  Found timew $ver — OK"
}

install_skill() {
    local skill_dir="$1"

    echo ""
    echo "Installing skill to: $skill_dir"

    mkdir -p "${skill_dir}/scripts"

    # Copy SKILL.md
    cp "${SCRIPT_DIR}/SKILL.md" "${skill_dir}/SKILL.md"

    # Copy scripts
    for script in timew-start.sh timew-stop.sh timew-status.sh timew-report.sh; do
        cp "${SCRIPT_DIR}/scripts/${script}" "${skill_dir}/scripts/${script}"
        chmod +x "${skill_dir}/scripts/${script}"
    done

    echo "  Copied SKILL.md and scripts/"
    echo "  Made scripts executable"
}

print_claudemd_instructions() {
    local skill_dir="$1"

    echo ""
    echo "================================================"
    echo " Installation complete!"
    echo "================================================"
    echo ""
    echo "Add the following block to your ~/.claude/CLAUDE.md"
    echo "(or your project's CLAUDE.md) to enable time tracking:"
    echo ""
    echo "--- COPY BELOW THIS LINE ---"
    cat "${SCRIPT_DIR}/CLAUDEMD_SNIPPET.md"
    echo "--- COPY ABOVE THIS LINE ---"
    echo ""
    echo "Skill directory: $skill_dir"
    echo ""
    echo "Test the installation:"
    echo "  ${skill_dir}/scripts/timew-start.sh myproject \"test task\" feature"
    echo "  ${skill_dir}/scripts/timew-status.sh"
    echo "  ${skill_dir}/scripts/timew-stop.sh --done"
}

main() {
    local skill_dir="$DEFAULT_SKILL_DIR"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --skill-dir)
                [[ -n "${2:-}" ]] || die "--skill-dir requires a path argument"
                skill_dir="$2"
                shift 2
                ;;
            -h|--help)
                echo "Usage: $0 [--skill-dir <path>]"
                echo ""
                echo "Options:"
                echo "  --skill-dir <path>   Install to a custom path (default: $DEFAULT_SKILL_DIR)"
                exit 0
                ;;
            *)
                die "Unknown argument: $1. Run '$0 --help' for usage."
                ;;
        esac
    done

    check_timew
    install_skill "$skill_dir"
    print_claudemd_instructions "$skill_dir"
}

main "$@"
