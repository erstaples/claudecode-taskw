---
name: timewarrior
description: |
  Integrates with Timewarrior (timew) for zero-friction time tracking across Claude Code sessions.

  Activate this skill when:
  - Session starts (check ~/.claude-timew-current for an active task)
  - User runs /task, /timew, or /timetrack commands
  - User mentions "time tracking", "track time", "log my time", "how long did I spend", "weekly report", "time report"
  - User says they are starting, switching, pausing, finishing, or completing a task
  - User asks about time spent on a project or task
---

# Timewarrior Skill

Handles time tracking for coding sessions using the [Timewarrior](https://timewarrior.net/) CLI (`timew`).

## Prerequisites

- **Timewarrior >= 1.4** must be installed and on PATH.
  - macOS: `brew install timewarrior`
  - Ubuntu/Debian: `sudo apt install timewarrior`
  - Fedora: `sudo dnf install timew`
- Scripts live at `${CLAUDE_PLUGIN_ROOT}/scripts/` (plugin install) or `scripts/` (manual install).
- State persisted in `~/.claude-timew-current`.

## State File

`~/.claude-timew-current` stores the active task context as key=value pairs:

```
PROJECT=nke-agent
TASK=fix-etcd-quorum-loss
TYPE=bugfix
```

- Written by `timew-start.sh` on every new start
- Read by `timew-start.sh --resume` and at session start
- Preserved by `timew-stop.sh` (normal stop) for later resume
- Deleted by `timew-stop.sh --done` when the task is fully complete
- Timewarrior's `~/.timewarrior/data/` is the source of truth for interval data

## Slash Commands

### `/task start <project> "<task-description>" [type]`

Start tracking a new task. If a timer is already running, it is stopped first.

```
/task start nke-agent "fix etcd quorum loss" bugfix
```

Runs: `${CLAUDE_PLUGIN_ROOT}/scripts/timew-start.sh nke-agent "fix etcd quorum loss" bugfix`

### `/task stop`

Stop the current timer, preserve state for later resume.

Runs: `${CLAUDE_PLUGIN_ROOT}/scripts/timew-stop.sh`

### `/task done`

Stop the timer and clear state (task fully complete).

Runs: `${CLAUDE_PLUGIN_ROOT}/scripts/timew-stop.sh --done`

### `/task resume`

Resume tracking using saved state from `~/.claude-timew-current`.

Runs: `${CLAUDE_PLUGIN_ROOT}/scripts/timew-start.sh --resume`

### `/task status`

Show current tracking state, saved context, and today's summary.

Runs: `${CLAUDE_PLUGIN_ROOT}/scripts/timew-status.sh`

### `/task switch <project> "<task-description>" [type]`

Stop current timer and start a new one (shorthand for stop + start).

Runs: `${CLAUDE_PLUGIN_ROOT}/scripts/timew-stop.sh` then `${CLAUDE_PLUGIN_ROOT}/scripts/timew-start.sh <project> <task> [type]`

### `/task report [period] [filter]`

Generate a time report.

Runs: `${CLAUDE_PLUGIN_ROOT}/scripts/timew-report.sh [period] [filter]`

| Period argument | Time range |
|----------------|-----------|
| `today` (default) | current day |
| `yesterday` | previous day |
| `week` | current week |
| `lastweek` | previous week |
| `month` | current month |
| `lastmonth` | previous month |
| `<project-name>` | treated as project filter, week range |

Examples:
```
/task report
/task report week
/task report week project:nke-agent
/task report month type:bugfix
```

## Tag Taxonomy

All Timewarrior intervals use colon-prefixed tags:

| Tag | Format | Example | Required |
|-----|--------|---------|----------|
| project | `project:<name>` | `project:nke-agent` | Yes |
| task | `task:<description>` | `task:fix-etcd-quorum-loss` | Yes |
| type | `type:<category>` | `type:bugfix` | No (default: `feature`) |

**Valid types:** `bugfix`, `feature`, `chore`, `review`, `investigation`

**Conventions:**
- Project names: short, lowercase, hyphenated (e.g., `nke-agent`, `forge`)
- Task descriptions: kebab-case (e.g., `fix-etcd-quorum-loss`)
- All manual `timew start` calls should go through the scripts to keep tags consistent

## Session Behavior

### On Session Start

1. Check if `~/.claude-timew-current` exists and has content.
2. If it does, tell the user:
   > "Last session you were working on **{PROJECT}/{TASK}** ({TYPE}). Want to resume tracking, or start a new task?"
3. If no state file, ask:
   > "What are you working on? I can start time tracking with `/task start`."
4. **Never auto-start a timer without explicit user confirmation.**

### On Session End

1. If a timer is running and the user says they're wrapping up, remind them:
   > "Timer is still running for **{PROJECT}/{TASK}**. Want me to stop it?"
2. If they confirm, run `${CLAUDE_PLUGIN_ROOT}/scripts/timew-stop.sh`.
3. Show elapsed time for the session.

## Reporting Quick Reference

| Natural language | Command |
|-----------------|---------|
| "how long today?" | `/task report today` |
| "what did I work on this week?" | `/task report week` |
| "show time on nke-agent" | `/task report week project:nke-agent` |
| "last month's bugfix time" | `/task report lastmonth type:bugfix` |
| "yesterday's summary" | `/task report yesterday` |

## Error Handling Rules

- **timew not installed** → Tell the user with install instructions. Do not silently fail or attempt workarounds.
- **timew start fails (already tracking)** → The start script stops the old timer first automatically.
- **State file stale or corrupt** → Run `timew-status.sh` to check timew's actual state, then recreate the state file from that information if the user confirms.
- **Destructive actions** (clearing state, modifying past intervals with `timew modify`) → Always confirm with the user before proceeding.
- **Manual `timew stop` outside scripts** → Status script will detect and warn that state is out of sync.
