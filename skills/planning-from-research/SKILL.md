---
name: planning-from-research
description: Generate execution-ready implementation plans from research documents. STRICTLY planning only—NO execution, NO coding. Validate research completeness first; if vague, resolve via subagents or user confirmation. Output is a standalone plan that a junior developer can execute without additional documentation.
allowed-tools: Read Write Bash Agent
---

# Planning From Research

Transform a research document into a concrete, executable implementation plan.

## CRITICAL BOUNDARIES

| Activity | Status |
|----------|--------|
| **Planning** | ✅ This skill |
| **Research** | ❌ Use codebase-research skill first |
| **Execution/Coding** | ❌ NEVER in this skill |

**This skill is STRICTLY for planning.** Do not write code, do not implement, do not execute tasks. Produce a document that someone else (or a future session) can execute from.

## Purpose

Convert the structural understanding from codebase-research into an actionable work plan. This skill bridges the gap between "what exists" (research) and "what to build" (execution).

## When to Use

Use this skill when:
- A research document exists in `memory-bank/research/`
- The goal is to create an implementation plan for development work
- The output must be clear enough for a junior developer to execute independently

## Workflow

### Step 1: Load Research Document

Locate and read the full research document:

- If a path is provided: Read from `memory-bank/research/<path>`
- If a topic is provided: Find the latest matching file in `memory-bank/research/`

Extract:
- Scope and constraints
- Key files and their purposes
- Identified patterns and dependencies
- Any questions or TODOs noted during research

### Step 2: Validate Completeness

**CRITICAL**: Verify the research document contains no blocking vagueness before planning.

Check for these red flags:

| Flag | Example | Action Required |
|------|---------|-----------------|
| Open questions | "Should we use X or Y?" | Must be resolved |
| Uncertainty markers | "maybe", "perhaps", "consider" | Must be converted to decisions |
| Incomplete items | "TODO", "FIXME", "investigate" | Must be completed or deferred |
| Competing approaches | Multiple options without selection | Must choose ONE |
| Missing scope boundaries | Unclear what is in/out of scope | Must be defined |
| Absent acceptance criteria | No definition of "done" | Must be specified |

#### If Blocking Issues Found

**Option A: Deploy Subagents (if available)**

Deploy up to 3 subagents in parallel to resolve open questions:

1. **context-synthesis**: Analyze open questions; determine which block planning
2. **codebase-analyzer**: Investigate technical unknowns; provide concrete recommendations
3. **codebase-locator**: Find pattern examples; show how similar problems were solved

**Option B: Confirm with User (if subagents unavailable)**

Present open questions to the user and request explicit answers before proceeding.

**Option C: Follow Workflow in Order**

If neither subagents nor user confirmation is viable, document the open questions as **assumptions** in the plan with clear **risk flags**, then proceed. The plan must note: "These items were unresolved at planning time and may require re-planning."

**DO NOT proceed to Step 3 until blocking questions are resolved, documented as assumptions, or explicitly deferred.**

### Step 3: Check for Drift

Capture current repository state:

```bash
git rev-parse --short HEAD 2>/dev/null || echo "not-a-repo"
git status --porcelain 2>/dev/null || echo "clean"
```

If code changed significantly since research:
- Add a "Drift Note" to the plan
- Mark affected assumptions/tasks for re-verification

### Step 4: Generate Plan

Create `memory-bank/plan/YYYY-MM-DD_HH-MM-SS_<topic>.md` with this structure:

