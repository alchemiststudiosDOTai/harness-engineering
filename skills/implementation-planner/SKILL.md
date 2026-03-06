---
name: implementation-planner
description: Generate execution-ready implementation plans from research docs - planning ONLY, no fixing or verifying. North Star is whether a JR developer can execute the plan with zero additional context.
writes-to: memory-bank/plan/
allowed-tools:
  - Read
  - Edit
  - Write
  - Bash(git:*)
  - Bash(grep:*)
  - Bash(sed:*)
  - Bash(awk:*)
  - Bash(jq:*)
  - Bash(date:*)
  - Bash(find:*)
hard-guards:
  - NO code modifications during planning
  - NO fixes or verification
  - Focus ONLY on generating clear executable plans
  - Every task must be unambiguous to a JR developer
---

# Implementation Planner

## Overview

Generate execution-ready, coding-only implementation plans from research documents. The goal is to produce plans that **any JR developer can execute immediately with zero ambiguity**.

## North Star Rule

> **If a JR developer picked this up, could they start coding immediately?**
>
> If the answer is "no" or "they'd need to ask clarifying questions," the plan is incomplete.

## When to Use

- User asks to "create a plan from research"
- User references a research doc in `memory-bank/research/`
- User wants "implementation steps" from findings
- User asks to "break down into tasks" a researched topic

## What This Skill Does NOT Do

| ❌ DON'T | ✅ DO INSTEAD |
|---------|--------------|
| Fix code issues | Document them as tasks to fix |
| Verify implementations | Plan verification steps |
| Run tests | Plan what tests to write |
| Deploy anything | Plan deployment as a task |
| Make code changes | Document exactly what changes to make |

## Planning Workflow

### 1. Read Research Doc

```
Read from: memory-bank/research/<topic>.md
Extract: scope, constraints, target files, unresolved questions, proposed solutions
```

### 2. Verify Git Freshness

```bash
# Capture current state
git rev-parse HEAD          # Commit SHA
git status --short          # Working tree status
```

### 3. Generate Plan File

Save as: `memory-bank/plan/YYYY-MM-DD_HH-MM-SS_<topic>.md`

### 4. Plan Structure

```markdown
---
title: "<topic> – Implementation Plan"
phase: Plan
date: "{{timestamp}}"
owner: "{{agent_or_user}}"
parent_research: "memory-bank/research/<file>.md"
git_commit_at_plan: "<short_sha>"
tags: [plan, <topic>, coding]
---

## Goal

- ONE singular coding-focused outcome
- Explicitly state what is OUT of scope (ops, deploy, excessive testing)

## Scope & Assumptions

- IN scope: (technical items only)
- OUT of scope: (what we're NOT doing)
- Assumptions: (frameworks, environments, libraries)

## Deliverables

- Source code modules, functions, or APIs
- Documentation limited to developer-level notes (not user docs)

## Readiness

- Preconditions: repos, libs, data schemas, sample inputs
- What must exist before starting

## Milestones

- M1: Skeleton & architecture setup
- M2: Core logic & data flow
- M3: Feature completion & refinement
- M4: Basic test(s) & integration hooks

## Work Breakdown (Tasks)

For EACH task, specify:
- **Task ID**: T001, T002, etc.
- **Summary**: What to do (present tense, actionable)
- **Owner**: who does it
- **Estimate**: time/complexity
- **Dependencies**: other task IDs
- **Target milestone**: M1-M4
- **Acceptance test**: Exactly ONE test that proves it works
- **Files/modules touched**: List exact paths

## Risks & Mitigations

Keep technical:
- Library stability issues
- API version drift
- Schema mismatch risks
- Breaking changes in dependencies

## Test Strategy

At most ONE new test per task, only for validating main coding work.
Focus on proving correctness, not coverage.

## References

- Research doc sections
- Key code references (file:line format)

## Final Gate

- **Output summary**: plan path, milestone count, tasks ready
- **Next command**: `/use plan-executor "<plan_path>"`
```

## Task Writing Guidelines

### ✅ Good Task

```
T003: Add user authentication middleware
- Create src/middleware/auth.ts with verifyToken() function
- Import in src/app.ts and apply to /api/* routes
- Acceptance: curl /api/users returns 401 without header, 200 with valid token
- Files: src/middleware/auth.ts, src/app.ts
- Milestone: M2
```

### ❌ Bad Task

```
T003: Fix auth
- Handle the auth stuff properly
- Make sure it works
```

### Rules for Tasks

1. **Present tense, actionable**: "Add function X" not "Function X should be added"
2. **File paths explicit**: No "find the right place to put it"
3. **One acceptance test per task**: Single proof of correctness
4. **No hand-waving**: "Implement caching" → "Add Redis caching to src/cache.ts with get/set methods"
5. **Depend on tasks, not people**: "Depends on T001" not "Wait for backend team"

## Git Freshness Check

Always capture and include:

```bash
COMMIT_SHA=$(git rev-parse --short HEAD)
STATUS=$(git status --short)
```

If research doc mentions specific commits/branches and they've changed:
- Mark affected tasks for re-verification
- Note the discrepancy in plan frontmatter

## Issue Opening (When Available)

If planning reveals blockers or prerequisites that need tracking:
- Check for Gitea/GitHub availability
- Open issues ONLY for:
  - External dependencies
  - Prerequisites that aren't in scope
  - Decisions needed before execution
- Link issue IDs to relevant tasks

## Validation Questions

Before finalizing, ask:

1. **Ambiguity check**: Could a JR developer understand every task without questions?
2. **Completeness**: Are all prerequisites and dependencies listed?
3. **Executability**: Does each task specify exact files and acceptance criteria?
4. **Scope creep**: Is ops/deploy work leaking into the plan?

## Output Format

After plan generation, output:

```
✓ Plan written to: memory-bank/plan/YYYY-MM-DD_HH-MM-SS_<topic>.md
✓ Milestones: 4
✓ Tasks: 12
✓ Git state: <short_sha>

Next: /use plan-executor "memory-bank/plan/YYYY-MM-DD_HH-MM-SS_<topic>.md"
```

## Examples

### Example Plan Entry

```markdown
## Task T004: Add rate limiting to API endpoints

**Summary**: Implement token-bucket rate limiting for public API endpoints

**Files**:
- src/middleware/rateLimit.ts (new)
- src/app.ts (modify)

**Changes**:
1. Create src/middleware/rateLimit.ts with TokenBucket class
   - Constructor takes capacity and refillRate
   - consume(tokens) method returns true if allowed
2. Add rateLimit instance to src/app.ts
3. Apply to /api/public/* routes only

**Acceptance Test**:
- Send 100 requests in 1 second to /api/public/data
- First 60 succeed (200)
- Next 40 fail (429)
- Headers include X-RateLimit-Remaining

**Dependencies**: T001 (Express app setup)
**Milestone**: M2
**Estimate**: 2 hours
```

## Subagent Usage (Sparingly)

Only spawn subagents if:
- Research doc is large (>500 lines)
- Need to map tasks to existing codebase structure
- Need parallel analysis of multiple subsystems

Typical subagents:
- `codebase-analyzer`: Find where new code fits
- `context-synthesis`: Extract structured tasks from prose research

Default: Don't use subagents. Trust the research doc.

## Handoff

After writing the plan document to `memory-bank/plan/`, hand off to `plan-executor` if the next step is the Execute phase.

Suggested next command:

```text
/use plan-executor "memory-bank/plan/<file>.md"
```
