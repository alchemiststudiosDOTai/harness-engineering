---
name: plan-executor
description: Execute implementation plans from memory-bank/plan/. Focus on EXECUTING ONLY - no planning, no fixes outside plan scope. Uses gated checks, atomic commits, and maintains a single execution log in memory-bank/execute/. Use when the user says "execute this plan" or provides a plan path.
writes-to: memory-bank/execute/
allowed-tools:
  - Edit
  - Read
  - Write
  - Bash(git:*)
  - Bash(python:*)
  - Bash(pytest:*)
  - Bash(mypy:*)
  - Bash(black:*)
  - Bash(coverage:*)
  - Bash(docker:*)
  - Bash(trivy:*)
  - Bash(hadolint:*)
  - Bash(jq:*)
  - Bash(curl:*)
  - Bash(gh:*)
hard-guards:
  - NO planning - follow the plan exactly
  - NO fixes outside plan scope
  - Create rollback point before starting
  - Keep ONE execution log updated as you work
  - Commit atomic changes per task
---

# Plan Executor

## Overview

Execute implementation plans from `memory-bank/plan/` with strict discipline: gated checks, atomic commits, and a single living execution log.

## North Star Rule

> **Follow the plan exactly. Do not improvise. Do not fix what isn't in the plan.**
>
> If something is ambiguous or missing, stop and ask the user.

## When to Use

- User provides a plan path: `/use plan-executor "memory-bank/plan/<file>.md"`
- User says "execute this plan" or "run the plan"
- User references a plan document for implementation

## What This Skill Does NOT Do

| ❌ DON'T | ✅ DO INSTEAD |
|---------|--------------|
| Re-plan the work | Execute tasks as written |
| Fix unrelated issues | Follow plan scope only |
| Skip quality gates | Run all gates, document failures |
| Ignore the plan | Plan is the source of truth |

## Execute Phase Workflow

### 0. Input

User provides: `$ARGUMENTS` = path to plan in `memory-bank/plan/`

### 1. Read Plan & Lock Context

Read the FULL plan. Extract:
- Milestones
- Task IDs and order
- Acceptance tests
- Quality gates
- Success criteria

### 2. Pre-Flight Snapshot

Before any code changes:

```bash
# Capture git state
BRANCH=$(git branch --show-current)
SHA=$(git rev-parse --short HEAD)
STATUS=$(git status --short)
```

Create rollback point:

```bash
git add -A
git commit -m "rollback: before executing plan <topic>"
```

Create `memory-bank/execute/YYYY-MM-DD_HH-MM-SS_<topic>.md`:

```markdown
---
title: "<topic> – Execution Log"
phase: Execute
date: "{{timestamp}}"
owner: "{{user}}"
plan_path: "memory-bank/plan/<file>.md"
start_commit: "<short_sha>"
env: {target: "local|staging|prod", notes: ""}
---

## Pre-Flight Checks
- Branch: <branch>
- Rollback commit: <sha>
- DoR satisfied: yes/no
- Access/secrets: present/missing
- Fixtures/data: ready/not ready

[If any NO → abort and add Blockers section]
```

### 3. Task-by-Task Execution

For EACH task in plan order:

```
1. Read task requirements
2. Implement minimal slice aligned with acceptance test
3. Run local validation
4. Commit atomic change with Task ID in message
5. Update execution log
```

**Commit message format:**

```
T<NNN>: <task summary>

<brief description of change>

Refs: plan/<file>.md
```

### 4. Quality Gates

Run gates in order. Document ALL results.

#### Gate C - Code Quality

```bash
# Run tests
pytest

# Type check
mypy src/

# Lint
black --check src/

# Coverage
coverage report
```

Document in the execution log:
```
### Gate Results
- Tests: pass/fail + evidence
- Coverage: X% (target Y%)
- Type checks: pass/fail
- Linters: pass/fail
```

**If gate FAILS:**
- Record failure + remediation attempted
- STOP and ask user for next steps
- Do NOT roll back without user confirmation

