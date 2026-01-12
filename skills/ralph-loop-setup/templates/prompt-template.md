# Ralph Agent Instructions

## Your Task

1. Read `plans/prd.json` for current tasks
2. Read `plans/progress.txt` for context and patterns
3. Pick highest priority task where `passes: false`
4. Implement that ONE task
5. Run verification command (e.g., `pnpm verify`)
6. Commit if passing: `feat: [task-id] - description`
7. Update prd.json: `passes: true`
8. Append learnings to progress.txt

## Stop Condition

If ALL tasks pass, output:

```
<promise>COMPLETE</promise>
```

Otherwise, end normally and the loop will continue.

## Guidelines

- Make incremental progress each iteration
- Focus on one task at a time
- Document learnings and patterns discovered
- Commit working changes frequently
- Don't output the completion promise until verification passes
