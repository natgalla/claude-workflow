#!/usr/bin/env bash
# Propagate agents/ and commands/ to ~/.claude/
# Run from the claude-workflow repo root.
# After creating this file, make it executable: chmod +x sync-dotclaude.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="$HOME/.claude"
SKIP_CONFIRM=false

for arg in "$@"; do
  [[ "$arg" == "-y" ]] && SKIP_CONFIRM=true
done

# Discover source files dynamically
SOURCE_FILES=()
for dir in agents commands; do
  while IFS= read -r -d '' f; do
    rel="${f#"$SCRIPT_DIR/"}"
    SOURCE_FILES+=("$rel")
  done < <(find "$SCRIPT_DIR/$dir" -maxdepth 1 -name "*.md" -type f -print0 | sort -z)
done

# Partition into changed and new
CHANGED=()
NEW_FILES=()
WARN_MISSING=()

for f in "${SOURCE_FILES[@]}"; do
  dest_file="$DEST/$f"
  dest_dir="$(dirname "$dest_file")"
  if [[ ! -f "$dest_file" ]]; then
    NEW_FILES+=("$f")
  elif ! diff -q "$SCRIPT_DIR/$f" "$dest_file" > /dev/null 2>&1; then
    CHANGED+=("$f")
  fi
done

# Warn about files in ~/.claude that are not in the repo (do not delete them)
for dir in agents commands; do
  if [[ -d "$DEST/$dir" ]]; then
    while IFS= read -r -d '' f; do
      rel="${f#"$DEST/"}"
      found=false
      for src in "${SOURCE_FILES[@]}"; do
        [[ "$src" == "$rel" ]] && found=true && break
      done
      if [[ "$found" == false ]]; then
        WARN_MISSING+=("$rel")
      fi
    done < <(find "$DEST/$dir" -maxdepth 1 -name "*.md" -type f -print0 | sort -z)
  fi
done

ALL_TO_COPY=(${CHANGED[@]+"${CHANGED[@]}"} ${NEW_FILES[@]+"${NEW_FILES[@]}"})

if [[ ${#ALL_TO_COPY[@]} -eq 0 ]]; then
  echo "Already in sync — no changes to propagate."
  if [[ ${#WARN_MISSING[@]} -gt 0 ]]; then
    echo ""
    echo "Warning: the following files exist in ~/.claude but not in this repo (skipped — not deleted):"
    for f in "${WARN_MISSING[@]}"; do
      echo "  $f"
    done
  fi
  exit 0
fi

if [[ ${#CHANGED[@]} -gt 0 ]]; then
  echo "Changed files:"
  for f in "${CHANGED[@]}"; do
    echo "  $f"
    diff "$DEST/$f" "$SCRIPT_DIR/$f" || true
    echo ""
  done
fi

if [[ ${#NEW_FILES[@]} -gt 0 ]]; then
  echo "New files (not yet in ~/.claude):"
  for f in "${NEW_FILES[@]}"; do
    echo "  $f"
  done
  echo ""
fi

if [[ ${#WARN_MISSING[@]} -gt 0 ]]; then
  echo "Warning: the following files exist in ~/.claude but not in this repo (will be skipped — not deleted):"
  for f in "${WARN_MISSING[@]}"; do
    echo "  $f"
  done
  echo ""
fi

if [[ "$SKIP_CONFIRM" == false ]]; then
  read -r -p "Copy ${#ALL_TO_COPY[@]} file(s) to ~/.claude? [y/N] " confirm
  [[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }
fi

COPIED=()
for f in "${ALL_TO_COPY[@]}"; do
  dest_file="$DEST/$f"
  dest_dir="$(dirname "$dest_file")"
  mkdir -p "$dest_dir"
  cp "$SCRIPT_DIR/$f" "$dest_file"
  COPIED+=("$f")
  echo "Copied $f"
done

echo ""
echo "Done. ${#COPIED[@]} file(s) copied to $DEST."
echo "(No git commit — ~/.claude is not a git repo.)"
