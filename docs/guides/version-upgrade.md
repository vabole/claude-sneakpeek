# Version Upgrade Guide

This guide documents how to upgrade to a new Claude Code version while preserving existing variants.

## Overview

The versioned variant approach allows running multiple Claude Code versions side-by-side:

```
~/.local/bin/
├── claudesp20    # Claude Code 2.1.20
├── claudesp22    # Claude Code 2.1.22
└── claudesp23    # Claude Code 2.1.23 (latest)

~/.claude-sneakpeek-20/claudesp20/
~/.claude-sneakpeek-22/claudesp22/
~/.claude-sneakpeek-23/claudesp23/
```

## Quick Upgrade (Two Commands)

```bash
# 1. Create variant and update alias
./scripts/upgrade.sh 24

# 2. Link session history, skills, and plugins to ~/.claude
./scripts/link-session-history.sh 24 --force

# 3. Reload shell
source ~/.zshrc
```

## What Each Script Does

### upgrade.sh

```bash
./scripts/upgrade.sh 24
```

This command:
1. Updates `constants.ts` to the latest npm version
2. Creates the variant (overwrites if exists)
3. Updates the `preview` alias
4. Syncs to chezmoi
5. Commits and pushes to fork

Options:
```bash
./scripts/upgrade.sh              # Auto-detect latest version
./scripts/upgrade.sh 24           # Specific version
./scripts/upgrade.sh --dry-run    # Preview what would happen
./scripts/upgrade.sh --no-commit  # Skip git commit/push
./scripts/upgrade.sh --no-chezmoi # Skip chezmoi sync
```

### link-session-history.sh

```bash
./scripts/link-session-history.sh 24 --force
```

This command symlinks variant config to `~/.claude` so the variant shares:
- `projects/` - Session history (for `claude -r` / `preview -r`)
- `session-env/` - Per-session environment data
- `skills/` - Custom skills
- `plugins/` - Installed plugins
- `history.jsonl` - Command history

Options:
```bash
./scripts/link-session-history.sh 24           # Create symlinks (skip existing)
./scripts/link-session-history.sh 24 --force   # Backup and replace existing
```

## Individual Scripts

### Create Variant

```bash
# Basic usage
./scripts/create-versioned-variant.sh 23

# With options
./scripts/create-versioned-variant.sh 23 --force --update-constants
./scripts/create-versioned-variant.sh 23 --provider zai --api-key "$Z_AI_API_KEY"
```

Options:
- `--force`, `-f` - Overwrite existing variant without prompting
- `--update-constants` - Auto-update constants.ts to latest npm version
- `--interactive`, `-i` - Enable interactive prompts (disabled by default)
- `--provider <name>` - Provider: mirror (default), zai, minimax, openrouter
- `--api-key <key>` - API key for provider

### Update Preview Alias

```bash
# Basic usage
./scripts/update-preview-alias.sh claudesp24

# With chezmoi sync
./scripts/update-preview-alias.sh claudesp24 --chezmoi

# Interactive mode
./scripts/update-preview-alias.sh claudesp24 --interactive
```

Options:
- `--chezmoi` - Sync to chezmoi without prompting
- `--interactive` - Enable interactive prompts

### Link Session History

```bash
# Basic usage
./scripts/link-session-history.sh 24

# Force replace existing (backs up first)
./scripts/link-session-history.sh 24 --force
```

Options:
- `--force`, `-f` - Backup and replace existing directories

**Why symlink?** Without symlinks, the variant has its own isolated config. Symlinking to `~/.claude` means:
- `preview -r` shows the same sessions as `claude -r`
- Skills and plugins are shared
- Command history is shared

## Manual Upgrade Steps

### 1. Check Latest Version

```bash
# Check what's available on npm
npm view @anthropic-ai/claude-code version

# Check current constant in the fork
grep DEFAULT_NPM_VERSION src/core/constants.ts
```

