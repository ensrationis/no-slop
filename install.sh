#!/usr/bin/env bash
# Install or update pstack + no-slop for Claude Code. Safe to re-run.
#   ./install.sh               plugin, skill, mise and bun
#   ./install.sh --claude-md   also add the always-on rule to ~/.claude/CLAUDE.md
#   ./install.sh --no-deps     skip mise and bun
#   ./install.sh --check       report state only, change nothing
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
skill_dst="$HOME/.claude/skills/no-slop"
claude_md="$HOME/.claude/CLAUDE.md"
check=0 deps=1 add_md=0
for a in "$@"; do
  case $a in
    --check) check=1 ;;
    --no-deps) deps=0 ;;
    --claude-md) add_md=1 ;;
    *) echo "unknown option: $a" >&2; exit 2 ;;
  esac
done

ok() { printf '  ok      %s\n' "$1"; }
todo() { printf '  missing %s\n' "$1"; }
run() { if [ $check = 1 ]; then todo "$1"; else echo "  -> $1"; shift; "$@"; fi; }

command -v claude >/dev/null || { echo "claude CLI not found: install Claude Code first" >&2; exit 1; }

echo "pstack plugin"
if claude plugin marketplace list 2>/dev/null | grep -q cursor-plugins; then ok "marketplace cursor-plugins"
else run "marketplace cursor-plugins" claude plugin marketplace add cursor/plugins; fi
if claude plugin list 2>/dev/null | grep -q 'pstack@cursor-plugins'; then ok "pstack@cursor-plugins"
else run "pstack@cursor-plugins" claude plugin install pstack@cursor-plugins; fi

echo "no-slop skill"
if [ -d "$skill_dst" ] && diff -rq "$here/skill" "$skill_dst" >/dev/null; then ok "$skill_dst is current"
else
  install_skill() {
    # Backups live outside skills/: Claude Code would load a copy left there as a second no-slop.
    if [ -e "$skill_dst" ]; then
      mkdir -p "$HOME/.claude/skills-backup"
      mv "$skill_dst" "$HOME/.claude/skills-backup/no-slop-$(date +%Y%m%d%H%M%S)"
    fi
    mkdir -p "$(dirname "$skill_dst")"
    cp -R "$here/skill" "$skill_dst.tmp" && mv "$skill_dst.tmp" "$skill_dst"
  }
  run "$skill_dst (old copy moved to ~/.claude/skills-backup/)" install_skill
fi

if [ $deps = 1 ]; then
  echo "tools for statechart and watch-pr"
  for t in mise bun; do
    if command -v $t >/dev/null; then ok "$t $($t --version 2>/dev/null | head -1)"
    elif command -v brew >/dev/null; then run "$t" brew install $t
    else todo "$t: install it by hand, see README"; fi
  done
fi

echo "always-on rule in ~/.claude/CLAUDE.md"
if [ -f "$claude_md" ] && grep -q 'no-slop:begin' "$claude_md"; then ok "rule present"
elif [ $add_md = 1 ]; then
  append_rule() { mkdir -p "$(dirname "$claude_md")"; touch "$claude_md"; cp "$claude_md" "$claude_md.bak-$(date +%Y%m%d%H%M%S)"; printf '\n' >> "$claude_md"; cat "$here/claude-md-snippet.md" >> "$claude_md"; }
  run "rule (backup next to CLAUDE.md)" append_rule
else todo "rule: re-run with --claude-md, or paste claude-md-snippet.md yourself"; fi

echo "done. Running sessions pick up the skill at once; /pstack:* commands may need a restart or /reload-plugins."
