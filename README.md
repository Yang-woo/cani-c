# cani-c

**"Can I clear? Can I compact?"**

A Claude Code skill that answers that question for you, writes a handoff, and tells you what to type.

## The problem

Long sessions fill the context window. You reach for `/compact` or `/clear`, but first you type some version of:

- "is it safe to compact now?"
- "can I clear this?"
- "summarize everything so I can continue in a new session"

Every session. Same prompt. And `/compact` is lossy, so you never know what it dropped.

## What cani-c does

```
/cani-c
```

1. **Decides** compact vs clear based on whether the remaining work depends on details currently in context.
2. **Writes a handoff** — goal, fixed decisions, done, next steps in order, files touched, things to watch out for — into Claude Code's auto-memory (default) or a file in your repo.
3. **Gives you the command.** For compact, a `/compact <focus>` that names what to preserve. For clear, just `/clear`.

The next session starts already knowing where you left off. When that work is finished:

```
/cani-c done
```

removes the handoff so stale context stops following you around.

## Arguments

| | |
|---|---|
| `/cani-c` | judge, write handoff, tell me what to type |
| `/cani-c clear` / `/cani-c compact` | skip the judgment |
| `/cani-c memory` / `/cani-c file` | where the handoff goes (asked once, then remembered) |
| `/cani-c done` | clean up after the handoff has been worked through |

## Install

```bash
git clone https://github.com/Yang-woo/cani-c.git
cp -r cani-c/skills/cani-c ~/.claude/skills/cani-c
```

Restart Claude Code. `/cani-c` is now available in every project.

## Memory vs file

**memory** (default) writes to `~/.claude/projects/<project>/memory/`, which Claude Code loads at the start of every session. Nothing lands in your repo. Scoped per project folder.

**file** writes `.claude/cani-c.md` in your repo so teammates and other machines can pick it up. Add a `SessionStart` hook to auto-load it; the skill shows you the snippet.

## Why not just /compact?

`/compact` keeps a summary the model wrote under token pressure. You cannot see what it cut. cani-c writes a structured handoff *before* you compact or clear, and records the session ID so you can `/resume` or grep the original transcript if something is missing.

## License

MIT
