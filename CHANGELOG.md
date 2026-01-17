# Changelog

All notable changes to the Ralph Loop Setup plugin are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.3] - 2026-01-17

### Fixed
- **Corrected plugin update command in README** - Update command requires `plugin-name@marketplace-name` format (`ralph-loop-setup@ralph-loop-setup`), not just plugin name
- Added note explaining how to find full plugin name with `claude plugin list`
- Changed commands to use `claude plugin` CLI format for clarity

## [1.3.2] - 2026-01-15

### Fixed
- **One-task-per-iteration enforcement** - Fresh-context mode was completing ALL tasks in single iteration; changed "end normally" to explicit "EXIT immediately - do NOT continue to other tasks"
- **GitHub issue reference in commit messages** - Added `Fixes #[github_issue]` format to commit instructions for auto-closing issues when PRs merge

## [1.3.1] - 2026-01-13

### Fixed
- **Renamed `--snapshots` to `--screenshots`** - Correct Playwright terminology (snapshot = DOM/accessibility tree, screenshot = visual PNG)
- Removed references to never-implemented `snapshot.ts` and `snapshot-config.json` files
- Simplified screenshot feature to use Playwright MCP directly via `browser_take_screenshot`
- Updated documentation in SKILL.md, README.md, CLAUDE.md, and command templates

## [1.3.0] - 2026-01-13

### Added
- **Token usage tracking** - Monitor now displays input/output tokens, cache reads, and cost per run
- **--screenshot flag** - Instructs Claude to capture UI screenshots via Playwright MCP after iterations
- JSON output format parsing to extract token metrics from Claude CLI

### Changed
- Ralph fresh-context mode now uses `--output-format json` for richer metadata
- Status file includes token accumulation across iterations
- Monitor dashboard displays cost-to-date with formatted numbers

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
- **--screenshot** flag - Instructs Claude to use Playwright MCP for visual screenshots
- Core guardrails: SIGN-001 through SIGN-004
- Branch handling via `--branch` flag or prd.json `branchName`
- Multi-task mode with `--next` flag

## Version History Summary

| Version | Date | Highlights |
|---------|------|------------|
| 1.3.3 | 2026-01-17 | Fixed plugin update command syntax in README |
| 1.3.2 | 2026-01-15 | One-task-per-iteration fix, GitHub issue in commits |
| 1.3.1 | 2026-01-13 | Fixed --snapshots to --screenshots terminology |
| 1.3.0 | 2026-01-13 | Token usage tracking, screenshot flag, JSON output parsing |
| 1.2.0 | 2026-01-13 | Renamed to `/ralph-cancel`, unified stop script, planner command |
| 1.1.0 | 2026-01-13 | Skip field, vertical split, monitoring enhancements |
| 1.0.0 | 2026-01-12 | Initial release |
