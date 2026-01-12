# Ralph Guardrails (Signs)

Learned constraints that prevent repeated failures. Each "sign" is a rule discovered through iteration failures. Add new signs as you encounter failure patterns.

> "Progress should persist. Failures should evaporate." - The Ralph philosophy

---

## Verification Signs

### SIGN-001: Verify Before Complete
**Trigger:** About to output completion promise
**Instruction:** ALWAYS run the verification command (`pnpm verify` or equivalent) and confirm it passes before outputting `<promise>COMPLETE</promise>`
**Reason:** Models tend to declare victory without proper verification

### SIGN-002: Check All Tasks Before Complete
**Trigger:** Completing a task in multi-task mode
**Instruction:** Re-read prd.json and count remaining `passes: false` tasks. Only output completion promise when ALL tasks pass, not just the current one.
**Reason:** Premature completion exits loop with work remaining

---

## Progress Signs

### SIGN-003: Document Learnings
**Trigger:** Completing any task
**Instruction:** Update progress.md with what was learned (patterns discovered, files modified, decisions made) before ending iteration
**Reason:** Future iterations need context to avoid re-discovering the same patterns

### SIGN-004: Small Focused Changes
**Trigger:** Making changes per iteration
**Instruction:** Keep changes small and focused. Commit incrementally when tests pass. Don't try to solve everything in one iteration.
**Reason:** Large changes are harder to debug when verification fails

---

## Project-Specific Signs

Add signs below as you encounter project-specific failure patterns:

<!-- Example format:
### SIGN-XXX: [Descriptive Name]
**Trigger:** [When this sign applies]
**Instruction:** [What to do instead]
**Reason:** [Why this matters]
**Added after:** [Iteration N / date when learned]
-->
