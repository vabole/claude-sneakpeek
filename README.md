# claude-sneakpeek

Get a parallel build of Claude Code that unlocks feature-flagged capabilities like swarm mode.

Demo video of swarm mode in action: https://x.com/NicerInPerson/status/2014989679796347375

This installs a completely isolated instance of Claude Code—separate config, sessions, MCP servers, and credentials. Your existing Claude Code installation is untouched.

## Install (from local fork)

This fork pins Claude Code version **2.1.20**. Run from the repo directory:

```bash
cd /Users/vabole/repos/claude-sneakpeek
npm run dev -- quick --name claudesp20 --root ~/.claude-sneakpeek-20
```

Add `~/.local/bin` to your PATH if not already (macOS/Linux):

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
```

Then run `claudesp20` to launch.

## Version tracking workflow

When a new Claude Code version is released, update the version in `src/core/constants.ts` and create a new isolated variant:

```bash
# 1. Edit src/core/constants.ts and change DEFAULT_NPM_VERSION to new version (e.g., 2.1.21)

# 2. Create new variant with clean separation
npm run dev -- quick --name claudesp21 --root ~/.claude-sneakpeek-21

# 3. Test the new version works
claudesp21

# 4. Once confirmed working, remove the old version
npm run dev -- remove claudesp20 --root ~/.claude-sneakpeek-20
rm -rf ~/.claude-sneakpeek-20
```

Each version gets:
- Its own config directory (`~/.claude-sneakpeek-XX/`)
- Its own wrapper script (`~/.local/bin/claudespXX`)
- Complete isolation from other versions

## What gets unlocked?

Features that are built into Claude Code but not yet publicly released:

- **Swarm mode** — Native multi-agent orchestration with `TeammateTool`
- **Delegate mode** — Task tool can spawn background agents
- **Team coordination** — Teammate messaging and task ownership

## Commands (local fork)

```bash
# Run from repo directory: /Users/vabole/repos/claude-sneakpeek

npm run dev -- quick --name <name> --root <config-dir>   # Install
npm run dev -- remove <name> --root <config-dir>         # Uninstall
npm run dev -- list --root <config-dir>                  # List variants
npm run dev -- doctor --root <config-dir>                # Health check
```

## Versioned Variants

Run multiple Claude Code versions side-by-side with versioned variants:

```bash
# Create versioned variant (from source)
./scripts/create-versioned-variant.sh 22    # Creates claudesp22

# Update preview alias
./scripts/update-preview-alias.sh claudesp22
```

This gives you:
- `claudesp20` — stable, tested version
- `claudesp22` — latest for testing
- `preview` alias — points to latest

See [docs/guides/version-upgrade.md](docs/guides/version-upgrade.md) for details.

## Where things live

```
~/.claude-sneakpeek-20/claudesp20/
├── npm/           # Claude Code installation
├── config/        # Isolated config, sessions, MCP servers
└── variant.json

~/.local/bin/claudesp20   # Wrapper script
```

## Alternative providers

Supports Z.ai, MiniMax, OpenRouter, and local models via cc-mirror. See [docs/providers.md](docs/providers.md).

## Credits

Fork of [cc-mirror](https://github.com/numman-ali/cc-mirror) by Numman Ali.

## License

MIT
