# claude-skills

Personal [Claude Code](https://claude.com/claude-code) skills, shared across all my
machines and servers. Drop them into `~/.claude/skills/` and they're available in
every project.

## Install (any machine or server)

This repo is **public**, so no SSH key setup is needed — a fresh droplet can install
in one line:

```bash
curl -fsSL https://raw.githubusercontent.com/tomimester/claude-skills/main/install.sh | bash
```

Or, if you'd rather see what you're running before you run it:

```bash
git clone https://github.com/tomimester/claude-skills.git ~/.claude-skills \
  && bash ~/.claude-skills/install.sh
```

Then **restart Claude Code**. To **update** later, on each machine:

```bash
bash ~/.claude-skills/install.sh        # pulls latest + re-links
```

The installer clones this repo to `~/.claude-skills` and **symlinks** each skill into
`~/.claude/skills/`, so updates are just a `git pull` away. It never overwrites a
hand-made skill dir that already exists.

> Cloning over HTTPS means machines can **pull** but not **push**. That's usually what
> you want — servers consume skills, they don't author them. On a machine where you
> *do* want to edit and push, switch the remote to SSH:
>
> ```bash
> git -C ~/.claude-skills remote set-url origin git@github.com:tomimester/claude-skills.git
> ```

## Skills included

| Skill | Use |
| --- | --- |
| **`/onboard`** | Start of session — read the project's `AGENT_ONBOARDING.md` (+ `CLAUDE.md`/README), get up to speed, continue from "Next steps". |
| **`/handoff`** | End of session — create/refresh `AGENT_ONBOARDING.md` (what's done, where we are, next steps) so the next agent picks up exactly here; commit & push. |
| **`/appify`** | Turn an existing web project (webapp or WordPress site) into a native iOS App Store app — RN/Expo + JSON API + auth hand-off + Codemagic→TestFlight + the full submission pipeline, as proven on Mászóedzés. |

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

- Skills are plain Markdown — **no secrets**. The repo is public; treat everything in it as world-readable.
- Per-project override: drop a `.claude/skills/<name>/` in a repo to shadow one here.
