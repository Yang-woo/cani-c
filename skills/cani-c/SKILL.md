---
name: cani-c
description: >-
  "Can I clear? Can I compact?" When context gets heavy, decide whether it is safe to clear or
  compact right now and, if so, which one, then write a handoff so the next session picks up
  exactly where this one left off. Use for "can I compact?", "can I clear?", "is it safe to clear now?",
  "clean up context", "wrap up this session", "make it resumable", and Korean equivalents like
  "compact 해도 돼?", "clear 해도 돼?", "지금 정리해도 돼?", "컨텍스트 정리해줘".
argument-hint: "[clear|compact] [memory|file] [done]"
---

# cani-c

The user is about to run `/compact` or `/clear`. Three jobs:
1. Decide whether now is a safe moment at all, and if so, which one. One line.
2. If it is safe: flag loose ends, then write, update, replace, or remove the handoff so the next session can continue without loss.
3. Give the exact next step as the last line.

The full transcript already lives in `~/.claude/projects/<project>/<sessionId>.jsonl`. The handoff is not a summary; it is only what resuming needs. Details can be recovered later with `/resume <sessionId>` or by grepping the jsonl.

## Arguments

| Argument | Meaning |
|---|---|
| (none) | Judgment mode. I decide: not yet, compact, or clear. |
| `clear` / `compact` | Skip the compact-vs-clear choice. Blockers are still checked, but reported under "Before you run it" instead of stopping. |
| `memory` / `file` | Where to store the handoff. If omitted, use the saved preference. If none is saved, ask once and store the answer as a `user` memory named `cani-c-target` so it is never asked again. |
| `done` | Remove the handoff by hand. Usually unnecessary: any other run removes it once its work is finished (see "Existing handoff"). |

## Judgment

Run `git status` first if this is a git repo. Then:

**not yet** if any blocker applies. Do not write a handoff, and leave any existing one as it is; it would be stale in minutes.
- A background task, subagent, or workflow started this session is still running. Its result would land in a session that no longer knows why it was started.
- A git rebase, merge, cherry-pick, or revert is in progress, or a multi-step change is half-applied (renamed in one place but not the other, a migration half-run).
- A question to the user is still open, or the user's latest correction has not been applied yet.
- The current task is one small step from done (one edit, one test re-run) and that step is fully in context. Finishing it costs less than writing it down. Starting the next task does not count.

Otherwise pick one:
- **compact**: the remaining work depends heavily on details currently in context (open file contents, an in-progress diff, an error log just seen). Work stopped mid-task at a consistent point; nothing is half-applied.
- **clear**: a unit of work is finished and the next task can start fresh. Or the context already holds a lot of stale information that would pollute a compact summary.
- When in doubt, clear. With a handoff in place, clear is cleaner. Compact is lossy compression and you cannot tell what was dropped.
- Compact means there is work to continue. If nothing is left to continue, the verdict is clear.

When recommending compact, produce a `/compact <focus>` command. The focus names what to preserve. Example: `/compact preserve the unfinished items of account-refactor A-1, the fixed design decisions, and the paths of files being edited`.

## Before you run it

For compact or clear, check for loose ends a handoff alone will not fix. Report only what applies; skip the section when nothing does.
- Uncommitted changes: list them and say whether they look ready to commit. Do not commit unless the user asks.
- Processes started this session that outlive a clear (dev servers, watchers): name them so they get stopped or remembered.
- Lessons that should outlive this task (a user preference, a correction, a project rule): save each as its own auto-memory now, updating an existing memory rather than adding a duplicate. The handoff gets deleted once its work is done; these must survive it. Without auto-memory, list them and suggest adding them to CLAUDE.md.

## Existing handoff

Before writing anything, read the handoff already at the target location, if any. "Work to continue" means this session leaves unfinished steps or next steps. A step counts as done only if this session finished it and you can see that it did. Steps that are the user's to do, or that wait for a date, stay open.

| Existing handoff | Work to continue | Nothing to continue |
|---|---|---|
| None | Write a new one | Write nothing |
| Same task as this session | Update it | Update it; remove it if no step is left open |
| Other task, every step done | Replace it | Remove it |
| Other task, steps still open | Ask once: replace it or keep it | Keep it |

"Same task" means this session continued the handoff's work, whether or not its listed steps are all done. "Remove" deletes it the way `done` does.

