---
name: qa-from-execute
description: Perform quality assurance on code changes after the implementation-planner -> plan-executor workflow. STRICTLY QA only—no coding, no fixes, no source-code changes. Focus on changed areas only, emphasizing control/data flow correctness.
writes-to: memory-bank/qa/
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
hard-guards:
  - QA only - no coding or source-code changes
  - Write QA output to memory-bank/qa/
  - Review only the scope captured in memory-bank/execute/
---

# QA From Execute

Evaluate code changes for correctness, risks, and quality. This skill performs read-only analysis of implemented work, producing a QA report without modifying code.

## CRITICAL BOUNDARIES

| Activity | Status |
|----------|--------|
| **QA Analysis** | ✅ This skill |
| **Code Changes** | ❌ NO — Read only |
| **Bug Fixes** | ❌ NO — Report only |
| **Execute** | ❌ NO — Analysis only |

**This skill is STRICTLY for QA evaluation.** Do not write code, do not fix issues, and do not perform the Execute phase. Analyze, evaluate, and report.

## When to Use

Use this skill when:
- The Execute phase is complete
- Code has been written and needs quality evaluation
- The task is to assess correctness of changes, not modify them
- Pre-merge or post-implementation review is needed

## Workflow

### Step 1: Load Execute Context

Locate and read the execution log:

- If a path is provided: Read from `memory-bank/execute/<path>`
- If a topic is provided: Find the latest matching file in `memory-bank/execute/`

Extract:
- Which files were modified
- Which functions/endpoints were added or changed
- What the acceptance criteria were
- Any issues encountered during the Execute phase

### Step 2: Identify Changed Areas

From the execution log, build a list of:

- **Files modified**: Paths to all changed files
- **Functions changed**: Public functions that were added or modified
- **Interfaces changed**: API endpoints, CLI commands, public methods
- **State changes**: Database schema, configuration, shared resources

**Focus analysis ONLY on these changed areas.** Do not review unchanged code.

### Step 3: Apply QA Checklist Per Changed Area

For each changed file/function/endpoint, evaluate:

#### 3.1 Inputs & Preconditions

| Check | Question |
|-------|----------|
| Validation | Are all inputs validated before use? |
| Type safety | Are type assumptions explicit and checked? |
| Null/empty | Are null, undefined, and empty cases handled? |
| Boundaries | Are min/max values, sizes, and limits enforced? |

#### 3.2 Control Flow

| Check | Question |
|-------|----------|
| Branch coverage | Are all branches reachable? Any dead code? |
| Fall-through | Are switch/case fall-throughs intentional? |
| Early returns | Are guard clauses used appropriately? |
| Loop termination | Do all loops have guaranteed termination? |

#### 3.3 Data Flow

| Check | Question |
|-------|----------|
| Invariants | Are invariants preserved through transformations? |
| Mutation scope | Is mutation limited to appropriate scope? |
| Shared state | Is shared state access properly synchronized? |
| Aliasing | Are aliasing risks (multiple refs to same data) handled? |

#### 3.4 State & Transactions

| Check | Question |
|-------|----------|
| Idempotency | Is the operation safe to retry? |
| Atomicity | Are multi-step operations atomic? |
| Rollback | Is there a path to undo partial changes? |
| Concurrency | Are race conditions handled? |

#### 3.5 Error Handling

| Check | Question |
|-------|----------|
| Specificity | Are exceptions specific (not broad catches)? |
| Retry logic | Is transient failure handled with backoff? |
| Dead letter | Are unprocessable items routed to DLQ/log? |
| Error context | Do errors include sufficient debugging info? |

#### 3.6 Contracts

| Check | Question |
|-------|----------|
| Pre-conditions | Are pre-conditions documented and enforced? |
| Post-conditions | Are post-conditions guaranteed on success? |
| Schema drift | Do request/response schemas match implementation? |
| Versioning | Are breaking changes properly versioned? |

#### 3.7 Time & Locale

| Check | Question |
|-------|----------|
| Timezones | Are datetime operations timezone-aware? |
| Monotonic time | Is elapsed time measured with monotonic clocks? |
| DST | Are daylight saving time transitions handled? |
| Format stability | Are date/time formats consistent and unambiguous? |

#### 3.8 Resource Hygiene

| Check | Question |
|-------|----------|
| File lifecycle | Are files opened/closed properly (with statements)? |
| Connection pooling | Are connections returned to pools? |
| Timeouts | Do all blocking operations have timeouts? |
| Cancellation | Is cancellation propagated through async chains? |

#### 3.9 Edge Cases

| Check | Question |
|-------|----------|
| Empty inputs | Is empty/null input handled gracefully? |
| Max sizes | Are large inputs bounded (pagination, limits)? |
| Partial failure | Is partial failure detectable and recoverable? |
| Resource exhaustion | Are OOM, disk full, quota exceeded handled? |

#### 3.10 Public Surface

