# Changelog

All notable changes to the Ralph Loop Setup plugin are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-01-13

### Added
- **ralph-stop.sh** - Unified stop script that kills processes for both fresh-context and same-session modes
- **ralph-planner.md** - New command template for planning tasks from GitHub issues
- **CLAUDE.md** - Plugin maintenance guide with version management rules and self-update checklist
- **CHANGELOG.md** - This file for tracking version history

### Changed
- **BREAKING**: Renamed `/cancel-ralph` to `/ralph-cancel` for consistent namespace
- Updated SKILL.md with documentation for all new features
- Updated templates list to include new files

### Fixed
- Completion promise detection now only checks last 10 lines to avoid false positives

## [1.1.0] - 2026-01-13

### Added
- **Skip field support** - Tasks with `skip: true` are excluded from automation
- **Vertical split monitoring** - iTerm2 opens split pane instead of new window
- **--verbose flag** - Detailed timing and output in fresh-context mode
- **--monitor flag** - Auto-open status dashboard
- **ralph-status.sh** - Status dashboard with live watch mode
- **ralph-tail.sh** - Log tail helper for following iteration output
- **SIGN-005** - Guardrail for skipping manual tasks
- **SIGN-006** - Guardrail for referencing GitHub issues in commits

### Changed
- Updated prd-template.json with `skip` and `skipReason` fields
- Dashboard shows skipped tasks with distinct indicator
- Improved task selection to exclude skipped tasks

### Fixed
- Safe JSON construction in update_status using jq

## [1.0.0] - 2026-01-12

### Added
- Initial release of Ralph Loop Setup plugin
- **ralph-loop.md** - Start command supporting fresh-context and same-session modes
- **cancel-ralph.md** - Cancel command for stopping active loops
- **ralph-fresh.sh** - External bash script for fresh-context iterations
- **stop-hook.sh** - Same-session verification hook
- **prd-template.json** - Task tracking with priority and acceptance criteria
- **progress-template.md** - Cross-session context notes
- **guardrails-template.md** - Learned constraints (Signs) system
- **snapshot.ts** - Visual regression snapshot support
- Core guardrails: SIGN-001 through SIGN-004
- Branch handling via `--branch` flag or prd.json `branchName`
- Multi-task mode with `--next` flag

## Version History Summary

| Version | Date | Highlights |
|---------|------|------------|
| 1.2.0 | 2026-01-13 | Renamed to `/ralph-cancel`, unified stop script, planner command |
| 1.1.0 | 2026-01-13 | Skip field, vertical split, monitoring enhancements |
| 1.0.0 | 2026-01-12 | Initial release |
