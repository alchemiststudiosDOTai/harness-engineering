---
name: codebase-research
description: This skill should be used when mapping or researching a codebase to understand its structure, patterns, and architecture. Use when the user asks to "map the codebase", "research how X works", "find all Y patterns", or needs to understand code organization. Produces factual structural maps—no suggestions, no recommendations, just what exists. Uses ast-grep for structural pattern matching.
allowed-tools: Bash Read Glob Grep Agent
---

# Codebase Research

Map and document codebase structure using structural analysis. This skill produces **factual maps only**—no suggestions, no recommendations, no opinions. Document what exists, where it lives, and how it connects.

## Core Principle

**Map, don't suggest.** The output is a structural map that another developer (or Claude instance) can use to navigate the codebase. Include:
- File paths with line numbers
- Pattern locations
- Dependency relationships
- Symbol definitions

Exclude:
- Improvement suggestions
- Refactoring recommendations
- "Should" or "could" statements
- Opinions about code quality

## Available Scripts

### `scripts/ast-scan.sh` - Structural Pattern Scanner
Find code patterns using ast-grep.

```bash
# Scan for all function definitions
scripts/ast-scan.sh functions src/

# Find all class definitions
scripts/ast-scan.sh classes

# Find all exports
scripts/ast-scan.sh exports lib/

# Find API routes
scripts/ast-scan.sh routes

# Available patterns: functions, classes, exports, imports, types, components, routes, handlers, all
```

### `scripts/structure-map.sh` - Directory Tree
Generate filtered directory structure.

```bash
# Basic tree (auto-filters node_modules, .git, etc.)
scripts/structure-map.sh ./

# Limit depth
scripts/structure-map.sh ./ --depth 3

# Code files only
scripts/structure-map.sh src/ --code-only

# Include file counts
scripts/structure-map.sh ./ --with-stats
```

### `scripts/symbol-index.sh` - Public Symbol Index
Extract all exported/public symbols.

```bash
# Index all exports
scripts/symbol-index.sh src/

# Shows: exported functions, classes, types, interfaces, constants
```

### `scripts/dependency-graph.sh` - Import Tracer
Map dependency relationships.

```bash
# Show all imports
scripts/dependency-graph.sh src/

# Trace specific file's dependencies
scripts/dependency-graph.sh ./ --file src/core/auth.ts

# Shows: what it imports + what imports it
```

## Research Workflow

### Step 1: Deploy 3 Research Tasks in Parallel

**If subagents are available:** Spawn exactly 3 Task research tasks in parallel for comprehensive coverage.

Deploy these tasks simultaneously in a single message:

1. **codebase-locator** - Find WHERE files and components live
   - Prompt: "Locate all files related to [topic]. Find directory structure, entry points, and related modules."

2. **codebase-analyzer** - Understand HOW specific code works
   - Prompt: "Analyze the implementation of [component]. Map function signatures, class hierarchies, and data flow."

3. **context-synthesis** - Connect findings across components
   - Prompt: "Find connections between [area A] and [area B]. Trace dependencies and shared patterns."

```
YOU MUST DEPLOY ALL 3 TASKS IN A SINGLE MESSAGE
DO NOT DEPLOY SEQUENTIALLY - USE PARALLEL TASK CALLS
```

**If subagents are NOT available:** Execute the workflow in order — locator first, then analyzer, then synthesis.

### Step 2: Run Scripts for Structural Analysis

While waiting for agents, run ast-grep scripts:

```bash
scripts/structure-map.sh ./ --with-stats
scripts/ast-scan.sh all src/
scripts/symbol-index.sh src/
```

### Step 3: Wait and Synthesize

Wait for ALL research tasks to complete, then compile findings:
- Merge agent results with script output
- Cross-reference file paths
- Identify patterns across different findings

### Step 4: Document Findings

Store in `memory-bank/research/` using format:
   ```markdown
   # Research – <TOPIC>
   **Date:** YYYY-MM-DD
   **Phase:** Research

   ## Structure
   - Directory layout with purposes

   ## Key Files
   - `path/file.ts:L123` → what it defines

   ## Patterns Found
   - Pattern name: locations where it appears

   ## Dependencies
   - Module A → imports → Module B

   ## Symbol Index
   - Exported symbols with locations
   ```

## When to Use Each Script

| Need | Script |
|------|--------|
| "What's the file structure?" | `structure-map.sh` |
| "Where are the functions?" | `ast-scan.sh functions` |
| "What does this module export?" | `symbol-index.sh` |
| "What depends on this file?" | `dependency-graph.sh --file` |
| "Where are the API routes?" | `ast-scan.sh routes` |
| "Find all React components" | `ast-scan.sh components` |

## Output Requirements

All research output must:
- Include exact file paths
- Include line numbers where applicable
- State only what was found (no interpretation)
- Group related findings together
- Be reproducible (another scan would find the same things)
