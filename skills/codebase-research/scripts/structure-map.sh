#!/bin/bash
# structure-map.sh - Generate intelligent directory tree
# Usage: structure-map.sh [path] [--depth N] [--code-only]
#
# Options:
#   --depth N     Limit tree depth (default: 4)
#   --code-only   Only show code files, skip configs/docs
#   --with-stats  Include file counts per directory
#
# Automatically filters: node_modules, .git, __pycache__, .venv, dist, build, etc.

set -euo pipefail

SEARCH_PATH="${1:-.}"
MAX_DEPTH=4
CODE_ONLY=false
WITH_STATS=false

# Parse flags
shift 2>/dev/null || true
while [[ $# -gt 0 ]]; do
    case $1 in
        --depth)
            MAX_DEPTH="$2"
            shift 2
            ;;
        --code-only)
            CODE_ONLY=true
            shift
            ;;
        --with-stats)
            WITH_STATS=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# Common directories to ignore
IGNORE_DIRS=(
    "node_modules"
    ".git"
    "__pycache__"
    ".venv"
    "venv"
    ".env"
    "dist"
    "build"
    ".next"
    ".nuxt"
    "coverage"
    ".cache"
    ".pytest_cache"
    ".mypy_cache"
    "target"
    ".cargo"
    "vendor"
    ".idea"
    ".vscode"
    "*.egg-info"
)

# Build find exclusion pattern
EXCLUDE_PATTERN=""
for dir in "${IGNORE_DIRS[@]}"; do
    EXCLUDE_PATTERN="$EXCLUDE_PATTERN -name '$dir' -prune -o"
done

# Code file extensions
CODE_EXTENSIONS="ts,tsx,js,jsx,py,rs,go,java,rb,php,swift,kt,scala,c,cpp,h,hpp,cs,vue,svelte"

if $CODE_ONLY; then
    # Only show code files
    eval "find '$SEARCH_PATH' -maxdepth $MAX_DEPTH $EXCLUDE_PATTERN -type f \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' -o -name '*.py' -o -name '*.rs' -o -name '*.go' -o -name '*.java' -o -name '*.rb' -o -name '*.vue' -o -name '*.svelte' \) -print" 2>/dev/null | sort
else
    # Show full tree structure
    if command -v tree &>/dev/null; then
        IGNORE_PATTERN=$(IFS='|'; echo "${IGNORE_DIRS[*]}")
        tree -a -L "$MAX_DEPTH" -I "$IGNORE_PATTERN" --noreport "$SEARCH_PATH" 2>/dev/null
    else
        # Fallback without tree command
        eval "find '$SEARCH_PATH' -maxdepth $MAX_DEPTH $EXCLUDE_PATTERN -print" 2>/dev/null | sort | head -200
    fi
fi

if $WITH_STATS; then
    echo ""
    echo "=== File Statistics ==="
    echo "TypeScript/JavaScript: $(find "$SEARCH_PATH" -type f \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' \) 2>/dev/null | wc -l)"
    echo "Python: $(find "$SEARCH_PATH" -type f -name '*.py' 2>/dev/null | wc -l)"
    echo "Rust: $(find "$SEARCH_PATH" -type f -name '*.rs' 2>/dev/null | wc -l)"
    echo "Go: $(find "$SEARCH_PATH" -type f -name '*.go' 2>/dev/null | wc -l)"
    echo "Total code files: $(find "$SEARCH_PATH" -type f \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' -o -name '*.py' -o -name '*.rs' -o -name '*.go' \) 2>/dev/null | wc -l)"
fi
