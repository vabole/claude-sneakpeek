# Local Fork Update Guide

Quick reference for updating Claude Code version in this fork (bun-only system).

## Version Bump Workflow

### 1. Update the version constant

Edit `src/core/constants.ts`:

```typescript
export const DEFAULT_NPM_VERSION = '2.1.20';  // Change to new version
```

### 2. Install new version into existing variant

Since npm isn't available (bun-only), install directly:

```bash
cd ~/.claude-sneakpeek/claudesp/npm
bun add @anthropic-ai/claude-code@2.1.20  # Use new version
```

### 3. Verify installation

```bash
claudesp --version
# Should show: 2.1.20 (Claude Code)

claudesp --print "say hi"
# Should respond
```

## One-liner (after editing constants.ts)

```bash
cd ~/.claude-sneakpeek/claudesp/npm && bun add @anthropic-ai/claude-code@2.1.20
```

## Wrapper Script

Location: `~/.local/bin/claudesp`

If the wrapper uses `node` instead of `bun`, update these lines:

```bash
# Line ~5: change "node" to "bun"
if command -v bun >/dev/null 2>&1; then

# Line ~7: change "node -" to "bun -"
bun - <<'NODE' > "$__claude_sneakpeek_env_file" || true

# Last line: change "exec node" to "exec bun"
exec bun "/Users/vabole/.claude-sneakpeek/claudesp/npm/node_modules/@anthropic-ai/claude-code/cli.js" "$@"
```

## File Locations

| What | Path |
|------|------|
| Version constant | `src/core/constants.ts` |
| Variant directory | `~/.claude-sneakpeek/claudesp/` |
| Claude Code install | `~/.claude-sneakpeek/claudesp/npm/node_modules/@anthropic-ai/claude-code/` |
| Wrapper script | `~/.local/bin/claudesp` |
| Config | `~/.claude-sneakpeek/claudesp/config/` |

## Check Latest Version

```bash
bun info @anthropic-ai/claude-code
```
