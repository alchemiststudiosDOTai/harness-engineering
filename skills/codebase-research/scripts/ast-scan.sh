#!/bin/bash
# ast-scan.sh - Scan codebase for structural patterns using ast-grep
# Usage: ast-scan.sh <pattern-type> [path] [--lang <language>]
#
# Pattern types:
#   functions    - All function/method definitions
#   classes      - All class definitions
#   exports      - All export statements
#   imports      - All import statements
#   types        - Type/interface definitions (TS)
#   components   - React/Vue components
#   routes       - API route definitions
#   handlers     - Error/event handlers
#   all          - Run all patterns
#
# Examples:
#   ast-scan.sh functions src/
#   ast-scan.sh classes --lang python
#   ast-scan.sh all ./lib

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RULES_DIR="$SCRIPT_DIR/ast-rules"

PATTERN_TYPE="${1:-all}"
SEARCH_PATH="${2:-.}"
LANG=""

# Parse optional --lang flag
shift 2 2>/dev/null || true
while [[ $# -gt 0 ]]; do
    case $1 in
        --lang)
            LANG="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

# Build language flag if specified
LANG_FLAG=""
if [[ -n "$LANG" ]]; then
    LANG_FLAG="--lang $LANG"
fi

scan_pattern() {
    local name="$1"
    local pattern="$2"
    echo "=== $name ===" >&2
    ast-grep --pattern "$pattern" "$SEARCH_PATH" $LANG_FLAG 2>/dev/null || true
}

scan_with_rule() {
    local name="$1"
    local rule_file="$2"
    if [[ -f "$RULES_DIR/$rule_file" ]]; then
        echo "=== $name ===" >&2
        ast-grep scan --rule "$RULES_DIR/$rule_file" "$SEARCH_PATH" 2>/dev/null || true
    fi
}

# Language-aware patterns
scan_functions() {
    echo "=== Function Definitions ===" >&2
    # JavaScript/TypeScript
    ast-grep --pattern 'function $NAME($$$) { $$$ }' "$SEARCH_PATH" 2>/dev/null || true
    ast-grep --pattern 'const $NAME = ($$$) => $$$' "$SEARCH_PATH" 2>/dev/null || true
    ast-grep --pattern 'const $NAME = function($$$) { $$$ }' "$SEARCH_PATH" 2>/dev/null || true
    ast-grep --pattern '$NAME($$$) { $$$ }' "$SEARCH_PATH" 2>/dev/null || true
    # Python
    ast-grep --pattern 'def $NAME($$$): $$$' "$SEARCH_PATH" --lang python 2>/dev/null || true
    # Rust
    ast-grep --pattern 'fn $NAME($$$) $$$' "$SEARCH_PATH" --lang rust 2>/dev/null || true
    # Go
    ast-grep --pattern 'func $NAME($$$) $$$' "$SEARCH_PATH" --lang go 2>/dev/null || true
}

scan_classes() {
    echo "=== Class Definitions ===" >&2
    # JavaScript/TypeScript
    ast-grep --pattern 'class $NAME { $$$ }' "$SEARCH_PATH" 2>/dev/null || true
    ast-grep --pattern 'class $NAME extends $PARENT { $$$ }' "$SEARCH_PATH" 2>/dev/null || true
    # Python
    ast-grep --pattern 'class $NAME: $$$' "$SEARCH_PATH" --lang python 2>/dev/null || true
    ast-grep --pattern 'class $NAME($$$): $$$' "$SEARCH_PATH" --lang python 2>/dev/null || true
    # Rust
    ast-grep --pattern 'struct $NAME { $$$ }' "$SEARCH_PATH" --lang rust 2>/dev/null || true
    ast-grep --pattern 'impl $NAME { $$$ }' "$SEARCH_PATH" --lang rust 2>/dev/null || true
}

scan_exports() {
    echo "=== Export Statements ===" >&2
    ast-grep --pattern 'export $$$' "$SEARCH_PATH" 2>/dev/null || true
    ast-grep --pattern 'module.exports = $$$' "$SEARCH_PATH" 2>/dev/null || true
    # Python
    ast-grep --pattern '__all__ = [$$$]' "$SEARCH_PATH" --lang python 2>/dev/null || true
}

scan_imports() {
    echo "=== Import Statements ===" >&2
    ast-grep --pattern 'import $$$' "$SEARCH_PATH" 2>/dev/null || true
    ast-grep --pattern 'require($$$)' "$SEARCH_PATH" 2>/dev/null || true
    # Python
    ast-grep --pattern 'from $$$ import $$$' "$SEARCH_PATH" --lang python 2>/dev/null || true
}

scan_types() {
    echo "=== Type Definitions ===" >&2
    ast-grep --pattern 'type $NAME = $$$' "$SEARCH_PATH" 2>/dev/null || true
    ast-grep --pattern 'interface $NAME { $$$ }' "$SEARCH_PATH" 2>/dev/null || true
    ast-grep --pattern 'enum $NAME { $$$ }' "$SEARCH_PATH" 2>/dev/null || true
}

scan_components() {
    echo "=== React/Vue Components ===" >&2
    # React functional components
    ast-grep --pattern 'function $NAME($$$): JSX.Element { $$$ }' "$SEARCH_PATH" 2>/dev/null || true
    ast-grep --pattern 'const $NAME: React.FC<$$$> = ($$$) => $$$' "$SEARCH_PATH" 2>/dev/null || true
    ast-grep --pattern 'const $NAME = ($$$) => { return (<$$$) }' "$SEARCH_PATH" 2>/dev/null || true
    # Vue defineComponent
    ast-grep --pattern 'defineComponent({ $$$ })' "$SEARCH_PATH" 2>/dev/null || true
}

scan_routes() {
    echo "=== API Routes ===" >&2
    # Express-style
    ast-grep --pattern 'app.get($$$)' "$SEARCH_PATH" 2>/dev/null || true
    ast-grep --pattern 'app.post($$$)' "$SEARCH_PATH" 2>/dev/null || true
    ast-grep --pattern 'app.put($$$)' "$SEARCH_PATH" 2>/dev/null || true
    ast-grep --pattern 'app.delete($$$)' "$SEARCH_PATH" 2>/dev/null || true
    ast-grep --pattern 'router.get($$$)' "$SEARCH_PATH" 2>/dev/null || true
    ast-grep --pattern 'router.post($$$)' "$SEARCH_PATH" 2>/dev/null || true
    # Next.js API routes (file-based, so just find the handlers)
    ast-grep --pattern 'export async function GET($$$) { $$$ }' "$SEARCH_PATH" 2>/dev/null || true
    ast-grep --pattern 'export async function POST($$$) { $$$ }' "$SEARCH_PATH" 2>/dev/null || true
    # FastAPI/Flask
    ast-grep --pattern '@app.get($$$)' "$SEARCH_PATH" --lang python 2>/dev/null || true
    ast-grep --pattern '@app.post($$$)' "$SEARCH_PATH" --lang python 2>/dev/null || true
    ast-grep --pattern '@app.route($$$)' "$SEARCH_PATH" --lang python 2>/dev/null || true
}

scan_handlers() {
    echo "=== Error/Event Handlers ===" >&2
    ast-grep --pattern 'catch ($$$) { $$$ }' "$SEARCH_PATH" 2>/dev/null || true
    ast-grep --pattern '.catch($$$)' "$SEARCH_PATH" 2>/dev/null || true
    ast-grep --pattern 'addEventListener($$$)' "$SEARCH_PATH" 2>/dev/null || true
    ast-grep --pattern '.on($$$)' "$SEARCH_PATH" 2>/dev/null || true
    # Python
    ast-grep --pattern 'except $$$: $$$' "$SEARCH_PATH" --lang python 2>/dev/null || true
}

case "$PATTERN_TYPE" in
    functions)
        scan_functions
        ;;
    classes)
        scan_classes
        ;;
    exports)
        scan_exports
        ;;
    imports)
        scan_imports
        ;;
    types)
        scan_types
        ;;
    components)
        scan_components
        ;;
    routes)
        scan_routes
        ;;
    handlers)
        scan_handlers
        ;;
    all)
        scan_functions
        echo ""
        scan_classes
        echo ""
        scan_exports
        echo ""
        scan_imports
        echo ""
        scan_types
        echo ""
        scan_routes
        ;;
    *)
        echo "Unknown pattern type: $PATTERN_TYPE" >&2
        echo "Valid types: functions, classes, exports, imports, types, components, routes, handlers, all" >&2
        exit 1
        ;;
esac
