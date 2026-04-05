# Claude Code × Timewarrior

A Claude Code skill that integrates with [Timewarrior](https://timewarrior.net/) (`timew`) for zero-friction time tracking across coding sessions.

Claude Code handles starting/stopping timers, persisting task context between sessions, and generating reports — all via simple `/task` slash commands.

## Requirements

- [Timewarrior](https://timewarrior.net/) >= 1.4
- Claude Code

## Install

**First, install Timewarrior:**

```bash
# macOS
brew install timewarrior

# Ubuntu/Debian
sudo apt install timewarrior

# Fedora
sudo dnf install timew
```

### Option A — Claude Code Plugin (recommended)

Install directly from the plugin marketplace:

```bash
# Add this repo as a marketplace
claude plugin marketplace add erstaples/claudecode-taskw

# Install the plugin (user scope — available across all projects)
claude plugin install timewarrior@claudecode-taskw --scope user

# Or project scope — shared with your team via version control
claude plugin install timewarrior@claudecode-taskw --scope project
```

The plugin is immediately available. Skills are namespaced as `/timewarrior:task` or via the `/task` shorthand defined in your CLAUDE.md.

### Option B — Manual install

```bash
git clone https://github.com/erstaples/claudecode-taskw.git
cd claudecode-taskw
./install.sh
```

The installer will:
- Verify `timew >= 1.4` is on your PATH
- Copy `SKILL.md` and `scripts/` to `~/.claude/skills/timewarrior/`
- Print the CLAUDE.md snippet to add

To install to a custom location:

```bash
./install.sh --skill-dir /path/to/skills/timewarrior
```

**Add the snippet to your CLAUDE.md**

The installer prints a block to paste. Add it to `~/.claude/CLAUDE.md` for global time tracking, or to a project-level `CLAUDE.md` for per-project tracking.

## Usage

### Slash Commands

| Command | Description |
|---------|-------------|
| `/task start <project> "<description>" [type]` | Start tracking a new task |
| `/task stop` | Stop the timer, preserve state for later |
| `/task done` | Stop the timer and mark the task complete |
| `/task resume` | Resume the last paused task |
| `/task status` | Show current state and today's summary |
| `/task switch <project> "<description>" [type]` | Stop current task and start a new one |
| `/task report [period] [filter]` | Generate a time report |

**Examples:**

```
/task start nke-agent "fix etcd quorum loss" bugfix
/task start forge "add VIP allocation" feature
/task stop
/task resume
/task done
/task status
/task report week
/task report week project:nke-agent
/task report lastmonth type:bugfix
```

### Task Types

Valid values for the optional `[type]` argument (defaults to `feature`):

- `feature`
- `bugfix`
- `chore`
- `review`
- `investigation`

### Session Behavior

At the **start of each session**, Claude Code will check for a saved task and prompt:

> "Last session you were working on **nke-agent/fix-etcd-quorum-loss** (bugfix). Want to resume tracking, or start a new task?"

At the **end of a session**, if a timer is still running, Claude Code will remind you to stop it.

## How It Works

### Tag Taxonomy

All intervals are tagged with a consistent structure that enables clean filtering:

| Tag | Format | Example |
|-----|--------|---------|
| project | `project:<name>` | `project:nke-agent` |
| task | `task:<description>` | `task:fix-etcd-quorum-loss` |
| type | `type:<category>` | `type:bugfix` |

Task names are automatically normalized to kebab-case — `"Fix Etcd Quorum Loss"` becomes `fix-etcd-quorum-loss`.

### State File

`~/.claude-timew-current` stores the active task context between sessions:

```
PROJECT=nke-agent
TASK=fix-etcd-quorum-loss
TYPE=bugfix
```

Timewarrior's `~/.timewarrior/data/` remains the source of truth for all interval data.

### Direct `timew` Queries

Because all intervals use structured tags, you can query them directly:

```bash
# Summary for a specific project
timew summary project:nke-agent

# All bugfixes this week
timew summary :week type:bugfix

# Raw JSON export
timew export :month project:forge
```

## Scripts

The scripts in `scripts/` can also be run directly:

```bash
scripts/timew-start.sh <project> <task> [type]
scripts/timew-start.sh --resume
scripts/timew-stop.sh
scripts/timew-stop.sh --done
scripts/timew-status.sh
scripts/timew-report.sh [period] [filter...]
```
