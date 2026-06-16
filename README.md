# claude-skills

Personal [Claude Code](https://claude.com/claude-code) skills, shared across all my
machines and servers. Drop them into `~/.claude/skills/` and they're available in
every project.

## Install (any machine or server)

This is a **private** repo, so clone it over **SSH** (the machine needs its SSH key
added to your GitHub account — same access you use to push):

```bash
git clone git@github.com:tomimester/claude-skills.git ~/.claude-skills \
  && bash ~/.claude-skills/install.sh
```

Then **restart Claude Code**. To **update** later, on each machine:

```bash
bash ~/.claude-skills/install.sh        # pulls latest + re-links
```

The installer clones this repo to `~/.claude-skills` and **symlinks** each skill into
`~/.claude/skills/`, so updates are just a `git pull` away. It never overwrites a
hand-made skill dir that already exists.

> New machine/server first needs SSH access to GitHub (add its `~/.ssh/id_ed25519.pub`
> to GitHub → Settings → SSH keys, or use agent-forwarding). If you'd rather skip
> per-machine SSH setup, make this repo **public** and use a
> `curl … raw.githubusercontent … | bash` one-liner instead.

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

- Skills are plain Markdown — no secrets.
- Per-project override: drop a `.claude/skills/<name>/` in a repo to shadow one here.
