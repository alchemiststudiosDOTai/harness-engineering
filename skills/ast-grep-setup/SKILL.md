---
name: ast-grep-setup
description: Set up ast-grep for a codebase with common TypeScript rules for detecting anti-patterns, enforcing best practices, and preventing bugs. Creates sgconfig.yml, rule files, and rule tests. Use when adding structural linting, banning legacy patterns, or implementing ratchet gates.
---

# ast-grep Setup Skill

Set up ast-grep with common TypeScript rules for detecting anti-patterns, enforcing best practices, and preventing bugs.

## When to Use

- Adding structural linting to a TypeScript codebase
- Banning legacy patterns after migration
- Implementing ratchet gates (block new violations while grandfathering existing ones)
- Enforcing architecture boundaries
- Preventing common TypeScript/JavaScript bugs

## Quick Start

### 1. Initialize ast-grep Configuration

```bash
# Create sgconfig.yml in project root
mkdir -p rules/ast-grep/rules rules/ast-grep/rule-tests
cat > rules/ast-grep/sgconfig.yml << 'EOF'
ruleDirs:
  - rules
testConfigs:
  - testDir: rule-tests
    allowedFixers: []
EOF
```

### 2. Add Rules for Common TypeScript Pain Points

See the [Rule Library](#rule-library) below for ready-to-use rules.

### 3. Run and Test

```bash
# Scan the codebase
cd rules/ast-grep && ast-grep scan

# Run rule tests
cd rules/ast-grep && ast-grep test

# Update test snapshots after rule changes
cd rules/ast-grep && ast-grep test -U
```

## Rule Library

### Type Safety Rules

#### no-implicit-any-params
Prevents function parameters without explicit types (implicit any).

```yaml
# rules/no-implicit-any-params.yml
id: no-implicit-any-params
language: TypeScript
severity: warning
message: "Parameter '$PARAM' lacks explicit type annotation"
files:
  - src/**/*.ts
  - src/**/*.tsx
rule:
  pattern: function $FUNC($PARAM) { $$$BODY }
  constraints:
    PARAM:
      not:
        has:
          kind: type_annotation
```

#### no-unsafe-any-usage
Bans direct property access on `any` typed values.

```yaml
# rules/no-unsafe-any-usage.yml
id: no-unsafe-any-usage
language: TypeScript
severity: error
message: "Unsafe property access on 'any' type. Cast or add type guard."
rule:
  pattern: $EXPR.$PROP
  constraints:
    EXPR:
      typeAnnotation: any
```

### Async/Await Rules

#### no-floating-promises
Prevents unhandled promises that could fail silently.

```yaml
# rules/no-floating-promises.yml
id: no-floating-promises
language: TypeScript
severity: error
message: "Promise is not awaited, returned, or handled with .catch()"
files:
  - src/**/*.ts
  - src/**/*.tsx
ignores:
  - new Promise($$$)
  - Promise.$FUNC($$$)
rule:
  all:
    - pattern: $PROMISE_FUNC($$$ARGS)
    - has:
        kind: call_expression
        pattern: $PROMISE_FUNC($$$ARGS)
    - not:
        inside:
          kind: await_expression
          stopBy: end
    - not:
        inside:
          kind: return_statement
          stopBy: end
    - not:
        inside:
          kind: call_expression
          pattern: $$$.catch($$$)
          stopBy: end
  constraints:
    PROMISE_FUNC:
      regex: (fetch|axios\.[a-z]+|async|\.then)
```

#### no-missing-await
Detects async function calls without await.

```yaml
# rules/no-missing-await.yml
id: no-missing-await
language: TypeScript
severity: warning
message: "Async function '$FUNC' called without await"
files:
  - src/**/*.ts
  - src/**/*.tsx
rule:
  all:
    - pattern: $FUNC($$$ARGS)
    - not:
        inside:
          kind: await_expression
          stopBy: end
    - not:
        inside:
          kind: return_statement
          stopBy: end
  constraints:
    FUNC:
      typeAnnotation: /^Promise</
```

### Error Handling Rules

#### no-empty-catch
Bans empty catch blocks that swallow errors.

```yaml
# rules/no-empty-catch.yml
id: no-empty-catch
language: TypeScript
severity: error
message: "Empty catch block silently swallows errors. Log or re-throw."
files:
  - src/**/*.ts
  - src/**/*.tsx
rule:
  all:
    - pattern: try { $$$TRY } catch ($ERROR) { $$$CATCH }
    - not:
        has:
          kind: statement
          inside:
            kind: catch_clause
            pattern: $$$CATCH
```
```

#### require-error-logging
Requires error logging in catch blocks.

```yaml
# rules/require-error-logging.yml
id: require-error-logging
language: TypeScript
severity: warning
message: "Catch block should log the error"
files:
  - src/**/*.ts
  - src/**/*.tsx
rule:
  all:
    - pattern: try { $$$TRY } catch ($ERR) { $$$CATCH }
    - not:
        has:
          kind: call_expression
          pattern: console.$LOG($ERR)
          inside:
            kind: catch_clause
            pattern: $$$CATCH
    - not:
        has:
          kind: call_expression
          pattern: logger.$LOG($ERR)
          inside:
            kind: catch_clause
            pattern: $$$CATCH
```

### React Rules

#### no-use-effect-missing-deps
Flags useEffect hooks that might be missing dependencies.

```yaml
# rules/no-use-effect-missing-deps.yml
id: no-use-effect-missing-deps
language: TypeScript
severity: warning
message: "useEffect has an empty dependency array but references external values"
files:
  - src/**/*.tsx
rule:
  pattern: useEffect($FUNC, [])
  constraints:
    FUNC:
      has:
        kind: identifier
        pattern: $ID
        not:
          pattern: console
```

#### no-direct-state-mutation
Prevents direct state mutation in React.

```yaml
# rules/no-direct-state-mutation.yml
id: no-direct-state-mutation
language: TypeScript
severity: error
message: "Do not mutate state directly. Use the setter function."
files:
  - src/**/*.tsx
rule:
  all:
    - pattern: $STATE.$PROP = $VAL
    - has:
        kind: identifier
        pattern: $STATE
        regex: ^set[A-Z]
```

### Performance Rules

#### no-array-reduce-for-objects
Warns about using reduce to build objects (often less readable).

```yaml
# rules/no-array-reduce-for-objects.yml
id: no-array-reduce-for-objects
language: TypeScript
severity: warning
message: "Consider using Object.fromEntries() or a for...of loop instead of reduce for building objects"
files:
  - src/**/*.ts
  - src/**/*.tsx
rule:
  pattern: $ARR.reduce(($ACC, $ITEM) => { $$$BODY; return $ACC; }, {})
```

#### no-regex-in-loop
Prevents regex creation inside loops (compiles on each iteration).

```yaml
# rules/no-regex-in-loop.yml
id: no-regex-in-loop
language: TypeScript
severity: warning
message: "Creating regex inside loop - move outside or use constant"
files:
  - src/**/*.ts
  - src/**/*.tsx
rule:
  inside:
    kind: for_statement
    stopBy: end
  pattern: /$PAT/
```

### Architecture Rules

#### no-cross-module-imports
Enforces module boundaries (customize for your architecture).

```yaml
# rules/no-cross-module-imports.yml
id: no-cross-module-imports
language: TypeScript
severity: error
message: "Domain modules should not import from other domain modules directly"
files:
  - src/domain/**/*.ts
rule:
  all:
    - pattern: import $$$ from "$MOD"
    - matches:
        source: $MOD
        contains: /domain/
```

#### no-node-in-frontend
Prevents Node.js modules from being imported in frontend code.

```yaml
# rules/no-node-in-frontend.yml
id: no-node-in-frontend
language: TypeScript
severity: error
message: "Node.js built-in modules cannot be used in frontend code"
files:
  - src/frontend/**/*.ts
  - src/frontend/**/*.tsx
  - src/client/**/*.ts
  - src/client/**/*.tsx
rule:
  all:
    - pattern: import $$$ from "$MOD"
    - matches:
        source: $MOD
        regex: ^(fs|path|os|crypto|http|https|net|dgram|dns|cluster|module|vm|child_process|worker_threads)$
```

### Best Practice Rules

#### no-console-log
Prevents console.log in production code (use a logger instead).

```yaml
# rules/no-console-log.yml
id: no-console-log
language: TypeScript
severity: warning
message: "Use a proper logger instead of console.log"
files:
  - src/**/*.ts
  - src/**/*.tsx
ignores:
  - "**/*.test.ts"
  - "**/*.spec.ts"
  - "**/__tests__/**"
rule:
  pattern: console.log($$$ARGS)
```

#### no-debugger
Prevents debugger statements.

```yaml
# rules/no-debugger.yml
id: no-debugger
language: TypeScript
severity: error
message: "Remove debugger statement before committing"
files:
  - src/**/*.ts
  - src/**/*.tsx
rule:
  pattern: debugger;
```

#### prefer-const-over-let
Suggests const when variable is never reassigned.

```yaml
# rules/prefer-const-over-let.yml
id: prefer-const-over-let
language: TypeScript
severity: hint
message: "Consider using 'const' since this variable is never reassigned"
files:
  - src/**/*.ts
  - src/**/*.tsx
rule:
  all:
    - pattern: let $VAR = $INIT
    - not:
        follows:
          pattern: $VAR = $NEWVAL
          stopBy: end
```

## Rule Tests

Each rule should have a corresponding test file:

### Example: no-floating-promises-test.yml

```yaml
id: no-floating-promises
valid:
  - |
    const result = await fetch('/api/users');
  - |
    return fetch('/api/users');
  - |
    fetch('/api/users').catch(err => console.error(err));
  - |
    new Promise((resolve) => setTimeout(resolve, 1000));
  - |
    Promise.all([fetch('/a'), fetch('/b')]);
invalid:
  - |
    function getUsers() {
      fetch('/api/users');
    }
  - |
    async function load() {
      fetch('/api/data');
    }
```

## Advanced Patterns

### Ratchet Mode: Allow Existing Violations

To implement a ratchet (block new violations while allowing existing ones):

```bash
# 1. Generate baseline of current violations
ast-grep scan --json > baseline/violations.json

# 2. Create baseline extractor script
cat > tools/ast-grep/baseline-check.sh << 'SCRIPT'
#!/bin/bash
# Check only new violations against baseline
ast-grep scan --json | node -e '
const baseline = require("./baseline/violations.json");
const current = JSON.parse(require("fs").readFileSync(0, "utf-8"));
const baselineSet = new Set(baseline.map(v => `${v.file}:${v.line}:${v.ruleId}`));
const newViolations = current.filter(v => !baselineSet.has(`${v.file}:${v.line}:${v.ruleId}`));
if (newViolations.length > 0) {
  console.error("New violations found:");
  newViolations.forEach(v => console.error(`${v.file}:${v.line} - ${v.message}`));
  process.exit(1);
}
'
SCRIPT
chmod +x tools/ast-grep/baseline-check.sh
```

### CI Integration

```yaml
# .github/workflows/ast-grep.yml
name: ast-grep
on: [push, pull_request]
jobs:
  ast-grep:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Node
        uses: actions/setup-node@v4
      - name: Install ast-grep
        run: npm install -g @ast-grep/cli
      - name: Run ast-grep scan
        run: cd rules/ast-grep && ast-grep scan
      - name: Run rule tests
        run: cd rules/ast-grep && ast-grep test
```

### IDE Integration

VS Code: Install the "ast-grep" extension for inline highlighting.

## Rule Writing Tips

1. **Start simple**: Use basic patterns first, then add constraints
2. **Test edge cases**: Create comprehensive rule-tests
3. **Use constraints**: Filter by typeAnnotation, regex, kind
4. **Check inside/outside**: Use `inside`, `follows`, `precedes` for context
5. **StopBy carefully**: Control matching scope with `stopBy: end` or `stopBy: neighbor`

## Common Pattern Reference

| Pattern | Matches |
|---------|---------|
| `function $FUNC($$$PARAMS) { $$$BODY }` | Function declarations |
| `const $VAR = $EXPR` | Const declarations |
| `$EXPR.$PROP` | Property access |
| `import $$$ from "$MOD"` | Import statements |
| `export $KIND $NAME` | Export declarations |
| `$FUNC($$$ARGS)` | Function calls |
| `await $EXPR` | Await expressions |
| `try { $$$TRY } catch ($ERR) { $$$CATCH }` | Try-catch |
| `$ARR.map($FN)` | Array methods |
