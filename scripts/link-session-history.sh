#!/usr/bin/env bash
#
# link-session-history.sh - Symlink variant session history to main ~/.claude
#
# Usage:
#   ./scripts/link-session-history.sh [VERSION_SUFFIX]
#   ./scripts/link-session-history.sh 23
#
# This creates symlinks so the variant shares session history with ~/.claude
#
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

show_help() {
  cat <<'HELP'
link-session-history.sh - Symlink variant session history to main ~/.claude

Usage:
  ./scripts/link-session-history.sh [VERSION_SUFFIX]

Arguments:
  VERSION_SUFFIX    Version suffix (e.g., 23 for claudesp23)

Options:
  --force, -f       Overwrite existing directories (backs them up first)
  --help, -h        Show this help

This script symlinks the following from the variant config to ~/.claude:
  - projects/       Session history per project
  - session-env/    Per-session environment data
  - history.jsonl   Command history
  - skills/         Custom skills
  - plugins/        Installed plugins

Example:
  ./scripts/link-session-history.sh 23
  ./scripts/link-session-history.sh 23 --force
HELP
}

main() {
  local suffix=""
  local force=false

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --help|-h)
        show_help
        exit 0
        ;;
      --force|-f)
        force=true
        shift
        ;;
      -*)
        log_error "Unknown option: $1"
        exit 1
        ;;
      *)
        suffix="$1"
        shift
        ;;
    esac
  done

  if [[ -z "$suffix" ]]; then
    log_error "Version suffix required (e.g., 23)"
    echo "Usage: ./scripts/link-session-history.sh 23"
    exit 1
  fi

  local variant_name="claudesp${suffix}"
  local variant_config="$HOME/.claude-sneakpeek-${suffix}/${variant_name}/config"
  local main_claude="$HOME/.claude"

  # Verify paths exist
  if [[ ! -d "$variant_config" ]]; then
    log_error "Variant config not found: $variant_config"
    log_error "Run ./scripts/create-versioned-variant.sh $suffix first"
    exit 1
  fi

  if [[ ! -d "$main_claude" ]]; then
    log_error "Main Claude directory not found: $main_claude"
    exit 1
  fi

  log_info "Variant: $variant_name"
  log_info "Config dir: $variant_config"
  log_info "Target: $main_claude"
  echo

  # Items to symlink (order matters: directories first, then files)
  local items=("projects" "session-env" "skills" "plugins" "history.jsonl")

  for item in "${items[@]}"; do
    local variant_path="$variant_config/$item"
    local main_path="$main_claude/$item"

    # Check if already a symlink
    if [[ -L "$variant_path" ]]; then
      local target
      target="$(readlink "$variant_path")"
      if [[ "$target" == "$main_path" ]]; then
        log_success "$item already symlinked"
        continue
      else
        log_warn "$item symlinked to different target: $target"
        continue
      fi
    fi

    # Check if exists in variant (not a symlink)
    if [[ -e "$variant_path" ]]; then
      if [[ "$force" == true ]]; then
        local backup="${variant_path}.backup.$(date +%s)"
        log_info "Backing up $item to ${backup##*/}"
        mv "$variant_path" "$backup"
      else
        log_warn "$item exists in variant, use --force to backup and replace"
        continue
      fi
    fi

    # Ensure main path exists
    if [[ ! -e "$main_path" ]]; then
      case "$item" in
        projects|session-env|skills|plugins)
          log_info "Creating $main_path"
          mkdir -p "$main_path"
          ;;
        *)
          log_warn "$item does not exist in $main_claude, skipping"
          continue
          ;;
      esac
    fi

    # Create symlink
    ln -s "$main_path" "$variant_path"
    log_success "Symlinked $item -> $main_path"
  done

  echo
  log_success "Session history linking complete for $variant_name"
}

main "$@"
