#!/bin/sh
# SessionStart: print the memory-mode cani-c handoff, if any, so it lands in the new session's context.
# Read-only and silent when there is none. File mode (.claude/cani-c.md) is left out on purpose:
# it is committed to the repo, so loading it stays an opt-in project hook.
# The memory dir sits next to the transcript: ~/.claude/projects/<project>/memory/.
# Backslashes become slashes so escaped Windows paths parse too.
dir=$(tr '\\' '/' | sed -n 's/.*"transcript_path" *: *"\([^"]*\)\/[^/"]*\.jsonl".*/\1/p')
f="$dir/memory/cani-c-handoff.md"
[ -f "$f" ] || exit 0
echo "Unfinished work from an earlier session, saved by /cani-c at $f:"
echo
cat "$f"
