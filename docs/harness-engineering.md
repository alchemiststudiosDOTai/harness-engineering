## Harness Engineering Specification (HES) v1

This is a **mechanical, repo-enforced** harness for making large (often agent-driven) change safe, reviewable, and incremental.

It is not “architecture docs.” It is **gates + evidence**.

---

# 1) Terms

**Harness**: the set of **automated checks** that must pass for change to merge.

**Gate**: a single check that returns pass/fail (ex: `lint-imports`, `ast-grep scan`, unit tests, snapshot tests).

**Ratchet**: a gate that **allows existing violations** (baseline) but **blocks new ones**, and forces the baseline to shrink over time.

**Work chunk**: the unit of change you merge. It is small, independently verifiable, and produces evidence (tests, golden outputs, diffs).

**Council**: multiple independent reviewers (agents) that vote to accept/reject a work chunk based on evidence + diff.

---

# 2) Non-negotiable invariants

## 2.1 Repo has one canonical “run the harness” command

- **MUST** provide a single command that runs the whole harness locally (example: `just check`).
- **MUST** be the same command CI runs (or CI calls the same underlying scripts).

This matches the “make the environment legible and enforceable” approach from OpenAI’s harness engineering writeup: constraints must be executable, not prose. ([OpenAI][1])

## 2.2 Architecture constraints are codified

- **MUST** mechanically enforce import boundaries.
- Python baseline: **Import Linter** contracts (built on an import graph) +/or direct **grimp** checks.

Import Linter is explicitly designed to impose architectural import constraints and fail CI when violated. ([PyPI][2])
Forbidden contracts are first-class and support TOML config in `pyproject.toml`. ([Import Linter][3])

## 2.3 Structural “taste” rules are codified

- **MUST** be able to ban patterns and prevent regressions even if tests pass.
- Baseline recommendation: **ast-grep** rules + rule tests + snapshots.

ast-grep supports project scanning via `sgconfig.yml`, and rule tests + snapshot baselines via `ast-grep test`. ([Ast Grep][4])

## 2.4 Behavioral feedback loop is strong

- **MUST** have automated tests.
- **MUST** include at least one of:
  - committed **snapshots** (API outputs, rendered structures),
  - committed **golden outputs** (end-to-end results),
  - **numerical equivalence** checks (tolerances, invariants).

Syrupy is a pytest snapshot plugin designed for committed snapshots and update workflows. ([Syrupy Project][5])

## 2.5 Changes merge only as work chunks

- **MUST** be small enough that the harness can attribute failures to a single chunk.
- **MUST** include verifiable evidence (tests, snapshots, golden diffs).

---

# 3) Required repository layout

Use this layout as the baseline. Adjust naming to your project, but keep the roles.

```
.
├─ AGENTS.md
├─ justfile
├─ pyproject.toml
├─ src/<pkg>/
├─ tests/
│  ├─ __snapshots__/          # syrupy snapshots
│  └─ goldens/                # canonical outputs (optional but recommended)
├─ tools/
│  ├─ ast-grep/
│  │  ├─ sgconfig.yml
│  │  ├─ rules/
│  │  └─ rule-tests/
│  └─ harness/
│     ├─ normalize.py         # determinism helpers
│     ├─ golden.py            # generate/compare goldens
│     └─ council.py           # council runner (local + CI)
└─ .github/workflows/check.yml
```

### AGENTS.md

Keep it short and executable: “how to run harness”, “where rules live”, “how to update snapshots/goldens”, “what a work chunk must contain”.

AGENTS.md is widely used as a dedicated, predictable place to instruct coding agents (separate from README). ([Agents][6])
OpenAI explicitly warns that a single giant instruction file rots and becomes ineffective; keep repo knowledge legible and enforceable. ([OpenAI][1])

---

# 4) The Gates (what must pass)

## Gate A: Formatting + lint

Pick your stack (example: `ruff`). The harness spec doesn’t care which, only that it’s deterministic and run in CI.

## Gate B: Import boundaries (architecture)

### Recommended default: Import Linter in `pyproject.toml`

**Minimal `pyproject.toml` example:**

```toml
[tool.importlinter]
root_package = "myproj"

[[tool.importlinter.contracts]]
name = "Domain must not import infrastructure"
type = "forbidden"
source_modules = ["myproj.domain"]
forbidden_modules = ["myproj.infra"]

[[tool.importlinter.contracts]]
name = "API layer must not import infra directly"
type = "forbidden"
source_modules = ["myproj.api"]
forbidden_modules = ["myproj.infra"]
allow_indirect_imports = true
```

- Import Linter config discovery supports `pyproject.toml`. ([Import Linter][7])
- Forbidden contract type and TOML `[[tool.importlinter.contracts]]` syntax is documented. ([Import Linter][3])
- Run via `lint-imports`. ([Import Linter][8])

