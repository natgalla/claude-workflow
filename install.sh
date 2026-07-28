#!/usr/bin/env bash
set -euo pipefail

DEST="$HOME/.claude"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$DEST/backups/claude-workflow-$(date +%Y%m%d-%H%M%S)"

echo "DeveloperTown Claude Code workflow installer"
echo "Source: $SCRIPT_DIR"
echo "Destination: $DEST"
echo ""

# Show what will happen before touching anything
echo "This script will:"
echo "  - Back up any existing CLAUDE.md, commands/, agents/, and hooks/ to $BACKUP_DIR"
echo "  - Copy CLAUDE.md → $DEST/CLAUDE.md"
echo "  - Copy commands/ → $DEST/commands/ (merges; existing files with the same name are replaced)"
echo "  - Copy agents/ → $DEST/agents/ (merges; existing files with the same name are replaced)"
echo "  - Copy hooks/ → $DEST/hooks/ (merges; existing files with the same name are replaced)"
echo ""
read -r -p "Continue? [y/N] " confirm
[[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }
echo ""

# Create backup
mkdir -p "$BACKUP_DIR"
[[ -f "$DEST/CLAUDE.md" ]] && cp "$DEST/CLAUDE.md" "$BACKUP_DIR/CLAUDE.md" && echo "Backed up CLAUDE.md"
[[ -d "$DEST/commands" ]] && cp -r "$DEST/commands" "$BACKUP_DIR/commands" && echo "Backed up commands/"
[[ -d "$DEST/agents" ]] && cp -r "$DEST/agents" "$BACKUP_DIR/agents" && echo "Backed up agents/"
[[ -d "$DEST/hooks" ]] && cp -r "$DEST/hooks" "$BACKUP_DIR/hooks" && echo "Backed up hooks/"
echo "Backups written to $BACKUP_DIR"
echo ""

# Install
mkdir -p "$DEST/commands" "$DEST/agents"

cp "$SCRIPT_DIR/CLAUDE.md" "$DEST/CLAUDE.md"
echo "Installed CLAUDE.md"

cp "$SCRIPT_DIR/commands/"*.md "$DEST/commands/"
echo "Installed $(ls "$SCRIPT_DIR/commands/"*.md | wc -l | tr -d ' ') commands"

cp "$SCRIPT_DIR/agents/"*.md "$DEST/agents/"
echo "Installed $(ls "$SCRIPT_DIR/agents/"*.md | wc -l | tr -d ' ') agents"

mkdir -p "$DEST/hooks"
cp "$SCRIPT_DIR/hooks/"*.sh "$DEST/hooks/"
chmod +x "$DEST/hooks/"*.sh
echo "Installed $(ls "$SCRIPT_DIR/hooks/"*.sh | wc -l | tr -d ' ') hooks"

echo ""
echo "Done. Restart Claude Code for changes to take effect."
echo ""
echo "Note: the hipaa-compliance agent reads ~/Documents/dt/domain-docs/hipaa.md."
echo "If that file doesn't exist on your machine, scaffold it with /domain-doc HIPAA"
echo "in any Claude Code session."
echo ""
echo "Note: the historian hooks require wiring in ~/.claude/settings.json."
echo "See hooks/README or the repo README for the required settings snippet."
