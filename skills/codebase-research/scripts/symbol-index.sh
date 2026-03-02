#!/bin/bash
# symbol-index.sh - Extract and index public symbols from codebase
# Usage: symbol-index.sh [path] [--format json|table]
#
# Extracts:
#   - Exported functions/methods
#   - Exported classes
#   - Exported types/interfaces
#   - Exported constants
#
# Output format:
#   file:line symbol_type symbol_name

set -euo pipefail

SEARCH_PATH="${1:-.}"
FORMAT="table"

shift 2>/dev/null || true
while [[ $# -gt 0 ]]; do
    case $1 in
        --format)
            FORMAT="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

extract_symbols() {
    local path="$1"

    # TypeScript/JavaScript exports
    echo "=== Exported Functions ===" >&2
    ast-grep --pattern 'export function $NAME($$$) { $$$ }' "$path" 2>/dev/null | head -100 || true
    ast-grep --pattern 'export const $NAME = ($$$) => $$$' "$path" 2>/dev/null | head -100 || true
    ast-grep --pattern 'export async function $NAME($$$) { $$$ }' "$path" 2>/dev/null | head -100 || true

    echo ""
    echo "=== Exported Classes ===" >&2
    ast-grep --pattern 'export class $NAME { $$$ }' "$path" 2>/dev/null | head -100 || true
    ast-grep --pattern 'export default class $NAME { $$$ }' "$path" 2>/dev/null | head -100 || true

    echo ""
    echo "=== Exported Types/Interfaces ===" >&2
    ast-grep --pattern 'export type $NAME = $$$' "$path" 2>/dev/null | head -100 || true
    ast-grep --pattern 'export interface $NAME { $$$ }' "$path" 2>/dev/null | head -100 || true

    echo ""
    echo "=== Exported Constants ===" >&2
    ast-grep --pattern 'export const $NAME = $$$' "$path" 2>/dev/null | head -100 || true

    echo ""
    echo "=== Python Public Symbols ===" >&2
    # Python: functions not starting with _
    ast-grep --pattern 'def $NAME($$$): $$$' "$path" --lang python 2>/dev/null | grep -v 'def _' | head -100 || true
    # Python: classes
    ast-grep --pattern 'class $NAME($$$): $$$' "$path" --lang python 2>/dev/null | head -100 || true
    ast-grep --pattern 'class $NAME: $$$' "$path" --lang python 2>/dev/null | head -100 || true
}

extract_symbols "$SEARCH_PATH"