### 5. Permalinks & Artifacts

If commits pushed:

```bash
# Get repo info for permalinks
gh repo view --json owner,name
```

Attach permalinks to:
- PRs/commits
- Build logs
- Coverage reports
- Security scans

Persist artifact pointers in the execution log.

### 6. Post-Deploy Verification (if applicable)

```
### Post-Deploy Verification
- Error rates: <metrics>
- Latencies: <metrics>
- Dashboard links: <URLs>
- Smoke/E2E results: <pass/fail>
```

## Execution Log Template

**Keep ONE document. Update as you work.**

```markdown
---
title: "<topic> – Execution Log"
phase: Execute
date: "{{timestamp}}"
plan_path: "memory-bank/plan/<file>.md"
start_commit: "<sha>"
end_commit: "<sha>"
env: {target: "...", notes: "..."}
---

## Pre-Flight Checks
- Branch: <branch>
- Rollback: <commit_sha>
- DoR: satisfied/not
- Ready: yes/no

## Task Execution

### T001 – <Summary>
- Status: completed/skipped/failed
- Commit: <sha>
- Files: <list>
- Commands: <cmd> → <output>
- Tests: pass/fail
- Coverage delta: +X%
- Notes: <decisions made>

### T002 – <Summary>
[... repeat for each task ...]

## Gate Results
- Tests: X/Y passed
- Coverage: X% (target Y%)
- Type checks: pass/fail
- Security: # issues
- Linters: pass/fail

## Deployment (if applicable)
- Staging: success/fail
- Prod: success/fail
- Timestamps: <start> → <end>

## Issues & Resolutions
- T<NNN> – <issue> → <resolution|rollback|asked user>

## Success Criteria
- [ ] All planned gates passed
- [ ] Rollout completed or rolled back
- [ ] KPIs/SLOs within thresholds
- [ ] Execution log saved

## Next Steps
- Follow-ups, tech debt, docs
```

## Final Report

After the Execute phase, summarize:

```markdown
# Execution Report – <topic>

**Date:** {{date}}
**Plan:** <plan_file>
**Log:** <log_file>

## Overview
- Environment: <env>
- Start: <sha>
- End: <sha>
- Duration: Xh Ym
- Branch: <branch>

## Outcomes
- Tasks attempted: N
- Tasks completed: N
- Final status: Success | Failure | Blocked

## Gate Results
- Tests: pass/fail
- Coverage: X% (target Y%)
- Type checks: pass/fail
- Security: # issues

## What Was Touched
[List all files modified]

## Next Steps
- [ ] Item 1
- [ ] Item 2
```

## Strict Rules

1. **ONE execution log** - Create once, update as you work. Do not create multiple docs.
2. **Atomic commits** - One commit per task. Task ID in commit message.
3. **Rollback first** - Create rollback commit before any code changes.
4. **Gates are mandatory** - Run all gates. Document failures. Stop on failure.
5. **Plan is source of truth** - Do not add, remove, or change tasks.
6. **Ask when blocked** - If gates fail or plan is ambiguous, stop and ask.

## Validation Questions

Before proceeding with each task:

1. **Clarity**: Do I understand exactly what this task requires?
2. **Scope**: Is this within the plan's scope?
3. **Dependencies**: Are prerequisite tasks completed?
4. **Rollback**: Can I revert to the safe state?

## Output Format

Start:

```
Executing plan: memory-bank/plan/<file>.md
Branch: <branch>
Rollback point: <commit_sha>
Tasks: N
Milestones: M
```

End:

```
Execution complete: Success | Failure | Blocked
Tasks completed: N/N
Log: memory-bank/execute/<file>.md
Next: /use qa-from-execute "memory-bank/execute/<file>.md"
```

## Handoff

After writing the execution log to `memory-bank/execute/`, hand off to `qa-from-execute` if the next step is the QA phase.

Suggested next command:

```text
/use qa-from-execute "memory-bank/execute/<file>.md"
```