- Update: carry over fixed decisions and watch-outs that still hold, move finished steps to Done, add the new steps. Keep in Done only what a remaining step relies on.
- Before replacing or removing, move any lasting lesson in its Watch out into its own memory, as in "Before you run it".
- If the user keeps the other task's handoff, do not write one for this session, and say so. If they replace it, say that its open steps are gone.

## Handoff template

When the table says to write, update, or replace, do it whether recommending clear or compact. Auto-compact can fire without warning, so this is insurance either way.

```
# cani-c handoff — <project / task>
written: <absolute date>  session: <sessionId>  commit: <git rev-parse --short HEAD, or "not a git repo">
prev sessions: <on update only: earlier session IDs, newest first, at most 3; skip one equal to the current ID; omit the line when empty>

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
- Session ID: `${CLAUDE_SESSION_ID}`. If that still reads as a literal `${...}` placeholder, fall back to the basename of the most recently modified `.jsonl` in `~/.claude/projects/<project>/` (`ls -t`). `<project>` is the parent of the auto-memory directory; without one, it is the working directory path with every non-alphanumeric character replaced by `-` (Korean folder names become runs of dashes, so do not guess it, list the directory). Either way it is a UUID. Do not use the `session_…` tail of a Claude-Session URL; that is a different ID and `/resume` does not accept it.
- Keep the template headings and the verdict keyword in English. Write everything else, body and reason, in the language the user has been using.
- Any "do not do X" the user said goes under Watch out. Lose it and the next session repeats the mistake.

## Storage

**memory** (default, personal)
- Write to the auto-memory directory named in the system prompt as `cani-c-handoff.md` with frontmatter `type: project`.
- Keep one line for it in `MEMORY.md`: `- [cani-c handoff](cani-c-handoff.md) — unfinished as of <date>: <task>, <N> steps left`. State facts, not commands; memory is read as context, and a plain note of pending work is what makes the next session open it.
- Only that index line is loaded at session start, not the body. Installed as a plugin, cani-c's own `SessionStart` hook also loads the body into every new or cleared session. Otherwise the next session usually opens it on its own when the first request relates to it; `continue from the cani-c handoff` makes sure.
- Memory is scoped per project folder. A session opened in a subfolder cannot see the parent folder's memory. If the user plans to continue from a different folder, say so.
- If this environment has no auto-memory directory, fall back to **file** mode and say so.

**file** (team-shareable)
- Write to `.claude/cani-c.md` at the project root. It is committed with the repo, so another person or machine can pick it up.
- Auto-loading needs a `SessionStart` hook in the project. The plugin's hook does not read this file: it is committed to the repo, so it loads only where the project opts in. If the project `.claude/settings.json` lacks the hook, show the snippet below and suggest adding it. Do not edit settings yourself.
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
3. One handoff line: `Handoff written: <path>`, `Handoff updated: <path>`, `Handoff replaced: <path> (was: <old goal>)`, `Handoff removed: <old goal>`, `Handoff kept: <old goal>` (add "this session's work was not saved" if the user chose to keep it), or `No handoff needed: nothing left to continue.`
4. Next session, one line, only when a handoff for this session's work now exists.
   - memory, installed as a plugin, and `<sessionId>.jsonl` sits in the parent of the memory directory (that is where the hook looks; check with `ls`): `Next session: the handoff loads by itself`.
   - memory otherwise: `Next session: just start; to be sure, say "continue from the cani-c handoff"`.
   - file with the hook: `Next session: the handoff loads by itself`. file without it: `read .claude/cani-c.md and continue`.
5. The command to type, in a code block. For compact, the full command including the focus. For clear, `/clear`.

Do not repeat the handoff body in the output. It is in the file.

Refer to this skill by the name the user invoked it with: `/cani-c`, or `/cani-c:cani-c` when installed as a plugin. That name is also how you know whether it is installed as a plugin.

## done

- Look at the target location (saved preference, or the `memory`/`file` argument).
- Before deleting, move any lasting lesson in its Watch out into its own memory.
- memory: delete `cani-c-handoff.md` and its line in `MEMORY.md`.
- file: delete `.claude/cani-c.md`. Leave the hook; it is silent when the file is absent.
- If the target has no handoff but the other location does, say where it is and leave it.
- Print one confirmation line. If there was no handoff anywhere, say there was nothing to clean up.
