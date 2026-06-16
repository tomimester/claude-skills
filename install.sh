#!/usr/bin/env bash
# Install Tomi's Claude Code skills into ~/.claude/skills on any machine/server.
#
#   curl -fsSL https://raw.githubusercontent.com/tomimester/claude-skills/main/install.sh | bash
#
# Re-run anytime to update (it pulls the latest and re-links).
set -euo pipefail

REPO_URL="${CLAUDE_SKILLS_REPO:-https://github.com/tomimester/claude-skills.git}"
SRC="${CLAUDE_SKILLS_DIR:-$HOME/.claude-skills}"
DEST="$HOME/.claude/skills"

# 1. Clone the skills repo (or update an existing checkout).
if [ -d "$SRC/.git" ]; then
  echo "Updating skills in $SRC …"
  git -C "$SRC" pull --ff-only --quiet
else
  echo "Cloning skills into $SRC …"
  git clone --depth 1 --quiet "$REPO_URL" "$SRC"
fi

# 2. Symlink each skill into ~/.claude/skills so future `git pull`s update them.
mkdir -p "$DEST"
installed=""
skipped=""
for d in "$SRC"/skills/*/; do
  [ -d "$d" ] || continue
  name="$(basename "$d")"
  target="$DEST/$name"
  if [ -L "$target" ]; then
    rm -f "$target"               # replace our own previous symlink
  elif [ -e "$target" ]; then
    skipped="$skipped $name"      # never clobber a real (hand-made) skill dir
    continue
  fi
  ln -s "$d" "$target"
  installed="$installed $name"
done

echo "✅ Installed:${installed:- (none)}"
[ -n "$skipped" ] && echo "⏭  Skipped existing non-symlink dirs:${skipped}"
echo "↻  Restart Claude Code to load the skills (slash commands register at startup)."
