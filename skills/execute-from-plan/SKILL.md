---
name: execute-from-plan
description: Execute implementation plans from memory-bank/plan/. STRICTLY execution only—NO research, NO planning, NO deviation from plan without confirmation. Trust that planning-from-research has already prepared the work. Output is working code with execution logs.
allowed-tools: Read Write Edit Bash Agent
---

# Execute From Plan

Execute tasks from a prepared implementation plan. This skill walks the plan milestone by milestone, task by task, producing working code.

## CRITICAL BOUNDARIES

| Activity | Status |
|----------|--------|
| **Execution** | ✅ This skill |
| **Planning** | ❌ Use planning-from-research first |
| **Research** | ❌ Use codebase-research first |

**This skill is STRICTLY for execution.** Do not plan, do not research, do not question the plan. Trust that preparation work is complete. Execute what is written.

## When to Use

Use this skill when:
- A plan document exists in `memory-bank/plan/`
- The task is to implement/build what the plan specifies
- Planning and research phases are already complete

## Workflow

### Step 1: Load Plan

Locate and read the plan document:

- If a path is provided: Read from `memory-bank/plan/<path>`
- If a topic is provided: Find the latest matching file in `memory-bank/plan/`

Extract:
- Goal and non-goals
- Milestones (M1-M5) and their tasks
- Acceptance criteria for each task
- Files and interfaces to modify
- Assumptions and constraints

### Step 2: Check for Drift

Compare current git state to the plan's recorded state:

```bash
git rev-parse --short HEAD 2>/dev/null || echo "not-a-repo"
```

If current HEAD differs from `git_commit_at_plan`:
- Warn: "DRIFT DETECTED — code changed since plan was created"
- Review the plan's "Drift Notes" section
- If significant drift: Ask user before proceeding
- If minor: Proceed with caution, document deviations

### Step 3: Execute Tasks in Order

**Execute strictly in milestone order: M1 → M2 → M3 → M4 → M5**

Within each milestone, execute tasks by ID order (T1, T2, T3...).

For each task:

1. **Read task details**
   - Task description (what to implement)
   - Files/interfaces to touch
   - Dependencies (must be complete first)
   - Acceptance criteria

2. **Verify dependencies**
   - Confirm all dependent tasks are marked complete
   - If not: Stop, report blocking dependency

3. **Execute the task**
   - Implement exactly what the task specifies
   - Touch only the files/interfaces listed
   - Do not add features beyond the task scope

4. **Run acceptance verification**
   - Verify against task acceptance criteria
   - Run any tests specified in the plan
   - If criteria fail: Fix or stop and report

5. **Update plan document**
   - Mark task as complete
   - Add execution notes (what was done, any issues)
   - Record actual time taken (optional)

6. **Commit (optional)**
   - Consider committing after each milestone
   - Use milestone ID in commit message: "M1: Architecture & skeleton"

### Step 4: Handle Blocks

If blocked during execution:

1. **Document the block**
   - What was being attempted
   - What went wrong
   - What was tried

2. **Update plan document**
   - Mark task status as "BLOCKED"
   - Add notes describing the block

3. **Ask user for guidance**
   - Present the documented block
   - Request decision: fix, skip, or replan

**Never deviate from the plan without explicit user confirmation.**

### Step 5: Complete or Report

**If all tasks complete:**
- Mark plan phase as "EXECUTED"
- Create execution log: `memory-bank/execution/YYYY-MM-DD_HH-MM-SS_<topic>.md`
- Output summary: tasks completed, files modified, tests passing

**If blocked and cannot proceed:**
- Report incomplete tasks
- Describe blocking issue
- Suggest next steps (replan, research, user intervention)

## Task Execution Rules

| Rule | Description |
|------|-------------|
| **Trust the plan** | Do not second-guess or research alternatives |
| **Stay in scope** | Implement exactly what the task specifies |
| **Verify after each** | Run acceptance criteria before marking complete |
| **Update the plan** | Document progress and notes in the plan file |
| **Stop on failure** | Do not proceed past failed acceptance criteria |
| **Ask on deviation** | Get user confirmation before changing the plan |

## Subagent Usage

If execution assistance is needed:

**With subagents available:** Deploy maximum 3:

| Subagent | When to Deploy |
|----------|----------------|
| lint-issue-resolver | Fix lint/type errors introduced during implementation |
| antipattern-sniffer | Review code for anti-patterns after significant changes |
| codebase-analyzer | Understand existing code patterns before modifying |

**Without subagents:** Execute manually following the plan's task descriptions.

## Execution Log Format

Create `memory-bank/execution/YYYY-MM-DD_HH-MM-SS_<topic>.md`:

```yaml
---
title: "<topic> – Execution"
phase: Execution
date: "YYYY-MM-DD HH:MM:SS"
owner: "<agent_or_user>"
parent_plan: "memory-bank/plan/<file>.md"
git_commit_at_start: "<sha>"
git_commit_at_end: "<sha>"
tags: [execution, <topic>]
---

## Summary

| Metric | Value |
|--------|-------|
| Milestones completed | N/N |
| Tasks completed | N/N |
| Tasks blocked | N |
| Files modified | N |
| Tests added | N |
| Execution time | HH:MM |

## Milestones

### M1: Architecture & Skeleton

| Task | Status | Notes |
|------|--------|-------|
| M1.T1 | ✅ Complete | [Notes] |
| M1.T2 | ✅ Complete | [Notes] |
| M1.T3 | ❌ Blocked | [Block description] |

### M2: Core Feature(s)

| Task | Status | Notes |
|------|--------|-------|
| M2.T1 | ⏸️ Skipped | [Reason] |

[...]

## Files Modified

- `path/to/file.py` – [what changed]
- `path/to/file.py` – [what changed]

## Issues Encountered

| Task | Issue | Resolution |
|------|-------|------------|
| M1.T2 | [Description] | [How resolved] |

## Drift from Plan

_If execution deviated from plan, document here:_
- Planned: [X]
- Actual: [Y]
- Reason: [Z]
```

## Constraints

| Constraint | Rule |
|------------|------|
| **NO PLANNING** | Never create new plans or modify existing plan structure |
| **NO RESEARCH** | Never investigate beyond what the plan specifies |
| **Strict ordering** | M1 before M2, T1 before T2 |
| **Verify before proceeding** | Acceptance criteria must pass |
| **Document everything** | Update plan and create execution log |
| **Stop on block** | Do not guess or work around blocks |
