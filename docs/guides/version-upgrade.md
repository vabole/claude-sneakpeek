# Version Upgrade Guide

This guide documents how to upgrade to a new Claude Code version while preserving existing variants.

## Overview

The versioned variant approach allows running multiple Claude Code versions side-by-side:

```
~/.local/bin/
├── claudesp19    # Claude Code 2.1.19
├── claudesp20    # Claude Code 2.1.20
└── claudesp22    # Claude Code 2.1.22 (latest)

~/.claude-sneakpeek-19/claudesp19/
~/.claude-sneakpeek-20/claudesp20/
~/.claude-sneakpeek-22/claudesp22/
```

## Quick Upgrade

Use the automated script:

```bash
# Check latest version and create variant
./scripts/create-versioned-variant.sh

# Or specify version explicitly
./scripts/create-versioned-variant.sh 22

# With custom options
./scripts/create-versioned-variant.sh 22 --provider zai --api-key "$Z_AI_API_KEY"
```

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
export const DEFAULT_NPM_VERSION = '2.1.22';  // Update to latest
```

### 3. Create Versioned Variant

```bash
# Pattern: claudesp{VERSION_SUFFIX} with root ~/.claude-sneakpeek-{VERSION_SUFFIX}
npm run dev -- quick \
  --provider mirror \
  --name claudesp22 \
  --root ~/.claude-sneakpeek-22 \
  --no-tui
```

### 4. Verify Installation

```bash
# Check version
~/.local/bin/claudesp22 --version

# Check variant config
cat ~/.claude-sneakpeek-22/claudesp22/variant.json | grep npmVersion
```

### 5. Update Shell Aliases

Edit your shell aliases (e.g., `~/.config/zsh/aliases/general.zsh`):

```bash
# Keep old alias for stability
alias csp='claudesp20 --dangerously-skip-permissions'

# Point preview to latest
alias preview='claudesp22 --dangerously-skip-permissions'
```

### 6. Sync Dotfiles (if using chezmoi)

```bash
chezmoi add ~/.config/zsh/aliases/general.zsh
cd ~/.local/share/chezmoi && git add -A && git commit -m "Update preview alias to claudesp22" && git push
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
| 2.1.19 | claudesp19 | ~/.claude-sneakpeek-19 | ~/.local/bin/claudesp19 |
| 2.1.20 | claudesp20 | ~/.claude-sneakpeek-20 | ~/.local/bin/claudesp20 |
| 2.1.22 | claudesp22 | ~/.claude-sneakpeek-22 | ~/.local/bin/claudesp22 |

The version suffix uses the minor.patch numbers (e.g., `22` for `2.1.22`).

## Provider Options

The default provider is `mirror` (pure Claude). Other options:

```bash
# Z.ai with GLM models
npm run dev -- quick --provider zai --name zai22 --root ~/.claude-sneakpeek-22 --api-key "$Z_AI_API_KEY"

# MiniMax
npm run dev -- quick --provider minimax --name minimax22 --root ~/.claude-sneakpeek-22 --api-key "$MINIMAX_API_KEY"

# OpenRouter (100+ models)
npm run dev -- quick --provider openrouter --name or22 --root ~/.claude-sneakpeek-22 --api-key "$OPENROUTER_API_KEY"
```

## Alias Strategy

Recommended alias setup for managing versions:

```bash
# Stable - points to tested version
alias csp='claudesp20 --dangerously-skip-permissions'

# Preview - points to latest for testing
alias preview='claudesp22 --dangerously-skip-permissions'

# Explicit version aliases (optional)
alias csp19='claudesp19 --dangerously-skip-permissions'
alias csp20='claudesp20 --dangerously-skip-permissions'
alias csp22='claudesp22 --dangerously-skip-permissions'
```

## Rollback

If the new version has issues, simply update the `preview` alias back:

```bash
alias preview='claudesp20 --dangerously-skip-permissions'
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

1. Check `src/core/constants.ts` has correct `DEFAULT_NPM_VERSION`
2. The script uses whatever version is in constants

### Wrapper Not Found

Ensure `~/.local/bin` is in your PATH:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

### Permission Denied

```bash
chmod +x ~/.local/bin/claudesp22
```
