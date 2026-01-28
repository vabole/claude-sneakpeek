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

show_help() {
  cat <<'HELP'
create-versioned-variant.sh - Create a versioned claude-sneakpeek variant

Usage:
  ./scripts/create-versioned-variant.sh [VERSION_SUFFIX] [OPTIONS]

Arguments:
  VERSION_SUFFIX    Version suffix (e.g., 22 for claudesp22). Auto-detected if omitted.

Options:
  --provider <name>   Provider: mirror (default), zai, minimax, openrouter
  --api-key <key>     API key for provider
  --help, -h          Show this help

Examples:
  ./scripts/create-versioned-variant.sh              # Auto-detect version
  ./scripts/create-versioned-variant.sh 22           # Create claudesp22
  ./scripts/create-versioned-variant.sh 22 --provider zai --api-key "$Z_AI_API_KEY"
HELP
}

# Main
main() {
  # Handle help flag
  for arg in "$@"; do
    if [[ "$arg" == "--help" || "$arg" == "-h" ]]; then
      show_help
      exit 0
    fi
  done

  local version_suffix_arg="${1:-}"
  shift || true
  local extra_args=("$@")

  # Determine version
  local default_version
  default_version="$(get_default_version)"
  local npm_version
  npm_version="$(get_npm_version)"

  log_info "Version in constants.ts: ${default_version:-unknown}"
  log_info "Latest npm version: ${npm_version:-unknown}"

  # Warn if constants.ts is outdated
  if [[ -n "$npm_version" && -n "$default_version" && "$npm_version" != "$default_version" ]]; then
    log_warn "constants.ts version ($default_version) differs from npm ($npm_version)"
    log_warn "Update src/core/constants.ts if you want the latest version"
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
    log_warn "Variant $variant_name already exists at ~/.local/bin/$variant_name"
    read -p "Overwrite? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      log_info "Aborted."
      exit 0
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

  # Build command (use bun if available, otherwise npm)
  local runner="npm"
  if command -v bun &>/dev/null; then
    runner="bun"
  fi
  local cmd=($runner run dev -- quick --name "$variant_name" --root "$root_dir" --no-tui)
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