### When Import Linter isn’t expressive enough: add a direct grimp test

grimp builds a queryable import graph for Python packages. ([GitHub][9])

Example guard test:

```python
# tests/test_architecture_imports.py
import grimp

def test_no_domain_to_infra_routes():
    graph = grimp.build_graph("myproj")
    # Find any path from domain to infra
    routes = graph.find_paths("myproj.domain", "myproj.infra")
    assert routes == [], f"Forbidden import routes found: {routes}"
```

(Adjust to the actual grimp API you use; the point is: **import graph → assert forbidden edges**.)

## Gate C: Structural ratchets (AST rules)

### ast-grep project config

`tools/ast-grep/sgconfig.yml`:

```yaml
ruleDirs:
  - rules
testConfigs:
  - testDir: rule-tests
```

ast-grep scanning requires `sgconfig.yml` + a rule directory; project config is documented. ([Ast Grep][4])
Rule keys (`id`, `language`, `rule`, `files`, etc.) are documented. ([Ast Grep][10])

### Example rule: ban a legacy API

`tools/ast-grep/rules/no-legacy-client.yml`:

```yaml
id: no-legacy-client
language: Python
severity: error
message: "LegacyClient is banned. Use NewClient (see docs/harness/legacy-client.md)."
files:
  - src/**/*.py
rule:
  pattern: LegacyClient($$$ARGS)
```

### Rule tests + snapshots

`tools/ast-grep/rule-tests/no-legacy-client-test.yml`:

```yaml
id: no-legacy-client
valid:
  - |
    NewClient()
invalid:
  - |
    LegacyClient()
```

Run:

- `ast-grep scan` (enforce rules in repo) ([Ast Grep][11])
- `ast-grep test -U` (generate/update snapshots when rules evolve) ([Ast Grep][12])

This is your “ratchet after cleanup”: delete the bad pattern → add a rule that prevents reintroduction.

## Gate D: Snapshot testing (behavior lock)

### Syrupy baseline

Example:

```python
# tests/test_api_contract.py
def normalize(obj):
    # stable ordering / rounding / redaction goes here
    return obj

def test_contract(snapshot):
    out = call_api()
    assert normalize(out) == snapshot
```

Syrupy usage, snapshot generation location, and update flag (`pytest --snapshot-update`) are documented. ([Syrupy Project][5])

## Gate E: Golden outputs (end-to-end)

This is for things like:

- compile output,
- model inference outputs,
- simulation ticks,
- migrations,
- reports.

**Rule: goldens must be deterministic.** If they aren’t, you normalize.

Pattern:

- `tools/harness/golden.py generate` writes `tests/goldens/<case>.json`
- `tools/harness/golden.py compare` diffs current run vs committed golden
- CI fails on diff.

This gives you **diffable evidence** for each chunk.

## Gate F: Numerical equivalence (when refactoring math/ML/sims)

- Compare floats with tolerances (absolute/relative).
- Normalize RNG seeds.
- Quantize outputs where needed.

Your acceptance criteria must state: **which metrics must be equal within what tolerance**.

---

# 5) CI: all gates run, always

A **single failure must not hide other failures**. Use a matrix and disable fail-fast so you get a full report.

GitHub Actions example:

```yaml
name: check

on:
  pull_request:
  push:

jobs:
  checks:
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        task:
          - lint
          - imports
          - ast
          - test
    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.12"

      - name: Install uv
        run: pip install uv

      - name: Sync deps
        run: uv sync --locked

      - name: Run task
        run: |
          case "${{ matrix.task }}" in
            lint)   just lint ;;
            imports) just imports ;;
            ast)    just ast ;;
            test)   just test ;;
          esac
```

GitHub documents `strategy.fail-fast` behavior and `fail-fast: false`. ([GitHub Docs][13])

---

# 6) Local developer loop: `just check`

Use `just` so the harness is **one command**.

`just` is explicitly a project command runner with recipes in `justfile`. ([GitHub][14])

Example `justfile`:

```make
set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

check: lint imports ast test

lint:
  ruff check .
  ruff format --check .

imports:
  lint-imports

ast:
  (cd tools/ast-grep && ast-grep scan)
  (cd tools/ast-grep && ast-grep test)

test:
  pytest
```

---

# 7) Work chunks: the merge unit

## 7.1 Chunk acceptance criteria (hard)

A work chunk **MUST**:

1. Change one thing.
2. Add/adjust harness enforcement so the change **stays true**.
3. Produce evidence (tests/snapshots/goldens/diffs).
4. Pass all gates.

This is the core “throughput changes merge philosophy” point: you need a harness that makes small merges safe and repeatable. ([OpenAI][1])

## 7.2 Chunk file template (commit with every chunk)

Create: `docs/chunks/NNN-<slug>.md`

Template:

````md
# Chunk NNN: <slug>

