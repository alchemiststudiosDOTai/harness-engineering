# Harness Engineering

This repository is an **active attempt to formalize and implement Harness Engineering**—a mechanical, repo-enforced framework for making large (often agent-driven) code changes safe, reviewable, and incremental.

Inspired by [OpenAI's work on Harness Engineering](https://openai.com/index/harness-engineering/), this project provides the scaffolding, tooling, and conventions necessary for humans to steer while agents execute.

---

## What is Harness Engineering?

Harness Engineering is a set of constraints and feedback loops that enable high-throughput agent-driven development without architectural decay. It treats the repository as a **system of record** for everything agents need to know.

Key insight from OpenAI's experience:
> "What Codex can't see doesn't exist."

Knowledge in Slack threads, Google Docs, or engineers' heads is illegible to agents. The solution: encode everything—architecture, taste, quality standards—into mechanical, verifiable structures in the repo itself.

---

## Core Principles

| Principle | What it means |
|-----------|---------------|
| **One canonical harness command** | `just check` (or equivalent) runs all gates locally and in CI |
| **Architecture as code** | Import boundaries enforced mechanically (Import Linter, grimp) |
| **Taste as code** | AST rules (ast-grep) ban patterns and prevent regressions |
| **Evidence-based chunks** | Every change produces tests, snapshots, or golden diffs |
| **Progressive disclosure** | `AGENTS.md` is a map, not an encyclopedia; deeper docs linked |
| **Agent-to-agent review** | Council of models votes on risky changes |

---

## Repository Structure

```
.
├── docs/
│   ├── harness-engineering.md    # Full HES v1 specification
│   └── workflows/
│       └── RPEQ.md               # Research → Plan → Execute → QA workflow
├── agents/                       # Agent definitions for specific tasks
│   ├── analysis/                 # Codebase analysis agents
│   ├── development/              # Development agents (TDD, refactoring)
│   ├── documentation/            # Documentation agents
│   ├── research/                 # Research and synthesis agents
│   ├── performance/              # Profiling and optimization agents
│   └── security/                 # Security review agents
├── commands/                     # Slash commands for Claude Code
│   ├── context engineering/      # Research, plan, execute workflow
│   ├── integration/              # External tool integrations
│   ├── quality-assurance/        # QA and inspection commands
│   └── utilities/                # Helper commands
├── skills/                       # Reusable skill definitions
│   ├── ast-grep-setup/           # TypeScript ast-grep rules setup
│   ├── codebase-research/        # Codebase mapping and research
│   ├── execute-from-plan/        # Execution from research docs
│   ├── planning-from-research/   # Plan generation
│   └── qa-from-execution/        # QA review after execution
├── prompt-hooks/                 # Prompt hooks for automation
├── alias/                        # Model alias configurations
└── rules/                        # Structural and taste rules
```

---

## Using This Repository

Most of the files in this repo (agents, commands, skills) are designed for **Claude Code** and **OpenAI Codex**. However, they can easily be adapted to other harnesses:

- **For other AI tools**: Just prompt your tool to read and adapt the files. The patterns are tool-agnostic.
- **For a universal sync tool**: We plan to build a sync tool that can push these definitions to any harness.
- **Internal use**: Clone this repo and ask Claude or Codex to set it up for your project. They will understand the structure and adapt it to your codebase.

The core principles and gates are universal. The implementation details (slash commands, prompt hooks) are just one expression of the Harness Engineering philosophy.

---

## The Six Gates

A Harness Engineering compliant repository enforces these gates:

1. **Gate A: Formatting + Lint** — Deterministic style enforcement (ruff, etc.)
2. **Gate B: Import Boundaries** — Architecture constraints via Import Linter
3. **Gate C: Structural Ratchets** — AST rules via ast-grep
4. **Gate D: Snapshot Testing** — Behavior lock via syrupy
5. **Gate E: Golden Outputs** — End-to-end deterministic artifacts
6. **Gate F: Numerical Equivalence** — Tolerances for math/ML/sims refactors

---

## Work Chunks

Changes merge only as **work chunks**—small, independently verifiable units with evidence:

- One thing changed
- Harness enforcement adjusted so the change stays true
- Evidence produced (tests, snapshots, goldens, diffs)
- All gates pass

Chunk documentation lives in `docs/chunks/NNN-<slug>.md` with:
- Intent (what changes)
- Preconditions (harness status, baselines)
- Exact commands
- Evidence (snapshots, goldens, numerical equivalence)
- Rollback procedure

---

## Current Status

This repository is **under active development**. We are:

- Building out agent definitions for common development tasks
- Creating slash commands for the RPEQ workflow
- Formalizing skill patterns for research, planning, execution, and QA
- Implementing prompt hooks for automated validation

See `docs/harness-engineering.md` for the full specification.

---

## References

- [OpenAI: Harness Engineering](https://openai.com/index/harness-engineering/) — The original article describing agent-first development at OpenAI
- [AGENTS.md](https://agents.md/) — Convention for agent instructions
- [Import Linter](https://import-linter.readthedocs.io/) — Architecture boundary enforcement
- [ast-grep](https://ast-grep.github.io/) — Structural search and linting
- [Syrupy](https://syrupy-project.github.io/syrupy/) — Snapshot testing

---

## License

MIT License — see [LICENSE](LICENSE) file for details.
