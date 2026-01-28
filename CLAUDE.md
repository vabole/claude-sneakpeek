# Claude Instructions for this Fork

This is a personal fork of [mikekelly/claude-sneakpeek](https://github.com/mikekelly/claude-sneakpeek).

## Git Remotes

- `origin` - Upstream repo (mikekelly/claude-sneakpeek) - **fetch only, push disabled**
- `fork` - This fork (vabole/claude-sneakpeek) - push and fetch allowed

## Important Rules

1. **Do NOT create PRs to the original repo** unless explicitly asked
2. All commits and pushes should go to `fork` (this fork)
3. To sync with upstream: `git fetch origin && git rebase origin/main`

## Purpose

This fork tracks specific Claude Code versions for isolated testing:
- Version pinned in `src/core/constants.ts` (`DEFAULT_NPM_VERSION`)
- Each version gets its own variant (e.g., `claudesp20`, `claudesp22`)

## Version Upgrades

When a new Claude Code version is released:

```bash
./scripts/create-versioned-variant.sh 22        # Create claudesp22
./scripts/update-preview-alias.sh claudesp22    # Update preview alias
```

See [docs/guides/version-upgrade.md](docs/guides/version-upgrade.md) for full documentation.

## Quick Reference

See [AGENTS.md](AGENTS.md) for project structure and development commands.