## Intent

- What changes in behavior/structure?

## Preconditions

- Current harness status: <green/red>
- Baselines used: (snapshot ids / golden files / allowlists)

## Commands (exact)

```bash
just check
python tools/harness/golden.py generate <case>
python tools/harness/golden.py compare <case>
```
````

## Evidence

- Snapshots updated: yes/no (paths)
- Goldens diff: attached (paths)
- Numerical equivalence: metric + tolerance

## Rollback

- How to revert safely

```

This is how you avoid “agent gets lost”: you never feed “the whole thing,” you feed **one chunk with proof**.

---

# 8) Ratchets for brownfield repos

A brownfield repo usually can’t go from “no rules” → “perfect rules” without stopping all work.

So you ratchet.

## 8.1 Ratchet rule (hard)
A ratchet gate:
- allows existing violations by baseline list
- blocks new violations
- fails if baseline contains entries that no longer violate (forces shrink)

## 8.2 Concrete ratchet pattern
- `baseline/*.txt` contains known violations
- checker emits “current violations”
- CI fails if:
  - `new = current - baseline` is non-empty
  - `stale = baseline - current` is non-empty (forces cleanup of baseline)

This turns “legacy mess” into a measurable burndown without blocking all change.

---

# 9) Council: 3-agent acceptance gate

Purpose: **don’t rely on one model** to greenlight risky change.

## 9.1 Council rule (hard)
- Council reads:
  - diff,
  - chunk doc,
  - harness results,
  - golden diffs / snapshots.
- Council outputs JSON: `{ "vote": "accept|reject", "reasons": [...], "required_fixes": [...] }`
- Merge requires:
  - all harness gates green
  - **2/3 accept** (Codex + Gemini + Claude)

This mirrors the “agent-to-agent review” approach described by OpenAI (pushing review effort toward agents once the harness exists). :contentReference[oaicite:19]{index=19}

## 9.2 Implementation skeleton
Create `tools/harness/council.py`:
- collects artifacts
- calls `tools/harness/reviewers/codex.sh`, `gemini.sh`, `claude.sh`
- aggregates votes
- fails non-zero if reject threshold hit

You can keep reviewer scripts as thin wrappers that:
- read `prompt.md`
- print JSON to stdout

In CI, run `python tools/harness/council.py --chunk docs/chunks/NNN-*.md --diff "$GITHUB_SHA"`.

---

# 10) Implementation steps

You asked for **exact steps** for greenfield and brownfield. Here they are as one focused plan per case.

---

## A) Greenfield repo: implement HES v1 in order

### Step A1 — Scaffold repo + lock dependencies
1. Initialize project with uv
2. Commit `pyproject.toml` + `uv.lock`
3. CI uses `uv sync --locked`

uv’s docs describe `uv.lock` and that it should be checked in for reproducible installs. :contentReference[oaicite:20]{index=20}

**Acceptance**: `uv sync --locked` succeeds on a clean machine.

### Step A2 — Add `justfile` with `just check`
- Implement `check` recipe calling all gates.

`just` recipes and `justfile` behavior are documented. :contentReference[oaicite:21]{index=21}

**Acceptance**: `just check` runs locally and fails correctly when you introduce an error.

### Step A3 — Enforce architecture boundaries
- Add Import Linter + at least 2 forbidden contracts that encode your layering.

Import Linter contract config and forbidden contracts are documented. :contentReference[oaicite:22]{index=22}

**Acceptance**: a deliberately wrong import fails `lint-imports` with a clear message.

### Step A4 — Add ast-grep scanning + rule testing
- Add `tools/ast-grep/sgconfig.yml`
- Add one rule that bans a known “bad” pattern
- Add `rule-tests/` + snapshots

ast-grep’s project scanning and rule testing are documented. :contentReference[oaicite:23]{index=23}

**Acceptance**: `ast-grep scan` catches the banned pattern; `ast-grep test` passes.

### Step A5 — Add snapshot testing
- Add syrupy
- Add 1–3 snapshot tests around stable, high-value interfaces.

Syrupy usage and snapshot update flow are documented. :contentReference[oaicite:24]{index=24}

**Acceptance**: tests fail on first run, pass after `pytest --snapshot-update`, and diffs are reviewable.

### Step A6 — Add golden outputs (if you have E2E artifacts)
- Add `tools/harness/golden.py`
- Commit first goldens
- Add compare step to CI

**Acceptance**: golden compare fails if output changes; shows a minimal diff.

### Step A7 — Wire CI matrix (fail-fast disabled)
- Add `.github/workflows/check.yml` matrix with `fail-fast: false`.

GitHub documents `fail-fast` and its effect. :contentReference[oaicite:25]{index=25}

**Acceptance**: if lint fails, tests still run and report (no early cancel).

### Step A8 — Add chunk protocol + council
- Add `docs/chunks/` template
- Add `tools/harness/council.py`
- Require chunk doc for PRs via CI check

**Acceptance**: PR fails if missing chunk doc; council rejects if evidence missing.

---

## B) Brownfield repo: implement HES v1 without stopping the world

### Step B1 — Stabilize “can run tests in CI”
- Add a minimal `just check` that at least runs the current tests.
- Fix flaky tests first (only enough to make the loop reliable).

**Acceptance**: CI is green on main for at least a few merges.

### Step B2 — Characterize current behavior with snapshots/goldens
- Pick 3–10 critical surfaces (API payloads, reports, pipeline outputs).
- Snapshot them (syrupy) and/or commit goldens.

This is your “don’t refactor blind” lock-in. Syrupy’s workflow is designed for this. :contentReference[oaicite:26]{index=26}

**Acceptance**: you can change internals and prove externals unchanged.

### Step B3 — Add architecture boundaries as a ratchet
- Start with 1–2 high-level contracts (domain vs infra).
- If it breaks everywhere: baseline existing violations and ratchet (block new).

Import Linter supports contract-based enforcement; config in `pyproject.toml` is standard. :contentReference[oaicite:27]{index=27}

**Acceptance**: new forbidden import causes CI failure; baseline shrinks over time.

### Step B4 — Add ast-grep ratchets after each cleanup
Process:
1. Remove a bad pattern
2. Add ast-grep rule that bans reintroduction
3. Add rule test + snapshot

ast-grep explicitly supports rule tests + snapshot baselines. :contentReference[oaicite:28]{index=28}

**Acceptance**: pattern can’t come back without deliberate rule change.

### Step B5 — Add guard tests for invariants the type system won’t catch
Examples:
- registry ordering
- forbidden callsites
- table constraints
- no direct SQL in handlers
- feature flags must be declared centrally

**Acceptance**: you can’t bypass conventions without breaking tests.

### Step B6 — Add council only after gates are reliable
Council is not a substitute for harness gates. It’s an extra check once evidence is strong.

OpenAI’s writeup emphasizes enforcing invariants and making rules legible to agents; council works only if those invariants exist. :contentReference[oaicite:29]{index=29}

**Acceptance**: council votes are stable and correlate with harness results.

---

# 11) What to rename / remove (per your instruction)

- Do **not** frame anything as “dream architecture.”
- Call it what it is: **Architecture Contracts** + **Harness Gates** + **Work Chunks**.

That wording keeps the guide operational and prevents it from turning into aspirational docs.

---

If you paste “tips and actual implementations you’ve done” (even rough bullets + file snippets), I’ll splice them into this spec as **drop-in sections** (with your naming, your commands, your exact gates) without expanding scope or adding theory.
::contentReference[oaicite:30]{index=30}
```

[1]: https://openai.com/index/harness-engineering/?utm_source=chatgpt.com "Harness engineering: leveraging Codex in an agent-first world | OpenAI"
[2]: https://pypi.org/project/import-linter/2.3/?utm_source=chatgpt.com "import-linter · PyPI"
[3]: https://import-linter.readthedocs.io/en/v2.9/contract_types/forbidden/?utm_source=chatgpt.com "Forbidden - Import Linter"
[4]: https://ast-grep.github.io/guide/project/project-config.html?utm_source=chatgpt.com "Project Configuration | ast-grep"
[5]: https://syrupy-project.github.io/syrupy/?utm_source=chatgpt.com "syrupy | :pancakes: The sweeter pytest snapshot plugin"
[6]: https://agents.md/?utm_source=chatgpt.com "AGENTS.md"
[7]: https://import-linter.readthedocs.io/en/v2.9/get_started/configure/?utm_source=chatgpt.com "Configure - Import Linter"
[8]: https://import-linter.readthedocs.io/en/v1.7.0/usage.html?utm_source=chatgpt.com "Usage — Import Linter 1.7.0 documentation"
[9]: https://github.com/seddonym/grimp?utm_source=chatgpt.com "GitHub - python-grimp/grimp: Builds a graph of a Python project's internal dependencies."
[10]: https://ast-grep.github.io/reference/yaml.html?utm_source=chatgpt.com "Configuration Reference | ast-grep"
[11]: https://ast-grep.github.io/guide/scan-project.html?utm_source=chatgpt.com "Scan Your Project! | ast-grep"
[12]: https://ast-grep.github.io/guide/test-rule.html?utm_source=chatgpt.com "Test Your Rule | ast-grep"
[13]: https://docs.github.com/actions/reference/workflows-and-actions/workflow-syntax?utm_source=chatgpt.com "Workflow syntax for GitHub Actions - GitHub Docs"
[14]: https://github.com/casey/just?utm_source=chatgpt.com "GitHub - casey/just: 🤖 Just a command runner"
