# claude-skills

Personal [Claude Code](https://claude.com/claude-code) skills, shared across all my
machines and servers. Drop them into `~/.claude/skills/` and they're available in
every project.

## Install (any machine or server)

```bash
curl -fsSL https://raw.githubusercontent.com/tomimester/claude-skills/main/install.sh | bash
```

Then **restart Claude Code**. Run the same line anytime to **update** (it pulls the
latest and re-links).

The installer clones this repo to `~/.claude-skills` and **symlinks** each skill into
`~/.claude/skills/`, so updating is just `git pull` (or re-running the line). It never
overwrites a hand-made skill dir that already exists.

## Skills included

| Skill | Use |
| --- | --- |
| **`/onboard`** | Start of session — read the project's `AGENT_ONBOARDING.md` (+ `CLAUDE.md`/README), get up to speed, continue from "Next steps". |
| **`/handoff`** | End of session — create/refresh `AGENT_ONBOARDING.md` (what's done, where we are, next steps) so the next agent picks up exactly here; commit & push. |

## Add a new skill

Create `skills/<name>/SKILL.md` with frontmatter:

```markdown
---
name: <name>
description: <when Claude should use it — be specific; this drives auto-suggest>
---

# <Name>
…instructions…
```

Commit & push, then re-run the install line on each machine.

## Windows

Use WSL or Git Bash for the install line, or manually copy each `skills/<name>/SKILL.md`
into `%USERPROFILE%\.claude\skills\<name>\SKILL.md`.

## Notes

- Skills are plain Markdown — no secrets. Keep this repo **public** so the `curl`
  install works without auth.
- Per-project override: drop a `.claude/skills/<name>/` in a repo to shadow one here.
