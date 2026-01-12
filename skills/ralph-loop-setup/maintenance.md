# Ralph Loop Maintenance

On-demand maintenance tasks for Ralph loop infrastructure.

## Progress Log Cleanup

The `progress.txt` file grows over time as Ralph completes tasks. While only the last 20 lines are loaded into context, the file itself can get large.

### When to Clean Up

- File exceeds ~200 lines
- Starting a new major project phase
- Context from old tasks is no longer relevant

### Cleanup Procedure

**Option 1: Archive and truncate (recommended)**

```bash
cd [project-dir]  # your project root

# Archive full history
cp plans/progress.txt plans/progress-archive-$(date +%Y%m%d).txt

# Keep last 50 lines (covers ~2-3 recent tasks)
tail -50 plans/progress.txt > plans/progress.txt.new
mv plans/progress.txt.new plans/progress.txt

# Commit the archive
git add plans/progress*.txt
git commit -m "chore: archive and truncate progress.txt"
```

**Option 2: Aggressive truncate (no archive)**

```bash
tail -30 plans/progress.txt > plans/progress.txt.new
mv plans/progress.txt.new plans/progress.txt
```

### What to Keep

The last 20-50 lines should include:
- Most recent completed task summary
- Any cross-task learnings or patterns discovered
- Active context that future iterations might need

### What Can Go

- Detailed step-by-step logs from completed tasks
- Old iteration notes that are now in git history
- Context specific to archived features

## PRD Cleanup

When `prd.json` accumulates many completed tasks:

```bash
# View completed vs pending
jq '.features | group_by(.passes) | map({passes: .[0].passes, count: length})' plans/prd.json

# Optional: Archive completed tasks to separate file
jq '{completed: [.features[] | select(.passes == true)]}' plans/prd.json > plans/prd-completed.json
jq '.features = [.features[] | select(.passes == false)]' plans/prd.json > plans/prd.json.new
mv plans/prd.json.new plans/prd.json
```

## Run Logs Cleanup

Fresh-context mode creates logs in `scripts/ralph/runs/`:

```bash
# View disk usage
du -sh scripts/ralph/runs/

# Remove runs older than 7 days
find scripts/ralph/runs -type d -mtime +7 -exec rm -rf {} +
```
