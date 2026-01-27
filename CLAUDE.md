# Claude Instructions for this Repository

This is a personal fork of [realmikekelly/claude-sneakpeek](https://github.com/realmikekelly/claude-sneakpeek).

## Git Remotes

- `origin` - This fork (vabole/claude-sneakpeek) - push and fetch allowed
- `upstream` - Original repo (realmikekelly/claude-sneakpeek) - fetch only, push disabled

## Important Rules

1. **Do NOT create PRs to the original repo** unless explicitly asked
2. All commits and pushes should go to `origin` (this fork)
3. To sync with upstream: `git fetch upstream && git merge upstream/main`

## Purpose

This fork tracks specific Claude Code versions for isolated testing:
- Version pinned in `src/core/constants.ts` (`DEFAULT_NPM_VERSION`)
- Each version gets its own variant (e.g., `claudesp20`, `claudesp23`)

## Version Upgrades

When a new Claude Code version is released:

```bash
./scripts/create-versioned-variant.sh 23        # Create claudesp23
./scripts/update-preview-alias.sh claudesp23    # Update preview alias
```

See [docs/guides/version-upgrade.md](docs/guides/version-upgrade.md) for full documentation.
