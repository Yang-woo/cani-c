<p align="center"><img src="assets/banner.png" alt="cani-c: Can I clear? Can I compact?"></p>

# cani-c

[English](README.md) · [한국어](README.ko.md)

> **"Can I clear? Can I compact?"** — A [Claude Code](https://claude.ai/code) skill that answers that question for you, writes a handoff, and tells you what to type.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Claude Code Skill](https://img.shields.io/badge/Claude%20Code-skill-8A2BE2)](https://code.claude.com/docs/en/skills)

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

1. **Decides** whether now is a safe moment at all. If a subagent is still running, a rebase is half-done, or the next step is one edit away, it says `not yet`, explains why, and tells you what to finish first. Otherwise it picks compact or clear based on whether the remaining work depends on details currently in context.
2. **Flags loose ends** a handoff will not fix: uncommitted changes, dev servers still running, lessons worth saving as permanent memory.
3. **Writes or updates a handoff** — goal, fixed decisions, done, next steps in order, files touched, things to watch out for — into Claude Code's auto-memory (default) or a file in your repo.
4. **Gives you the command.** For compact, a `/compact <focus>` that names what to preserve. For clear, just `/clear`.

In the next session, just start working. The memory index notes that unfinished work exists, and Claude opens the handoff when your request relates to it. To be sure, say `continue from the cani-c handoff`.

Run `/cani-c` again later and the handoff rolls forward: finished steps move to Done, decisions and watch-outs carry over, and earlier session IDs stay listed. Once every step is done, `/cani-c` removes the handoff instead of writing a new one, so stale context stops following you around. `/cani-c done` does the same by hand. Either way, lasting lessons in its watch-outs are saved to memory before it goes.

If the existing handoff belongs to a different task that still has open steps, `/cani-c` asks once whether to replace it, or leaves it alone when this session has nothing to hand off.

## Example

```
> /cani-c

compact recommended — the payments refactor is mid-diff and the next step needs the error log still in context.
Before you run it:
- 2 uncommitted files, not ready to commit (test_refund.py still failing)
- Saved to memory: the user does not want retry decorators
Handoff written: ~/.claude/projects/-Users-me-app/memory/cani-c-handoff.md
Next session: just start; to be sure, say "continue from the cani-c handoff"

/compact preserve the unfinished items of the payments refactor, the decision to keep Stripe webhooks synchronous, and the paths of files being edited
```

The handoff it wrote:

```markdown
# cani-c handoff — app / payments refactor
written: 2026-09-18  session: 9f2c1b7e-4d3a-4e8b-a1c5-0b6d7e8f9a12  commit: a1b2c3d

## Goal
Move charge creation behind a single PaymentService so retries are idempotent.

## Fixed decisions (do not re-litigate)
- Webhooks stay synchronous. Queue was tried and rejected for ordering bugs.

## Done
- PaymentService.charge() with idempotency key
- Tests for the happy path

## Not done / next steps (in order)
1. Fix the failing test in test_refund.py (KeyError on `charge_id`)
2. Wire the new service into checkout_view.py
3. Delete legacy charge_helpers.py

## Files touched
- src/payments/service.py — new PaymentService
- tests/test_refund.py — failing, see step 1

## Watch out
- Do not add a retry decorator; the user rejected it twice.
```

When it is not a good moment:

```
> /cani-c

not yet — a test run is still in flight and a rename is half-applied.
- The integration-test subagent has not reported back. Its result would land in a session that no longer knows why it ran. Wait for it.
- users.email is renamed in the migration but not in models.py. Finish the rename first.

Run /cani-c again after the tests report and the rename is done.
```

## Arguments

| Command | What it does |
|---|---|
| `/cani-c` | judge (not yet / compact / clear), write handoff, tell me what to type |
| `/cani-c clear` / `/cani-c compact` | skip the compact-vs-clear choice (blockers become warnings) |
| `/cani-c memory` / `/cani-c file` | where the handoff goes (asked once, then remembered) |
| `/cani-c done` | remove the handoff by hand (`/cani-c` already does this once every step is done) |

Works in English and Korean. It also triggers on plain language, no slash needed: "can I compact?", "wrap up this session", "make it resumable", "compact 해도 돼?", "컨텍스트 정리해줘".

## Install

As a plugin, inside Claude Code:

```
/plugin marketplace add Yang-woo/cani-c
/plugin install cani-c@cani-c
```

Or copy the skill by hand and restart Claude Code:

```bash
git clone https://github.com/Yang-woo/cani-c.git
cp -r cani-c/skills/cani-c ~/.claude/skills/cani-c
```

Either way, it is now available in every project. Copied by hand, the command is `/cani-c`. Installed as a plugin, its full name is `/cani-c:cani-c`, and typing `/cani-c` finds it in autocomplete.

Auto memory (`~/.claude/projects/<project>/memory/`) is on by default in Claude Code. If you turned it off with `/memory` or `autoMemoryEnabled: false`, cani-c falls back to file mode and says so.

## Memory vs file

**memory** (default) writes to `~/.claude/projects/<project>/memory/`, whose index Claude Code loads at the start of every session. Only the index line is loaded; it says that unfinished work exists, which is usually enough for the next session to open the handoff. Nothing lands in your repo. Scoped per project folder. If two sessions in the same folder run `/cani-c` at the same time, the later one wins.

**file** writes `.claude/cani-c.md` in your repo so teammates and other machines can pick it up. Add a `SessionStart` hook to auto-load it; the skill shows you the snippet.

## Why not just /compact?

`/compact` keeps a summary the model wrote under token pressure. You cannot see what it cut. cani-c writes a structured handoff *before* you compact or clear, and records session IDs so you can `/resume <id>` or grep the original transcript if something is missing.

The handoff headings stay in English; the body is written in whatever language you were working in.

## Design choices

- **One skill, no sub-commands.** Every variant is an argument.
- **No transcript parser.** The full jsonl is already on disk; the handoff only holds what resuming needs.
- **Never edits your settings.** File mode shows you the hook snippet and lets you paste it.

## Contributing

PRs welcome. Ideas:

- A `PreCompact` hook that writes the handoff automatically before auto-compact fires
- Trigger phrases in more languages
- Real-world handoffs that lost something — open an issue with what was missing

## License

MIT
