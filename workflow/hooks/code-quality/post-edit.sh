#!/bin/bash
# PostToolUse hook: Biome check + TypeScript type-check after Edit/Write
#
# - Runs `biome check --write` on biome-supported files (auto-fix format + lint)
# - Runs `tsc --noEmit` on TypeScript/TSX files
# - Reports file modifications and errors back to Claude
#
# Replaces: typecheck/post-edit.sh

if ! command -v jq >/dev/null 2>&1; then
  echo "[code-quality] jq is required but not installed" >&2
  exit 0
fi

# --- Helpers ---

file_hash() {
  if command -v md5 >/dev/null 2>&1; then
    md5 -q "$1" 2>/dev/null
  elif command -v md5sum >/dev/null 2>&1; then
    md5sum "$1" 2>/dev/null | cut -d' ' -f1
  fi
}

detect_pm() {
  local dir="$1"
  if [ -f "$dir/pnpm-lock.yaml" ]; then
    echo "pnpm"
  elif [ -f "$dir/yarn.lock" ]; then
    echo "yarn"
  else
    echo "npx"
  fi
}

# timeout (GNU coreutils) / gtimeout (Homebrew) fallback
if command -v timeout >/dev/null 2>&1; then
  TIMEOUT_CMD="timeout"
elif command -v gtimeout >/dev/null 2>&1; then
  TIMEOUT_CMD="gtimeout"
else
  TIMEOUT_CMD=""
fi

run_with_timeout() {
  local secs="$1"; shift
  if [ -n "$TIMEOUT_CMD" ]; then
    "$TIMEOUT_CMD" "$secs" "$@"
  else
    "$@"
  fi
}

# --- Read input ---

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

EXT="${FILE_PATH##*.}"

# --- Biome Check ---

BIOME_SUPPORTED=false
case "$EXT" in
  js|jsx|ts|tsx|json|jsonc|css|graphql)
    BIOME_SUPPORTED=true
    ;;
esac

BIOME_MODIFIED=false

if [ "$BIOME_SUPPORTED" = true ]; then
  # Find nearest biome.json or biome.jsonc
  BIOME_DIR=$(dirname "$FILE_PATH")
  BIOME_CONFIG_FOUND=false
  while [ "$BIOME_DIR" != "/" ]; do
    if [ -f "$BIOME_DIR/biome.json" ] || [ -f "$BIOME_DIR/biome.jsonc" ]; then
      BIOME_CONFIG_FOUND=true
      break
    fi
    BIOME_DIR=$(dirname "$BIOME_DIR")
  done

  if [ "$BIOME_CONFIG_FOUND" = true ]; then
    HASH_BEFORE=$(file_hash "$FILE_PATH")
    PM=$(detect_pm "$BIOME_DIR")

    # Run biome check --write with 15s timeout
    BIOME_OUTPUT=$(cd "$BIOME_DIR" && run_with_timeout 15 "$PM" biome check --write "$FILE_PATH" 2>&1)
    BIOME_EXIT=$?

    HASH_AFTER=$(file_hash "$FILE_PATH")

    if [ -n "$HASH_BEFORE" ] && [ -n "$HASH_AFTER" ] && [ "$HASH_BEFORE" != "$HASH_AFTER" ]; then
      BIOME_MODIFIED=true
    fi

    # Exit 124 = timeout killed the process (not a biome error)
    # Biome non-zero after --write = unfixable errors (parse errors, etc.)
    if [ $BIOME_EXIT -ne 0 ] && [ $BIOME_EXIT -ne 124 ]; then
      echo "Biome errors on $FILE_PATH:" >&2
      echo "$BIOME_OUTPUT" | head -20 >&2
      echo "---" >&2
    fi
  fi
fi

# --- TypeScript Type-Check (TS/TSX only) ---

case "$EXT" in
  ts|tsx)
    DIR=$(dirname "$FILE_PATH")
    while [ "$DIR" != "/" ]; do
      if [ -f "$DIR/tsconfig.json" ]; then
        break
      fi
      DIR=$(dirname "$DIR")
    done

    if [ -f "$DIR/tsconfig.json" ]; then
      cd "$DIR" || exit 0
      PM_TSC=$(detect_pm "$DIR")

      # Capture full output first, then truncate (avoids PIPESTATUS subshell bug)
      FULL_OUTPUT=$(run_with_timeout 30 "$PM_TSC" tsc --noEmit --pretty false 2>&1)
      TSC_EXIT=$?
      OUTPUT=$(echo "$FULL_OUTPUT" | head -20)

      if [ $TSC_EXIT -ne 0 ] && [ -n "$OUTPUT" ]; then
        echo "TypeScript errors found after editing $FILE_PATH:" >&2
        echo "$OUTPUT" >&2
        echo "---" >&2
        echo "Fix these before continuing to avoid build failures." >&2
      fi
    fi
    ;;
esac

# --- Notify Claude if biome modified the file ---

if [ "$BIOME_MODIFIED" = true ]; then
  jq -n \
    --arg ctx "[code-quality] biome check --write auto-fixed $FILE_PATH. The file on disk has been modified. Re-read this file before making further edits." \
    '{
      hookSpecificOutput: {
        hookEventName: "PostToolUse",
        additionalContext: $ctx
      }
    }'
fi

exit 0
