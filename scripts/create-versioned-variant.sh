#!/usr/bin/env bash
#
# create-versioned-variant.sh - Create a versioned claude-sneakpeek variant
#
# Usage:
#   ./scripts/create-versioned-variant.sh [VERSION_SUFFIX] [OPTIONS]
#
# Examples:
#   ./scripts/create-versioned-variant.sh              # Auto-detect version from constants
#   ./scripts/create-versioned-variant.sh 22           # Create claudesp22
#   ./scripts/create-versioned-variant.sh 22 --provider zai --api-key "$Z_AI_API_KEY"
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# Get version from constants.ts
get_default_version() {
  local constants_file="$PROJECT_ROOT/src/core/constants.ts"
  if [[ -f "$constants_file" ]]; then
    grep "DEFAULT_NPM_VERSION" "$constants_file" | sed "s/.*'\([^']*\)'.*/\1/"
  else
    echo ""
  fi
}

# Get latest npm version
get_npm_version() {
  npm view @anthropic-ai/claude-code version 2>/dev/null || echo ""
}

# Extract version suffix (e.g., "2.1.22" -> "22")
version_suffix() {
  local version="$1"
  echo "$version" | sed 's/.*\.\([0-9]*\)$/\1/'
}

# Check if variant already exists
variant_exists() {
  local name="$1"
  [[ -f "$HOME/.local/bin/$name" ]]
}

update_constants_file() {
  local new_version="$1"
  local constants_file="$PROJECT_ROOT/src/core/constants.ts"
  if [[ -f "$constants_file" ]]; then
    if [[ "$(uname)" == "Darwin" ]]; then
      sed -i '' "s/DEFAULT_NPM_VERSION = '[^']*'/DEFAULT_NPM_VERSION = '$new_version'/" "$constants_file"
    else
      sed -i "s/DEFAULT_NPM_VERSION = '[^']*'/DEFAULT_NPM_VERSION = '$new_version'/" "$constants_file"
    fi
    log_success "Updated constants.ts to $new_version"
  fi
}

remove_existing_variant() {
  local name="$1"
  local suffix="$2"
  local root_dir="$HOME/.claude-sneakpeek-${suffix}"
  local wrapper="$HOME/.local/bin/$name"

  if [[ -d "$root_dir" ]]; then
    rm -rf "$root_dir"
    log_info "Removed: $root_dir"
  fi
  if [[ -f "$wrapper" ]]; then
    rm -f "$wrapper"
    log_info "Removed: $wrapper"
  fi
}

show_help() {
  cat <<'HELP'
create-versioned-variant.sh - Create a versioned claude-sneakpeek variant

Usage:
  ./scripts/create-versioned-variant.sh [VERSION_SUFFIX] [OPTIONS]

Arguments:
  VERSION_SUFFIX    Version suffix (e.g., 22 for claudesp22). Auto-detected if omitted.

Options:
  --provider <name>     Provider: mirror (default), zai, minimax, openrouter
  --api-key <key>       API key for provider
  --force, -f           Overwrite existing variant without prompting
  --update-constants    Update constants.ts to latest npm version before creating
  --interactive, -i     Enable interactive prompts (disabled by default)
  --help, -h            Show this help

Examples:
  ./scripts/create-versioned-variant.sh 23 --update-constants --force
  ./scripts/create-versioned-variant.sh 22 --provider zai --api-key "$Z_AI_API_KEY"
HELP
}

# Main
main() {
  local version_suffix_arg=""
  local force=false
  local update_constants=false
  local interactive=false
  local extra_args=()

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
      --update-constants)
        update_constants=true
        shift
        ;;
      --interactive|-i)
        interactive=true
        shift
        ;;
      --provider|--api-key)
        extra_args+=("$1" "$2")
        shift 2
        ;;
      -*)
        extra_args+=("$1")
        shift
        ;;
      *)
        if [[ -z "$version_suffix_arg" ]]; then
          version_suffix_arg="$1"
        else
          extra_args+=("$1")
        fi
        shift
        ;;
    esac
  done

  # Determine version
  local default_version
  default_version="$(get_default_version)"
  local npm_version
  npm_version="$(get_npm_version)"

  log_info "Version in constants.ts: ${default_version:-unknown}"
  log_info "Latest npm version: ${npm_version:-unknown}"

  # Handle version mismatch
  if [[ -n "$npm_version" && -n "$default_version" && "$npm_version" != "$default_version" ]]; then
    if [[ "$update_constants" == true ]]; then
      log_info "Updating constants.ts from $default_version to $npm_version"
      update_constants_file "$npm_version"
      default_version="$npm_version"
    else
      log_warn "constants.ts version ($default_version) differs from npm ($npm_version)"
      log_warn "Use --update-constants to auto-update, or edit src/core/constants.ts manually"
    fi
  fi

  # Determine version suffix
  local suffix
  if [[ -n "$version_suffix_arg" ]]; then
    suffix="$version_suffix_arg"
  elif [[ -n "$default_version" ]]; then
    suffix="$(version_suffix "$default_version")"
  else
    log_error "Cannot determine version. Specify version suffix as argument."
    exit 1
  fi

  local variant_name="claudesp${suffix}"
  local root_dir="$HOME/.claude-sneakpeek-${suffix}"

  log_info "Creating variant: $variant_name"
  log_info "Root directory: $root_dir"

  # Check if already exists
  if variant_exists "$variant_name"; then
    if [[ "$force" == true ]]; then
      log_info "Removing existing variant $variant_name (--force)"
      remove_existing_variant "$variant_name" "$suffix"
    elif [[ "$interactive" == true ]]; then
      log_warn "Variant $variant_name already exists at ~/.local/bin/$variant_name"
      read -p "Overwrite? [y/N] " -n 1 -r
      echo
      if [[ $REPLY =~ ^[Yy]$ ]]; then
        remove_existing_variant "$variant_name" "$suffix"
      else
        log_info "Aborted."
        exit 0
      fi
    else
      log_error "Variant $variant_name already exists. Use --force to overwrite."
      exit 1
    fi
  fi

  # Default provider
  local provider="mirror"
  local has_provider=false
  for arg in "${extra_args[@]:-}"; do
    if [[ "$arg" == "--provider" ]]; then
      has_provider=true
      break
    fi
  done

  # Build command (bun assumed available on all machines)
  local cmd=(bun x tsx src/cli/index.ts quick --name "$variant_name" --root "$root_dir" --no-tui)
  if [[ "$has_provider" == false ]]; then
    cmd+=(--provider "$provider")
  fi
  cmd+=("${extra_args[@]:-}")

  log_info "Running: ${cmd[*]}"
  echo

  # Execute
  cd "$PROJECT_ROOT"
  "${cmd[@]}"

  echo
  log_success "Variant created: $variant_name"

  # Verify
  local wrapper="$HOME/.local/bin/$variant_name"
  if [[ -x "$wrapper" ]]; then
    local installed_version
    installed_version="$("$wrapper" --version 2>&1 | head -1)"
    log_success "Version: $installed_version"
  fi

  # Show next steps
  echo
  echo "Next steps:"
  echo "  1. Test: $variant_name --version"
  echo "  2. Update aliases in ~/.config/zsh/aliases/general.zsh:"
  echo "     alias preview='$variant_name --dangerously-skip-permissions'"
  echo "  3. Sync dotfiles: chezmoi add ~/.config/zsh/aliases/general.zsh"
  echo "  4. Reload: source ~/.zshrc"
}

main "$@"
