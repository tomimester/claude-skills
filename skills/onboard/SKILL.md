---
name: onboard
description: Start-of-session onboarding. Get fully up to speed on a project by reading its handoff/onboarding file and key docs, then continue from the documented next steps. Use when the user says "onboard", "get up to speed", "catch up", "read the handoff", or starts a session on an unfamiliar project.
---

# Onboard

Bring yourself up to speed on the current project quickly, then continue the work.

## Steps

1. **Find and read the handoff file** at the project root: `AGENT_ONBOARDING.md`
   (preferred) or `HANDOFF.md`. Read it fully.
2. **Read the core docs** it points to (and that exist): `CLAUDE.md`, `README.md`,
   any linked plan/spec files, and the persistent memory index if present.
3. **Read the critical code/files** named in those docs so you understand the
   current state — not just the summaries.
4. **Give the user a short briefing** (a few lines): where the project is, what's
   working vs in-flight, and what the documented **next steps** are.
5. **Continue from "Next steps"** — either start the top item, or, if the user
   named a specific task, do that. If the next steps are ambiguous or need a
   decision only the user can make, ask before diving in.

## Notes
- If there's **no handoff file**, fall back to `CLAUDE.md` + `README` + a quick
  look at the repo structure, brief the user, and offer to create a handoff file
  (the `handoff` skill) so future sessions start faster.
- Honour the project's "standing instructions" (build/deploy/test/git conventions)
  from the handoff file throughout the session.
