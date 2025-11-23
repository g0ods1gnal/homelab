#!/bin/bash
# Check for potentially exposed secrets in the codebase

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "🔍 Scanning for potential secret exposures..."
echo ""

cd "$PROJECT_ROOT"

# Patterns that might indicate exposed secrets
PATTERNS=(
    "password.*=.*['\"].*['\"]"
    "api[_-]?key.*=.*['\"].*['\"]"
    "secret.*=.*['\"].*['\"]"
    "token.*=.*['\"].*['\"]"
)

ISSUES_FOUND=0

# Check all YAML files except vault.yml
echo "Checking YAML files (excluding vault.yml)..."
for pattern in "${PATTERNS[@]}"; do
    MATCHES=$(find ansible -name "*.yml" -not -name "vault.yml" -type f -exec grep -iHn "$pattern" {} \; 2>/dev/null || true)
    if [ -n "$MATCHES" ]; then
        echo "⚠️  Potential secret exposure found:"
        echo "$MATCHES"
        echo ""
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    fi
done

# Check for hardcoded IPs/credentials in templates
echo "Checking Jinja2 templates..."
HARDCODED=$(find ansible/roles -name "*.j2" -type f -exec grep -iHn "password.*:.*['\"].*['\"]" {} \; 2>/dev/null || true)
if [ -n "$HARDCODED" ]; then
    echo "⚠️  Hardcoded values in templates:"
    echo "$HARDCODED"
    echo ""
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# Check if .vault_pass is in .gitignore
if ! grep -q ".vault_pass" .gitignore; then
    echo "❌ .vault_pass is NOT in .gitignore!"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $ISSUES_FOUND -eq 0 ]; then
    echo "✅ No potential secret exposures found"
else
    echo "⚠️  Found $ISSUES_FOUND potential issue(s)"
    echo ""
    echo "Review the findings above and ensure:"
    echo "  1. No passwords in plain text (use vault variables)"
    echo "  2. No hardcoded secrets in templates"
    echo "  3. .vault_pass is in .gitignore"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