| Check | Question |
|-------|----------|
| Backward compat | Are breaking changes intentional and documented? |
| OpenAPI alignment | Do implementations match OpenAPI/JSON schemas? |
| Type exports | Are public types exported and documented? |
| Deprecation | Are deprecated items marked and alternatives provided? |

### Step 4: Test & Contracts Analysis

For each changed public function/endpoint:

1. **Map to test coverage**
   - Run: `pytest -q` or equivalent
   - Run: `coverage run -m pytest && coverage report --format=markdown`
   - Identify which changed functions have tests

2. **Identify missing test cases**
   - Error branches: Are failure paths tested?
   - Boundary conditions: Are min/max values tested?
   - Property invariants: Are data guarantees verified?
   - Mutation tests: Would incorrect code fail tests?

3. **Contract/API verification**
   - Compare OpenAPI/JSON schema to implementation
   - Verify request/response DTOs match spec
   - Check for breaking field/enum changes

### Step 5: Secondary Scans (Optional)

Run static analysis tools (read-only, report results):

```bash
# Type checking
mypy . --ignore-missing-imports 2>/dev/null || echo "mypy not available"

# Security scan
bandit -r . -q 2>/dev/null || echo "bandit not available"

# Dependency audit
pip-audit 2>/dev/null || npm audit --json 2>/dev/null | jq '.metadata' || echo "audit not available"
```

Note findings without attempting fixes.

### Step 6: Write QA Report

Create `memory-bank/qa/YYYY-MM-DD_HH-MM-SS_<topic>_qa.md`:

```yaml
---
title: "<topic> – QA Report"
phase: QA
date: "YYYY-MM-DD HH:MM:SS"
owner: "<agent_or_user>"
parent_execute: "memory-bank/execute/<file>.md"
git_commit_at_qa: "<sha>"
tags: [qa, <topic>]
---

## Summary

| Metric | Count |
|--------|-------|
| Files reviewed | N |
| Functions reviewed | N |
| CRITICAL findings | N |
| WARNING findings | N |
| INFO findings | N |
| PASS (no issues) | N |

## Changed Areas Reviewed

### File: `path/to/file.py`

| Function/Class | Lines | Status |
|----------------|-------|--------|
| `function_name()` | L45-89 | ⚠️ WARNING |
| `ClassName` | L120-200 | ✅ PASS |

#### Findings for `function_name()`

| Severity | Category | Finding | Recommendation |
|----------|----------|---------|----------------|
| WARNING | Error Handling | Broad `except Exception` catch | Catch specific exceptions |
| INFO | Data Flow | Mutation of input parameter | Document or avoid |

### File: `path/to/another.js`

...

## Test Coverage Analysis

| Function | Has Tests | Coverage % | Missing Cases |
|----------|-----------|------------|---------------|
| `function_name()` | ✅ | 85% | Error branch, empty input |
| `another_function()` | ❌ | 0% | All cases |

## Contract/API Verification

| Endpoint | Schema Match | Breaking Changes |
|----------|--------------|------------------|
| `POST /api/items` | ✅ | None |
| `GET /api/items/:id` | ⚠️ | New required field |

## Static Analysis Summary

| Tool | Result |
|------|--------|
| mypy | N errors, M warnings |
| bandit | N low, M medium issues |
| pip-audit | N vulnerabilities |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation Status |
|------|------------|--------|-------------------|
| Race condition in shared state | Medium | High | Not mitigated |
| Missing error branch coverage | High | Medium | Not tested |

## Recommendations Summary

### Must Fix (CRITICAL)
1. [Description of critical issue]

### Should Fix (WARNING)
1. [Description of warning]

### Observations (INFO)
1. [Description of observation]
```

## Finding Severity Levels

| Level | Definition | Action Required |
|-------|------------|-----------------|
| **CRITICAL** | Security risk, data loss, or system instability | Must fix before merge |
| **WARNING** | Potential bugs, maintainability issues, missing coverage | Should fix, can defer |
| **INFO** | Style observations, suggestions, notes | Optional |
| **PASS** | No issues found | None |

## Constraints

| Constraint | Rule |
|------------|------|
| **NO CODE CHANGES** | Never write, modify, or delete code |
| **NO FIXES** | Report issues, do not implement solutions |
| **FOCUS ON CHANGES** | Only review files listed in the execution log |
| **READ-ONLY TOOLS** | Use tools that don't modify state |
| **DOCUMENT FINDINGS** | Every issue must be in the QA report |

## Subagent Usage

If additional analysis is needed:

**With subagents available:** Deploy maximum 3:

| Subagent | When to Deploy |
|----------|----------------|
| antipattern-sniffer | Review changed code for anti-patterns and code smells |
| codebase-analyzer | Deep analysis of specific function implementations |
| context-synthesis | Identify hidden dependencies affected by changes |

**Without subagents:** Perform manual analysis following the checklist.

## Handoff

After writing the QA report to `memory-bank/qa/`, hand off to the user for disposition.

Suggested next action:

```text
Review memory-bank/qa/<file>.md and decide whether to accept the work or create follow-up planning.
```
