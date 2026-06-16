---
name: handoff
description: End-of-session handoff. Capture or refresh a project handoff file (AGENT_ONBOARDING.md) so another agent can pick up exactly where this one left off. Use when the user says "do a handoff", "end-of-session handoff", "save everything for the next agent", "wrap up", or "update the handoff file".
---

# Handoff

Produce or refresh a single, self-contained handoff file so a fresh agent (with
no memory of this session) can get fully up to speed and continue the work.

## Steps

1. **Locate the project root** — the git top level (`git rev-parse --show-toplevel`)
   if in a repo, otherwise the current working directory.
2. **Find the handoff file** at the project root: `AGENT_ONBOARDING.md` (preferred),
   else `HANDOFF.md`. If one exists, **update it in place**; if not, **create
   `AGENT_ONBOARDING.md`**.
3. **Write/refresh these sections** (keep it scannable — scannable beats exhaustive):
   - **Standing instructions** — how to work on this project: stack, how to run/
     build/deploy, how to test, schema/migration steps, git conventions, and any
     non-obvious rules. On first creation, derive these from `CLAUDE.md`/`README`,
     the build tooling, and this session's learnings. Update only if they changed.
   - **Where we are now** — the current state of whatever is in flight (a table or
     short bullets). Be specific and honest about what works vs what's stubbed.
   - **What's been done** — append a brief log of this session's meaningful changes
     (name the files/areas touched).
   - **Next steps — pick up here** — a prioritised, *actionable* list. Each item:
     what to do, where (file paths), and any prerequisite (creds, accounts, infra).
   - **Key references** — paths to the important docs/files/plans/memory.
4. **Be concrete:** name real file paths, commands, and env var names. Note any
   gotchas discovered this session. **Never write secrets** (API keys, tokens,
   passwords) into the file — reference the env var name instead.
5. **Commit & push** if it's a git repo and the project's conventions allow it
   (follow the repo's existing git/commit-message rules; never stage secret/data
   files). If unsure whether to push, ask.
6. Tell the user the file path and that the next agent can be pointed at it.

## Notes
- One file the user can point an agent at ("read <path> and get up to speed") is
  the goal — prefer updating the existing file over creating new ones.
- Keep prose tight; this is a working doc, not documentation theatre.
