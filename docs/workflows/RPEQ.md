# Harness Engineering

Claude Code skills for the **context-engineer** workflow: a structured approach to complex software engineering tasks through research, planning, execution, and quality assurance.

## Overview

This repository contains a 4-phase workflow designed to break down complex development work into manageable, trackable phases. Each phase has a dedicated skill with strict boundaries to maintain focus and quality.

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│    Research     │───→│     Plan         │───→│    Execute      │───→│      QA         │
│                 │    │                  │    │                 │    │                 │
│  Map codebase   │    │  Create plan     │    │  Implement      │    │  Evaluate       │
│  Find patterns  │    │  Define tasks    │    │  milestone by   │    │  changed code   │
│  Document what  │    │  Set acceptance  │    │  milestone      │    │  Report risks   │
│  exists         │    │  criteria        │    │                 │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘    └─────────────────┘
  codebase-research     planning-from-research   execute-from-plan     qa-from-execution
```

## The Skills

### 1. [codebase-research](./skills/SKILL.md)

**Purpose:** Map the codebase structure, patterns, and architecture.

**When to use:** Before planning any significant work. Understand what exists before deciding what to build.

**Output:** Research document in `memory-bank/research/` with:

- Directory structure and file purposes
- Key symbols and their locations
- Dependency relationships
- Pattern locations

**Key constraint:** Map only—no suggestions, no recommendations, no opinions.

### 2. [planning-from-research](./skills/planning-from-research/SKILL.md)

**Purpose:** Transform research into an executable implementation plan.

**When to use:** After research is complete. Create a plan that a junior developer can execute without asking questions.

**Output:** Plan document in `memory-bank/plan/` with:

- Singular goal and non-goals
- Milestones (M1-M5): Architecture → Core Features → Tests → Packaging → Observability
- Granular work breakdown with acceptance criteria
- Risk assessment and mitigations

**Key constraint:** Planning only—no coding, no execution. Validate research completeness before planning.

### 3. [execute-from-plan](./skills/execute-from-plan/SKILL.md)

**Purpose:** Execute the plan milestone by milestone, task by task.

**When to use:** When a plan exists and implementation needs to happen.

**Output:** Working code + execution log in `memory-bank/execution/` with:

- Completed tasks with notes
- Files modified
- Issues encountered
- Drift from plan (if any)

**Key constraint:** Execution only—no planning, no research. Trust the plan. Stop and ask if blocked.

### 4. [qa-from-execution](./skills/qa-from-execution/SKILL.md)

**Purpose:** Evaluate implemented code for correctness, risks, and quality.

**When to use:** After execution is complete. Pre-merge or post-implementation review.

**Output:** QA report in `memory-bank/QA/` with:

- Findings categorized by severity (CRITICAL, WARNING, INFO, PASS)
- Test coverage analysis
- Contract/API verification
- Risk assessment

**Key constraint:** Read-only analysis—no code changes, no fixes. Report only.

## Directory Structure

```
skills/
├── SKILL.md                    # codebase-research skill
├── planning-from-research/
│   └── SKILL.md                # planning skill
├── execute-from-plan/
│   └── SKILL.md                # execution skill
├── qa-from-execution/
│   └── SKILL.md                # QA skill
└── scripts/                    # Helper scripts for research
    ├── ast-scan.sh             # Structural pattern scanner (ast-grep)
    ├── structure-map.sh        # Directory tree generator
    ├── symbol-index.sh         # Public symbol extractor
    └── dependency-graph.sh     # Import tracer
```

## Installation

Ask Claude to install the skills from this repository:

```
Install skills from https://github.com/alchemiststudiosDOTai/harness-engineering
```

Or run this command in your terminal:

```bash
git clone https://github.com/alchemiststudiosDOTai/harness-engineering.git ~/.claude/skills/harness-engineering
```

Then restart Claude Code or run `/refresh` to load the skills.

## Usage

Once installed, Claude will automatically detect and use these skills based on your requests. You can also reference them explicitly:

### Option 1: Let Claude detect the right skill

Simply describe what phase you're in:

- "I need to understand this codebase" → triggers codebase-research
- "Create a plan for implementing X" → triggers planning-from-research
- "Execute this plan" → triggers execute-from-plan
- "Review the changes I made" → triggers qa-from-execution

### Option 2: Reference skills directly

```
/claude use harness-engineering/skills/codebase-research
/claude use harness-engineering/skills/planning-from-research
/claude use harness-engineering/skills/execute-from-plan
/claude use harness-engineering/skills/qa-from-execution
```

### Option 3: Read skill files manually

```
@~/.claude/skills/harness-engineering/skills/SKILL.md
@~/.claude/skills/harness-engineering/skills/planning-from-research/SKILL.md
```

## Workflow Data Flow

```
memory-bank/
├── research/
│   └── YYYY-MM-DD_topic.md      # Created by codebase-research
├── plan/
│   └── YYYY-MM-DD_topic.md      # Created by planning-from-research
│                                 # References parent research
├── execution/
│   └── YYYY-MM-DD_topic.md      # Created by execute-from-plan
│                                 # References parent plan
└── QA/
    └── YYYY-MM-DD_topic_qa.md   # Created by qa-from-execution
                                  # References parent execution
```

## Key Principles

1. **Strict phase boundaries** — Each skill has a narrow focus. No skill does another skill's work.
2. **Documentation as artifacts** — Each phase produces a document that feeds the next phase.
3. **Traceability** — Each document links to its parent (research → plan → execution → QA).
4. **Reversibility** — Clear acceptance criteria at each phase allow go/no-go decisions.
5. **Subagent-aware** — Skills specify how to work with or without subagent availability.

## License

MIT
