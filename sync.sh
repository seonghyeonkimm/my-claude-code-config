#!/bin/bash
# sync.sh - Sync personal settings between ~/.claude and plugin repository
#
# Marketplace가 commands, skills, agents, rules, hooks를 관리하므로
# 이 스크립트는 marketplace 범위 밖의 개인 설정만 동기화합니다.
#
# Usage:
#   ./sync.sh export   # ~/.claude/ -> repo (capture local changes)
#   ./sync.sh import   # repo -> ~/.claude/ (apply repo settings)
#   ./sync.sh diff     # show differences between local and repo

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_HOME="${HOME}/.claude"

# Files to sync: personal config (stored under config/ in repo)
CONFIG_FILES=(
  "settings.json"
  "statusline.sh"
)

color_red='\033[31m'
color_green='\033[32m'
color_yellow='\033[33m'
color_cyan='\033[36m'
color_reset='\033[0m'

log_info() { printf "${color_cyan}[info]${color_reset} %s\n" "$1"; }
log_ok() { printf "${color_green}[ok]${color_reset} %s\n" "$1"; }
log_warn() { printf "${color_yellow}[warn]${color_reset} %s\n" "$1"; }
log_diff() { printf "${color_red}[diff]${color_reset} %s\n" "$1"; }

do_export() {
  log_info "Exporting personal settings to repo..."

  for file in "${CONFIG_FILES[@]}"; do
    src="$CLAUDE_HOME/$file"
    dst="$SCRIPT_DIR/config/$file"
    if [ -f "$src" ]; then
      mkdir -p "$(dirname "$dst")"
      cp "$src" "$dst"
      log_ok "config/$file"
    else
      log_warn "Skip (not found): $src"
    fi
  done

  echo ""
  log_info "Export complete. Review changes with: git diff"
  log_info "Note: commands, skills, agents, rules, hooks are managed by marketplace."
}

do_import() {
  log_info "Importing personal settings to ~/.claude..."

  for file in "${CONFIG_FILES[@]}"; do
    src="$SCRIPT_DIR/config/$file"
    dst="$CLAUDE_HOME/$file"
    if [ -f "$src" ]; then
      if [ -f "$dst" ]; then
        cp "$dst" "${dst}.bak"
      fi
      mkdir -p "$(dirname "$dst")"
      # Replace hardcoded home paths with current user's home
      sed "s|/Users/[^/\"']*/\\.claude/|$CLAUDE_HOME/|g" "$src" > "$dst"
      log_ok "config/$file (path-adjusted)"
    else
      log_warn "Skip (not in repo): config/$file"
    fi
  done

  # Make config scripts executable
  chmod +x "$CLAUDE_HOME/statusline.sh" 2>/dev/null || true

  echo ""
  log_info "Import complete. Restart Claude Code to apply changes."
  log_info "Note: commands, skills, agents, rules, hooks are managed by marketplace."
}

do_diff() {
  log_info "Comparing personal settings..."
  has_diff=false

  for file in "${CONFIG_FILES[@]}"; do
    local_file="$CLAUDE_HOME/$file"
    repo_file="$SCRIPT_DIR/config/$file"
    if [ ! -f "$local_file" ] && [ ! -f "$repo_file" ]; then
      continue
    elif [ ! -f "$local_file" ]; then
      log_diff "config/$file: only in repo"
      has_diff=true
    elif [ ! -f "$repo_file" ]; then
      log_diff "config/$file: only in local"
      has_diff=true
    elif ! diff -q "$local_file" "$repo_file" >/dev/null 2>&1; then
      log_diff "config/$file: differs"
      diff --color=auto "$repo_file" "$local_file" 2>/dev/null || true
      echo ""
      has_diff=true
    else
      log_ok "config/$file: in sync"
    fi
  done

  echo ""
  if [ "$has_diff" = true ]; then
    log_warn "Some files differ. Use 'export' or 'import' to sync."
  else
    log_ok "All personal settings are in sync."
  fi
  log_info "Note: commands, skills, agents, rules, hooks are managed by marketplace."
}

case "${1:-}" in
  export)
    do_export
    ;;
  import)
    do_import
    ;;
  diff)
    do_diff
    ;;
  *)
    echo "Usage: $0 {export|import|diff}"
    echo ""
    echo "  export  Copy ~/.claude personal settings to this repo"
    echo "  import  Apply repo personal settings to ~/.claude (with backup)"
    echo "  diff    Show differences between local and repo"
    echo ""
    echo "Note: commands, skills, agents, rules, hooks are managed by marketplace."
    exit 1
    ;;
esac
