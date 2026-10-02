---
name: cani-c
description: >-
  "Can I clear? Can I compact?" When context gets heavy, decide between /compact and /clear,
  and write a handoff so the next session picks up exactly where this one left off.
  Use for "can I compact?", "can I clear?", "clean up context", "wrap up this session",
  "make it resumable", and Korean equivalents like "compact 해도 돼?", "clear 해도 돼?", "컨텍스트 정리해줘".
argument-hint: "[clear|compact] [memory|file] [done]"
---

# cani-c

The user is about to run `/compact` or `/clear`. Three jobs:
1. Decide whether now is a safe moment at all, and if so, which one. One line.
2. If it is safe: flag loose ends, then write a handoff so the next session can continue without loss.
3. Give the exact next step as the last line.

The full transcript already lives in `~/.claude/projects/<project>/<sessionId>.jsonl`. The handoff is not a summary; it is only what resuming needs. Details can be recovered later with `/resume <sessionId>` or by grepping the jsonl.

## Arguments

| Argument | Meaning |
|---|---|
| (none) | Judgment mode. I decide: not yet, compact, or clear. |
| `clear` / `compact` | Skip the compact-vs-clear choice. Blockers are still checked, but reported under "Before you run it" instead of stopping. |
| `memory` / `file` | Where to store the handoff. If omitted, use the saved preference. If none is saved, ask once and store the answer as a `user` memory named `cani-c-target` so it is never asked again. |
| `done` | The previous handoff has been worked through. Delete the memory file and its MEMORY.md index line, or delete the file. |

## Judgment

Run `git status` first if this is a git repo. Then:

**not yet** if any blocker applies. Do not write a handoff; it would be stale in minutes.
- A background task, subagent, or workflow started this session is still running. Its result would land in a session that no longer knows why it was started.
- A git rebase, merge, cherry-pick, or revert is in progress, or a multi-step change is half-applied (renamed in one place but not the other, a migration half-run).
- A question to the user is still open, or the user's latest correction has not been applied yet.
- The next step is small and fully in context (one edit, one test re-run). Finishing it costs less than writing it down.

Otherwise pick one:
- **compact**: the remaining work depends heavily on details currently in context (open file contents, an in-progress diff, an error log just seen). Work was interrupted mid-task.
- **clear**: a unit of work is finished and the next task can start fresh. Or the context already holds a lot of stale information that would pollute a compact summary.
- When in doubt, clear. With a handoff in place, clear is cleaner. Compact is lossy compression and you cannot tell what was dropped.

When recommending compact, produce a `/compact <focus>` command. The focus names what to preserve. Example: `/compact preserve the unfinished items of account-refactor A-1, the fixed design decisions, and the paths of files being edited`.

## Before you run it

For compact or clear, check for loose ends a handoff alone will not fix. Report only what applies; skip the section when nothing does.
- Uncommitted changes: list them and say whether they look ready to commit. Do not commit unless the user asks.
- Processes started this session that outlive a clear (dev servers, watchers): name them so they get stopped or remembered.
- Lessons that should outlive this task (a user preference, a correction, a project rule): save each as its own memory now. `done` deletes the handoff; these must survive it.

## Handoff template

Write the handoff whether recommending clear or compact. Auto-compact can fire without warning, so this is insurance either way.

```
# cani-c handoff — <project / task>
written: <absolute date>  session: <sessionId>  commit: <git rev-parse --short HEAD, or "not a git repo">

## Goal
One or two sentences. What and why.

## Fixed decisions (do not re-litigate)
- ...

## Done
- ...

## Not done / next steps (in order)
1. ...

## Files touched
- path — what changed, one line

## Watch out
- traps, failed attempts, things the user disliked
```

- Convert relative dates to absolute dates.
- The session ID is the basename of the most recently modified `.jsonl` in `~/.claude/projects/<project>/` (`ls -t`). `<project>` is the parent of the auto-memory directory; without one, it is the working directory path with every non-alphanumeric character replaced by `-` (Korean folder names become runs of dashes, so do not guess it, list the directory). It is a UUID. Do not use the `session_…` tail of a Claude-Session URL; that is a different ID and `/resume` does not accept it.
- Keep the template headings and the verdict keyword in English. Write everything else, body and reason, in the language the user has been using.
- Any "do not do X" the user said goes under Watch out. Lose it and the next session repeats the mistake.

## Storage

**memory** (default, personal)
- Write to the auto-memory directory named in the system prompt as `cani-c-handoff.md` with frontmatter `type: project`. Overwrite if it exists.
- Add `- [cani-c handoff](cani-c-handoff.md) — <one-line task name>; read this first when resuming` to `MEMORY.md` if missing; otherwise update the hook text.
- Only the `MEMORY.md` index line is loaded at session start, not the body. The next session must be opened with `continue from the cani-c handoff`.
- Memory is scoped per project folder. A session opened in a subfolder cannot see the parent folder's memory. If the user plans to continue from a different folder, say so.
- If this environment has no auto-memory directory, fall back to **file** mode and say so.

**file** (team-shareable)
- Write to `.claude/cani-c.md` at the project root. It is committed with the repo, so another person or machine can pick it up.
- Auto-loading needs a `SessionStart` hook. If the project `.claude/settings.json` lacks it, show the snippet below and suggest adding it. Do not edit settings yourself.
  ```json
  {"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"cat .claude/cani-c.md 2>/dev/null"}]}]}}
  ```
- Without the hook, tell the user to open the next session with `read .claude/cani-c.md and continue`.

## Output

Short. Fixed order.

**not yet**
1. `not yet`, plus one sentence of reason.
2. One bullet per blocker: what it is, why it blocks, what clears it.
3. Last line: when to run `/cani-c` again.

**compact / clear**
1. `compact recommended` or `clear recommended`, plus one sentence of reason.
2. `Before you run it:` bullets, only if any apply.
3. Where the handoff was written, one line (path).
4. First prompt for the next session, one line. memory: `continue from the cani-c handoff`. file without the hook: `read .claude/cani-c.md and continue`. file with the hook: omit this line.
5. The command to type, in a code block. For compact, the full command including the focus. For clear, `/clear`.

Do not repeat the handoff body in the output. It is in the file.

## done

- memory: delete `cani-c-handoff.md` and its line in `MEMORY.md`.
- file: delete `.claude/cani-c.md`. Leave the hook; it is silent when the file is absent.
- Print one confirmation line.
