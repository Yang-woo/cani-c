#!/bin/sh
# SessionStart: show the memory-mode cani-c handoffs, if any, so they land in the new session's context.
# One handoff: print it. Several: list file names only, since which one to continue is the user's call.
# Facts only, no instructions: another session in this folder may still be working on any of them.
# Read-only and silent when there is none. File mode (.claude/cani-c.md) is left out on purpose:
# it is committed to the repo, so loading it stays an opt-in project hook.
# The memory dir sits next to the transcript: ~/.claude/projects/<project>/memory/.
# Backslashes become slashes so escaped Windows paths parse too.
dir=$(tr '\\' '/' | sed -n 's/.*"transcript_path" *: *"\([^"]*\)\/[^/"]*\.jsonl".*/\1/p')/memory
set -- "$dir"/cani-c-handoff*.md
[ -f "$1" ] || exit 0
if [ $# -eq 1 ]; then
  echo "Unfinished work saved by /cani-c in an earlier session, possibly one still running in this folder, at $1:"
  echo
  cat "$1"
else
  echo "Unfinished work saved by /cani-c in earlier sessions, one file per task, in $dir/:"
  for f; do echo "${f##*/}"; done
fi
