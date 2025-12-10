#!/usr/bin/env bash
set -euo pipefail

# Check for hardcoded version URLs in markdown files
# Usage: ./check-version-urls.sh [base-branch]
# Example: ./check-version-urls.sh origin/master
# Or: BASE_BRANCH=origin/main ./check-version-urls.sh

BASE_BRANCH="${1:-${BASE_BRANCH:-origin/master}}"

echo "Checking for hardcoded version URLs..."

# Get changed markdown files from current branch
FILES_FOUND=0
ERRORS=0

while IFS= read -r file; do
  FILES_FOUND=1
  # Check for /docs/X.Y.x/ pattern, excluding lines with no-version-lint comment
  MATCHES=$(grep -nE '/docs/[0-9]+\.[0-9]+\.x/' "$file" | grep -v 'no-version-lint' || true)
  if [ -n "$MATCHES" ]; then
    echo "$MATCHES"
    echo "ERROR: $file contains hardcoded version URL (X.Y.x format)"
    echo "  Use page.release variable instead"
    echo "  Add <!-- no-version-lint --> comment to suppress this warning"
    ERRORS=$((ERRORS + 1))
  fi

  # Check for /docs/X.Y.Z/ pattern, excluding lines with no-version-lint comment or image paths
  MATCHES=$(grep -nE '/docs/[0-9]+\.[0-9]+\.[0-9]+/' "$file" | grep -v 'no-version-lint' | grep -v '/assets/images/' || true)
  if [ -n "$MATCHES" ]; then
    echo "$MATCHES"
    echo "ERROR: $file contains hardcoded version URL (X.Y.Z format)"
    echo "  Use page.release variable instead"
    echo "  Add <!-- no-version-lint --> comment to suppress this warning"
    ERRORS=$((ERRORS + 1))
  fi
done < <((git diff --name-only --diff-filter=d "${BASE_BRANCH}...HEAD"; \
  git diff --name-only --diff-filter=d; \
  git diff --name-only --cached --diff-filter=d) | \
  sort -u | \
  grep -E '\.(md|markdown)$' | \
  grep -v '/generated/' | \
  grep -v '/raw/' || true)

if [ $FILES_FOUND -eq 0 ]; then
  echo "No markdown files changed"
  exit 0
fi

if [ $ERRORS -gt 0 ]; then
  echo ""
  echo "Found $ERRORS file(s) with hardcoded version URLs"
  exit 1
fi

echo "No hardcoded version URLs found"