### 2. Update Version Constant (if needed)

If the fork's constant is outdated, update `src/core/constants.ts`:

```typescript
export const DEFAULT_NPM_VERSION = '2.1.23';  // Update to latest
```

### 3. Create Versioned Variant

```bash
# Pattern: claudesp{VERSION_SUFFIX} with root ~/.claude-sneakpeek-{VERSION_SUFFIX}
npm run dev -- quick \
  --provider mirror \
  --name claudesp23 \
  --root ~/.claude-sneakpeek-23 \
  --no-tui
```

### 4. Verify Installation

```bash
# Check version
~/.local/bin/claudesp23 --version

# Check variant config
cat ~/.claude-sneakpeek-23/claudesp23/variant.json | grep npmVersion
```

### 5. Update Shell Aliases

Edit your shell aliases (e.g., `~/.config/zsh/aliases/general.zsh`):

```bash
# Keep old alias for stability
alias csp='claudesp20 --dangerously-skip-permissions'

# Point preview to latest
alias preview='claudesp23 --dangerously-skip-permissions'
```

### 6. Sync Dotfiles (if using chezmoi)

```bash
chezmoi add ~/.config/zsh/aliases/general.zsh
cd ~/.local/share/chezmoi && git add -A && git commit -m "Update preview alias to claudesp23" && git push
```

### 7. Reload Shell

```bash
source ~/.zshrc
# or
exec zsh
```

## Naming Convention

| Version | Variant Name | Root Directory | Wrapper |
|---------|--------------|----------------|---------|
| 2.1.20 | claudesp20 | ~/.claude-sneakpeek-20 | ~/.local/bin/claudesp20 |
| 2.1.22 | claudesp22 | ~/.claude-sneakpeek-22 | ~/.local/bin/claudesp22 |
| 2.1.23 | claudesp23 | ~/.claude-sneakpeek-23 | ~/.local/bin/claudesp23 |

The version suffix uses the patch number (e.g., `23` for `2.1.23`).

## Provider Options

The default provider is `mirror` (pure Claude). Other options:

```bash
# Z.ai with GLM models
./scripts/create-versioned-variant.sh 23 --provider zai --api-key "$Z_AI_API_KEY"

# MiniMax
./scripts/create-versioned-variant.sh 23 --provider minimax --api-key "$MINIMAX_API_KEY"

# OpenRouter (100+ models)
./scripts/create-versioned-variant.sh 23 --provider openrouter --api-key "$OPENROUTER_API_KEY"
```

## Alias Strategy

Recommended alias setup for managing versions:

```bash
# Stable - points to tested version
alias csp='claudesp22 --dangerously-skip-permissions'

# Preview - points to latest for testing
alias preview='claudesp23 --dangerously-skip-permissions'

# Explicit version aliases (optional)
alias csp20='claudesp20 --dangerously-skip-permissions'
alias csp22='claudesp22 --dangerously-skip-permissions'
alias csp23='claudesp23 --dangerously-skip-permissions'
```

## Rollback

If the new version has issues, simply update the `preview` alias back:

```bash
./scripts/update-preview-alias.sh claudesp22 --chezmoi
```

Old variants remain fully functional.

## Cleanup

To remove old variants:

```bash
# Remove variant
npm run dev -- remove claudesp19

# Or manually
rm -rf ~/.claude-sneakpeek-19
rm ~/.local/bin/claudesp19
```

## Troubleshooting

### Version Mismatch

If `create-versioned-variant.sh` creates wrong version:

1. Use `--update-constants` flag to auto-update
2. Or manually edit `src/core/constants.ts`

### Variant Already Exists

Use `--force` flag to overwrite:

```bash
./scripts/create-versioned-variant.sh 23 --force
```

### Wrapper Not Found

Ensure `~/.local/bin` is in your PATH:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

### Permission Denied

```bash
chmod +x ~/.local/bin/claudesp23
```
