#!/usr/bin/env bash
#
# update-preview-alias.sh - Update the 'preview' alias to point to a new variant
#
# Usage:
#   ./scripts/update-preview-alias.sh <variant_name>
#   ./scripts/update-preview-alias.sh claudesp22
#
# This script:
#   1. Updates the preview alias in the shell config
#   2. Optionally syncs to chezmoi
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

# Default alias file locations (check in order)
ALIAS_FILES=(
  "$HOME/.config/zsh/aliases/general.zsh"
  "$HOME/.zshrc"
  "$HOME/.bashrc"
  "$HOME/.bash_aliases"
)

find_alias_file() {
  for file in "${ALIAS_FILES[@]}"; do
    if [[ -f "$file" ]] && grep -q "alias preview=" "$file" 2>/dev/null; then
      echo "$file"
      return 0
    fi
  done
  echo ""
}

show_help() {
  cat <<'HELP'
update-preview-alias.sh - Update the 'preview' alias to point to a new variant

Usage:
  ./scripts/update-preview-alias.sh <variant_name> [OPTIONS]

Arguments:
  variant_name    The variant to point preview alias to (e.g., claudesp22)

Options:
  --chezmoi         Sync to chezmoi without prompting
  --interactive     Enable interactive prompts (disabled by default)
  --help, -h        Show this help

This script:
  1. Finds the shell config file containing the preview alias
  2. Updates it to point to the specified variant
  3. Syncs to chezmoi if --chezmoi flag is passed

Examples:
  ./scripts/update-preview-alias.sh claudesp23 --chezmoi
  ./scripts/update-preview-alias.sh claudesp20    # Rollback to older version
HELP
}

main() {
  local variant_name=""
  local sync_chezmoi=false
  local interactive=false

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --help|-h)
        show_help
        exit 0
        ;;
      --chezmoi)
        sync_chezmoi=true
        shift
        ;;
      --interactive)
        interactive=true
        shift
        ;;
      -*)
        log_error "Unknown option: $1"
        exit 1
        ;;
      *)
        variant_name="$1"
        shift
        ;;
    esac
  done

  if [[ -z "$variant_name" ]]; then
    log_error "Usage: $0 <variant_name> [--chezmoi]"
    log_error "Example: $0 claudesp22 --chezmoi"
    log_error "Run with --help for more info"
    exit 1
  fi

  # Verify variant exists
  local wrapper="$HOME/.local/bin/$variant_name"
  if [[ ! -x "$wrapper" ]]; then
    log_error "Variant not found: $wrapper"
    log_error "Create it first with: ./scripts/create-versioned-variant.sh"
    exit 1
  fi

  # Find alias file
  local alias_file
  alias_file="$(find_alias_file)"

  if [[ -z "$alias_file" ]]; then
    log_warn "No existing 'preview' alias found in standard locations"
    log_info "Checked: ${ALIAS_FILES[*]}"

    # Offer to create in first available file
    for file in "${ALIAS_FILES[@]}"; do
      if [[ -f "$file" ]]; then
        alias_file="$file"
        break
      fi
    done

    if [[ -z "$alias_file" ]]; then
      log_error "No shell config file found"
      exit 1
    fi

    log_info "Will add alias to: $alias_file"
    echo "alias preview='$variant_name --dangerously-skip-permissions'" >> "$alias_file"
    log_success "Added preview alias"
  else
    log_info "Found alias file: $alias_file"

    # Show current alias
    local current
    current="$(grep "alias preview=" "$alias_file" | head -1)"
    log_info "Current: $current"

    # Update alias using sed
    local new_alias="alias preview='$variant_name --dangerously-skip-permissions'"

    if [[ "$(uname)" == "Darwin" ]]; then
      # macOS sed requires empty string for -i
      sed -i '' "s|alias preview=.*|$new_alias|" "$alias_file"
    else
      sed -i "s|alias preview=.*|$new_alias|" "$alias_file"
    fi

    log_success "Updated: $new_alias"
  fi

  # Check for chezmoi
  if command -v chezmoi &>/dev/null; then
    if [[ "$sync_chezmoi" == true ]]; then
      log_info "Syncing to chezmoi"
      chezmoi add "$alias_file"
      log_success "Added to chezmoi"

      local chezmoi_dir
      chezmoi_dir="$(chezmoi source-path)"
      if [[ -d "$chezmoi_dir/.git" ]]; then
        cd "$chezmoi_dir"
        git add -A
        git commit -m "Update preview alias to $variant_name" || true
        git push && log_success "Pushed to remote"
      fi
    elif [[ "$interactive" == true ]]; then
      log_info "Chezmoi detected"
      read -p "Sync to chezmoi and push? [Y/n] " -n 1 -r
      echo
      if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        chezmoi add "$alias_file"
        log_success "Added to chezmoi"

        local chezmoi_dir
        chezmoi_dir="$(chezmoi source-path)"
        if [[ -d "$chezmoi_dir/.git" ]]; then
          read -p "Commit and push? [Y/n] " -n 1 -r
          echo
          if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            cd "$chezmoi_dir"
            git add -A
            git commit -m "Update preview alias to $variant_name" || true
            git push
            log_success "Pushed to remote"
          fi
        fi
      fi
    else
      log_info "Chezmoi detected. Use --chezmoi to sync automatically."
    fi
  fi

  echo
  log_success "Done!"
  echo
  echo "Reload your shell:"
  echo "  source ~/.zshrc"
  echo "  # or"
  echo "  exec zsh"
}

main "$@"
