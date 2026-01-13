---
description: Plan Ralph loop tasks by selecting from open GitHub issues
allowed-tools: Bash, Read, Write, Edit, AskUserQuestion, TodoWrite
argument-hint: [--labels LABELS] [--milestone NAME] [--limit N] [--project N]
---

# Ralph Planner - Generate prd.json from GitHub Issues

Analyze open GitHub issues and generate prd.json entries for Ralph loop automation.

## Arguments

- `$ARGUMENTS` - Optional filters
- `--labels LABELS` - Filter by labels (comma-separated, e.g., "bug,P1")
- `--milestone NAME` - Filter by milestone
- `--limit N` - Maximum issues to fetch (default: 20)
- `--project N` - GitHub project number to filter by

## Instructions

<instruction>
You are helping plan which GitHub issues to include in a Ralph loop.

**Step 1: Parse Arguments**

Extract from `$ARGUMENTS`:
- `--labels`: Comma-separated label filter
- `--milestone`: Milestone name filter
- `--limit`: Max issues (default 20)
- `--project`: Project number filter

**Step 2: Fetch Open Issues**

Build and run the gh command:

```bash
gh issue list --state open --json number,title,body,labels,milestone,assignees --limit [N]
```

Add filters if specified:
- `--label "bug,P1"` for label filtering
- `--milestone "v2.0"` for milestone filtering

**Step 3: Read Current prd.json**

Read `plans/prd.json` to see:
- What repo is configured
- What tasks already exist (avoid duplicates)
- Current task numbering (T-001, T-002, etc.)

**Step 4: Analyze Each Issue**

For each issue, assess:

1. **Automatable?** Check for manual indicators:
   - Keywords: "create account", "API key", "dashboard", "credentials", "manual", "configure in Vercel/AWS/etc"
   - If found, mark as `suggestSkip: true`

2. **Has acceptance criteria?** Look for:
   - Checkbox lists in body (`- [ ]` items)
   - "Acceptance criteria" section
   - Clear definition of done

3. **Priority** from labels:
   - P0/critical → priority: "high"
   - P1/high → priority: "high"
   - P2/medium → priority: "medium"
   - P3/low → priority: "low"
   - P4/nice-to-have → priority: "low"
   - No label → priority: "medium" (default)

4. **Already in prd.json?** Check if `github_issue` number already exists

**Step 5: Present Options to User**

Use AskUserQuestion to let user select issues. Format each option clearly:

```
#61 - Fix Neon 507 limit (P0, automatable)
#73 - Update guide docs (P4, automatable)
#83 - Langfuse setup (P3, MANUAL - suggest skip)
```

Group by:
- Recommended for automation (clear scope, has AC)
- May need manual steps (suggest skip)
- Already in prd.json (skip)

**Step 6: Generate prd.json Entries**

For each selected issue, generate a feature entry:

```json
{
  "id": "F-00X",
  "title": "[Issue title]",
  "github_issue": [number],
  "acceptance_criteria": [
    // Extract from issue body if available
    // Otherwise generate reasonable defaults
  ],
  "priority": "high|medium|low",
  "passes": false,
  "skip": [true if manual],
  "skipReason": "[reason if skip=true]",
  "notes": "[Brief context from issue body]"
}
```

**Step 7: Update prd.json**

If prd.json exists:
- Merge new features with existing (don't overwrite completed features)
- Update next feature ID number

If prd.json doesn't exist:
- Create new file with standard structure
- Include repo field from `gh repo view --json nameWithOwner`

**Step 8: Summary**

Output:
- How many issues were added
- Any skipped (manual) issues
- Suggest running `/ralph-loop --next --dry-run` to preview

**Example Output:**

```
Added 3 tasks to prd.json:
  F-005: Fix session timeout (#45) - high priority
  F-006: Add export button (#52) - medium priority
  F-007: Update error messages (#58) - low priority

Skipped (manual setup required):
  #83: Langfuse credentials - added with skip=true

Run `/ralph-loop --next --dry-run` to preview the first task.
```
</instruction>
