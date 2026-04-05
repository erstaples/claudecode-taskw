## Time Tracking

This project uses Timewarrior (`timew`) for time tracking via the `timewarrior` Claude Code skill.

At session start:
- Check if `~/.claude-timew-current` exists
- If yes, tell the user what task was last active and ask to resume or start new
- If no, ask what they're working on and offer to start tracking

Slash commands:
- `/task start <project> "<description>" [type]` — start tracking
- `/task stop` — stop and preserve state
- `/task done` — stop and clear state (task complete)
- `/task resume` — resume from saved state
- `/task status` — show current state and today's summary
- `/task switch <project> "<description>" [type]` — stop current and start new
- `/task report [period] [filter]` — generate time report

At session end:
- If a timer is running and the user is wrapping up, remind them to stop it
- Show elapsed time for the session

Scripts are in the timewarrior skill at `scripts/`.
Tags use the format `project:<name>`, `task:<desc>`, `type:<category>`.
Valid types: `bugfix`, `feature`, `chore`, `review`, `investigation`.
