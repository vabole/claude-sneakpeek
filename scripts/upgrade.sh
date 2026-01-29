#!/usr/bin/env bash
#
# upgrade.sh - One-command Claude Code version upgrade
#
# Usage:
#   ./scripts/upgrade.sh [VERSION_SUFFIX]
#   ./scripts/upgrade.sh 23
#   ./scripts/upgrade.sh         # Auto-detect from npm
#
# This script:
#   1. Updates constants.ts to the latest npm version
#   2. Creates the versioned variant (with --force)
#   3. Updates the preview alias
#   4. Syncs to chezmoi
#   5. Commits and pushes to fork
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_step() { echo -e "\n${CYAN}=== $* ===${NC}"; }

# Get latest npm version
get_npm_version() {
  npm view @anthropic-ai/claude-code version 2>/dev/null || echo ""
}

# Get version from constants.ts
get_constants_version() {
  local constants_file="$PROJECT_ROOT/src/core/constants.ts"
  if [[ -f "$constants_file" ]]; then
    grep "DEFAULT_NPM_VERSION" "$constants_file" | sed "s/.*'\([^']*\)'.*/\1/"
  else
    echo ""
  fi
}

# Extract version suffix (e.g., "2.1.23" -> "23")
version_suffix() {
  local version="$1"
  echo "$version" | sed 's/.*\.\([0-9]*\)$/\1/'
}

show_help() {
  cat <<'HELP'
upgrade.sh - One-command Claude Code version upgrade

Usage:
  ./scripts/upgrade.sh [VERSION_SUFFIX] [OPTIONS]

Arguments:
  VERSION_SUFFIX    Version suffix (e.g., 23). Auto-detected from npm if omitted.

Options:
  --no-commit       Skip git commit and push
  --no-chezmoi      Skip chezmoi sync
  --dry-run         Show what would be done without executing
  --help, -h        Show this help

This script performs all upgrade steps:
  1. Updates constants.ts to the latest npm version
  2. Creates the versioned variant (overwrites if exists)
  3. Updates the preview alias
  4. Syncs to chezmoi (if installed)
  5. Commits and pushes to fork remote

Examples:
  ./scripts/upgrade.sh 23           # Upgrade to version 23
  ./scripts/upgrade.sh              # Auto-detect latest version
  ./scripts/upgrade.sh --dry-run    # Preview what would happen
HELP
}

main() {
  local version_suffix_arg=""
  local no_commit=false
  local no_chezmoi=false
  local dry_run=false

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --help|-h)
        show_help
        exit 0
        ;;
      --no-commit)
        no_commit=true
        shift
        ;;
      --no-chezmoi)
        no_chezmoi=true
        shift
        ;;
      --dry-run)
        dry_run=true
        shift
        ;;
      -*)
        log_error "Unknown option: $1"
        exit 1
        ;;
      *)
        version_suffix_arg="$1"
        shift
        ;;
    esac
  done

  # Determine versions
  local npm_version
  npm_version="$(get_npm_version)"
  local current_version
  current_version="$(get_constants_version)"

  if [[ -z "$npm_version" ]]; then
    log_error "Could not fetch npm version"
    exit 1
  fi

  log_info "Current version in constants.ts: ${current_version:-unknown}"
  log_info "Latest npm version: $npm_version"

  # Determine target suffix
  local suffix
  if [[ -n "$version_suffix_arg" ]]; then
    suffix="$version_suffix_arg"
  else
    suffix="$(version_suffix "$npm_version")"
  fi

  local variant_name="claudesp${suffix}"

  echo
  log_info "Target variant: $variant_name"
  log_info "Target version: $npm_version"

  if [[ "$dry_run" == true ]]; then
    echo
    log_warn "DRY RUN - would execute:"
    echo "  1. Update constants.ts to $npm_version"
    echo "  2. Create variant $variant_name (--force --update-constants)"
    echo "  3. Update preview alias to $variant_name"
    if [[ "$no_chezmoi" != true ]]; then
      echo "  4. Sync alias to chezmoi"
    fi
    if [[ "$no_commit" != true ]]; then
      echo "  5. Commit and push to fork"
    fi
    exit 0
  fi

  # Step 1: Create variant with --force and --update-constants
  log_step "Creating variant $variant_name"
  "$SCRIPT_DIR/create-versioned-variant.sh" "$suffix" --force --update-constants

  # Step 2: Update preview alias
  log_step "Updating preview alias"
  local chezmoi_flag=""
  if [[ "$no_chezmoi" != true ]] && command -v chezmoi &>/dev/null; then
    chezmoi_flag="--chezmoi"
  fi
  "$SCRIPT_DIR/update-preview-alias.sh" "$variant_name" $chezmoi_flag

  # Step 3: Commit and push
  if [[ "$no_commit" != true ]]; then
    log_step "Committing changes"
    cd "$PROJECT_ROOT"

    if git diff --quiet src/core/constants.ts 2>/dev/null; then
      log_info "No changes to commit in constants.ts"
    else
      git add src/core/constants.ts
      git commit -m "bump claude code to $npm_version

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"

      # Push to fork if remote exists
      if git remote get-url fork &>/dev/null; then
        git push fork main
        log_success "Pushed to fork"
      else
        log_warn "No 'fork' remote found, skipping push"
      fi
    fi
  fi

  # Summary
  log_step "Upgrade complete"
  echo
  log_success "Upgraded to Claude Code $npm_version"
  echo
  echo "Reload your shell to use the new version:"
  echo "  source ~/.zshrc"
  echo
  echo "Then run:"
  echo "  preview --version"
}

main "$@"
