#!/bin/bash
# dependency-graph.sh - Trace import/dependency relationships
# Usage: dependency-graph.sh [path] [--file <specific-file>] [--format dot|list]
#
# Modes:
#   Default: Show all imports grouped by file
#   --file: Show what a specific file imports AND what imports it
#
# Output helps understand:
#   - Module dependencies
#   - Circular dependency risks
#   - Core modules (imported by many)
#   - Leaf modules (import many, imported by few)

set -euo pipefail

SEARCH_PATH="${1:-.}"
SPECIFIC_FILE=""
FORMAT="list"

shift 2>/dev/null || true
while [[ $# -gt 0 ]]; do
    case $1 in
        --file)
            SPECIFIC_FILE="$2"
            shift 2
            ;;
        --format)
            FORMAT="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

if [[ -n "$SPECIFIC_FILE" ]]; then
    echo "=== Imports in $SPECIFIC_FILE ===" >&2
    ast-grep --pattern 'import $$$' "$SPECIFIC_FILE" 2>/dev/null || true
    ast-grep --pattern 'from $$$ import $$$' "$SPECIFIC_FILE" --lang python 2>/dev/null || true

    echo ""
    echo "=== Files that import $SPECIFIC_FILE ===" >&2
    BASENAME=$(basename "$SPECIFIC_FILE" | sed 's/\.[^.]*$//')
    grep -r "from.*$BASENAME" "$SEARCH_PATH" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" -l 2>/dev/null || true
    grep -r "import.*$BASENAME" "$SEARCH_PATH" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" --include="*.py" -l 2>/dev/null || true
else
    echo "=== Import Map ===" >&2

    # Find all imports and group by file
    find "$SEARCH_PATH" -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \) \
        ! -path "*/node_modules/*" ! -path "*/.git/*" ! -path "*/dist/*" ! -path "*/build/*" \
        -exec sh -c '
            echo "--- {} ---"
            ast-grep --pattern "import $$$" "{}" 2>/dev/null | head -20 || true
        ' \; 2>/dev/null | head -500

    echo ""
    echo "=== Most Imported Modules ===" >&2
    grep -rh "from ['\"]" "$SEARCH_PATH" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" 2>/dev/null | \
        sed "s/.*from ['\"]\\([^'\"]*\\)['\"].*/\\1/" | \
        sort | uniq -c | sort -rn | head -20 || true
fi
