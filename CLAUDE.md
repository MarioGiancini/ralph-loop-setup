# Ralph Loop Setup - Plugin Maintenance Guide

This file provides guidance to Claude Code when working on this plugin repository.

## Plugin Context

This is a Claude Code plugin that sets up autonomous TDD loops (Ralph Wiggum technique) in projects.

- **Plugin name**: `ralph-loop-setup`
- **Repository**: https://github.com/MarioGiancini/ralph-loop-setup
- **Plugin type**: Skill-based (installed via `/plugin install`)

## Version Management

**IMPORTANT**: Bump the version in `.claude-plugin/plugin.json` on EVERY meaningful change.

### Versioning Rules

Follow semantic versioning (MAJOR.MINOR.PATCH):

| Change Type | Bump | Example |
|-------------|------|---------|
| Breaking changes (command renames, removed features) | MAJOR | 1.x.x → 2.0.0 |
| New features, new templates, new commands | MINOR | 1.1.x → 1.2.0 |
| Bug fixes, documentation updates, small tweaks | PATCH | 1.1.0 → 1.1.1 |

### Version Bump Checklist

Before committing changes:
1. Determine the appropriate version bump (MAJOR/MINOR/PATCH)
2. Update `.claude-plugin/plugin.json` version field
3. Add entry to `CHANGELOG.md` with date and changes
4. Commit with message referencing the version: `chore: bump version to X.Y.Z`

## Official Documentation References

Keep these docs in mind when updating the plugin:

- **Plugin System**: https://code.claude.com/docs/en/plugins
- **Plugin Marketplaces**: https://code.claude.com/docs/en/plugin-marketplaces
- **Skills Documentation**: https://code.claude.com/docs/en/skills
- **Memory Files**: https://code.claude.com/docs/en/memory
- **Claude Code GitHub**: https://github.com/anthropics/claude-code

## Self-Update Checklist

When asked to check for updates or improvements, follow this checklist:

### 1. Check Plugin API Changes

```bash
# Fetch latest plugin docs
WebFetch https://code.claude.com/docs/en/plugins
# Look for: new features, deprecated patterns, schema changes
```

### 2. Check Ralph Technique Evolution

The Ralph Wiggum technique was created by Ryan Carson. Check for updates:
- Search: "Ryan Carson Ralph Wiggum Claude Code 2025/2026"
- Look for: new patterns, improved verification, iteration strategies

### 3. Check Community Patterns

Review community plugins for emerging patterns:
- https://github.com/anthropics/claude-plugins-official
- https://claude-plugins.dev/
- Search: "Claude Code autonomous loop plugin"

### 4. Check Claude Code Changelog

```bash
WebFetch https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md
# Look for: new hooks, new tool capabilities, breaking changes
```

### 5. Update Checklist

After research, consider updating:
- [ ] Template scripts (ralph-fresh.sh, etc.) for new capabilities
- [ ] Command files for new Claude Code features
- [ ] Guardrails for newly discovered failure patterns
- [ ] SKILL.md documentation
- [ ] This CLAUDE.md if patterns changed significantly

## Directory Structure

```
ralph-loop-setup/
├── .claude-plugin/
│   └── plugin.json          # Plugin manifest (NAME, VERSION)
├── CLAUDE.md                 # This file - maintainer guidance
├── CHANGELOG.md              # Version history
├── README.md                 # User-facing installation docs
└── skills/
    └── ralph-loop-setup/
        ├── SKILL.md          # Detailed skill documentation
        └── templates/        # Files installed by the skill
            ├── ralph-loop-command.md
            ├── ralph-cancel-command.md
            ├── ralph-planner.md
            ├── ralph-fresh.sh
            ├── ralph-stop.sh
            ├── ralph-status.sh
            ├── ralph-tail.sh
            ├── prd-template.json
            ├── progress-template.md
            ├── guardrails-template.md
            ├── prompt-template.md
            ├── snapshot.ts
            └── snapshot-config.json
```

## Key Commands (Installed by Skill)

| Command | Purpose |
|---------|---------|
| `/ralph-loop` | Start autonomous loop (fresh-context or same-session) |
| `/ralph-cancel` | Stop active loop (kills processes, cleans state) |
| `/ralph-planner` | Generate prd.json from GitHub issues |

## Recent Changes to Track

- **Skip field** (v1.1.0): Tasks can have `skip: true` to exclude from automation
- **Vertical split** (v1.1.0): Monitor opens in iTerm2 split pane, not new window
- **Unified stop** (v1.2.0): ralph-stop.sh kills both modes, ralph-cancel renamed

## Testing Changes

After modifying templates, test by:
1. Installing in a test project: `/ralph-loop-setup`
2. Running dry-run: `/ralph-loop --next --dry-run`
3. Running with monitor: `/ralph-loop --next --verbose --monitor`
4. Testing cancel: `/ralph-cancel --force`

## Contributor Notes

- This plugin was created by Mario Giancini
- Based on Ryan Carson's "Ralph Wiggum" autonomous TDD technique
- Primary use case: iterating on well-defined tasks until verification passes