```yaml
---
title: "<topic> – Plan"
phase: Plan
date: "YYYY-MM-DD HH:MM:SS"
owner: "<agent_or_user>"
parent_research: "memory-bank/research/<file>.md"
git_commit_at_plan: "<sha_or_not-a-repo>"
tags: [plan, <topic>]
---

## Goal

**Singular Focus**: One crisp sentence describing the exact outcome.

Non-goals (explicitly excluded):
- [Non-goal 1]
- [Non-goal 2]

## Scope & Assumptions

### In Scope
- [Specific bounded item 1]
- [Specific bounded item 2]

### Out of Scope
- [Item that appears related but is excluded]

### Assumptions
- [Assumption 1]: [Justification]
- [Assumption 2]: [Justification]

### Constraints
- [Technical/business constraint 1]
- [Technical/business constraint 2]

## Deliverables (Definition of Done)

| # | Deliverable | Acceptance Criteria | How to Verify |
|---|-------------|---------------------|---------------|
| 1 | [Artifact name] | [Specific testable criteria] | [Method] |
| 2 | [Artifact name] | [Specific testable criteria] | [Method] |

## Readiness (Definition of Ready)

Checklist of preconditions before work can begin:

- [ ] [Data/access/environment requirement]
- [ ] [Test data/fixtures ready]
- [ ] [Dependencies installed/available]
- [ ] [Stakeholder approval on approach]

## Milestones

| ID | Description | Success Criteria | Target |
|----|-------------|------------------|--------|
| M1 | Architecture & skeleton | [Criteria] | T+0 |
| M2 | Core feature(s) | [Criteria] | T+[N] |
| M3 | Tests & hardening | [Criteria] | T+[N+M] |
| M4 | Packaging & deploy | [Criteria] | T+[N+M+P] |
| M5 | Observability & docs | [Criteria] | T+[N+M+P+Q] |

## Work Breakdown

**Execute in strict order.**

### M1: Architecture & Skeleton

| ID | Task | Estimate | Dependencies | Files/Interfaces |
|----|------|----------|--------------|------------------|
| M1.T1 | [Specific action: what to do, not how] | [time] | - | `[path]` |
| | **Acceptance:** [Specific verification] | | | |
| M1.T2 | [Specific action] | [time] | M1.T1 | `[path]` |
| | **Acceptance:** [Specific verification] | | | |

### M2: Core Feature(s)

| ID | Task | Estimate | Dependencies | Files/Interfaces |
|----|------|----------|--------------|------------------|
| M2.T1 | [Specific action] | [time] | M1 complete | `[path]` |
| | **Acceptance:** [Specific verification] | | | |

### M3: Tests & Hardening

| ID | Task | Estimate | Dependencies | Files/Interfaces |
|----|------|----------|--------------|------------------|
| M3.T1 | [Specific action] | [time] | M2 complete | `[path]` |
| | **Acceptance:** [Specific verification] | | | |

### M4: Packaging & Deploy

| ID | Task | Estimate | Dependencies | Files/Interfaces |
|----|------|----------|--------------|------------------|
| M4.T1 | [Specific action] | [time] | M3 complete | `[path]` |
| | **Acceptance:** [Specific verification] | | | |

### M5: Observability & Docs

| ID | Task | Estimate | Dependencies | Files/Interfaces |
|----|------|----------|--------------|------------------|
| M5.T1 | [Specific action] | [time] | M4 complete | `[path]` |
| | **Acceptance:** [Specific verification] | | | |

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation | Trigger |
|------|--------|------------|------------|---------|
| [Description] | H/M/L | H/M/L | [Prevention/reduction] | [Escalation point] |

## Test Strategy

**Maximum one test file per milestone.** Additional tests are out of scope.

| Milestone | Approach | Test File(s) |
|-----------|----------|--------------|
| M1 | [Unit/integration] | `[path]` |
| M2 | [Approach] | `[path]` |
| M3 | [Approach] | `[path]` |

## Alternative Approach (Optional)

Include ONLY if a significant decision has a viable alternative:

| Decision | Selected | Alternative | Rationale |
|----------|----------|-------------|-----------|
| [Area] | [Choice] | [Other option] | [Why selected/rejected] |

Default: no alternatives—maintain singular focus on execution.

## References

- Research document: `memory-bank/research/<file>.md`
- Key code locations: `[file:line]`
- External documentation: `[links]`
- Related tickets/PRs: `[refs]`

## Drift Notes

_If repository state changed since research:_
- Modified files: `[list]`
- Re-verification needed: `[items]`
```

### Step 5: Final Summary

Output completion summary:

```
✅ Plan Created: memory-bank/plan/YYYY-MM-DD_HH-MM-SS_<topic>.md

Summary:
- Milestones: [N]
- Total Tasks: [N]
- Critical Gates: [list]
- Estimated Duration: [total]

Next: Begin execution with M1 tasks
```

## Constraints

| Constraint | Rule |
|------------|------|
| **NO EXECUTION** | Never write, modify, or execute code |
| **NO CODING** | Never implement, prototype, or test solutions |
| **NO NEW RESEARCH** | Only use existing research document; do not investigate unless resolving blocking questions |
| Singular focus | One primary plan; maximum one alternative |
| Granular tasks | Each task: 30 minutes to 4 hours of work |
| Ordered execution | Tasks must be completable in sequence |
| Junior-ready | Clear enough to execute without questions |
| Test limit | Maximum one test file per milestone |

## Subagent Usage

If additional analysis is needed during planning:

**With subagents available:** Deploy maximum 3 in parallel:

| Subagent | When to Deploy |
|----------|----------------|
| context-synthesis | Identify hidden dependencies or integration points |
| codebase-analyzer | Understand implementation patterns at specific locations |
| codebase-locator | Find examples of how similar problems were solved |

**Without subagents:** Follow the workflow in order manually:
1. Read research document completely
2. Identify and list all open questions
3. If critical: ask user for clarification
4. If deferrable: document as assumptions with risk flags
5. Proceed to generate the plan
