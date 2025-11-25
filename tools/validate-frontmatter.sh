#!/usr/bin/env bash
set -euo pipefail

# Validate frontmatter in new documentation files
# Checks for required fields: title, description, keywords (1-3 items)
# Usage: ./validate-frontmatter.sh [base-branch]

BASE_BRANCH="${1:-${BASE_BRANCH:-origin/master}}"

echo "Validating frontmatter in new docs files..."

FILES_FOUND=0
ERRORS=0

# Get only NEW (added) markdown files in app/_src/
while IFS= read -r file; do
  # Skip if no files
  [ -z "$file" ] && continue

  FILES_FOUND=1
  FILE_ERRORS=0

  # Extract frontmatter (between first two ---)
  FRONTMATTER=$(awk '/^---$/{if(++c==2)exit; next}c==1' "$file")

  if [ -z "$FRONTMATTER" ]; then
    echo "ERROR: $file - no frontmatter found"
    ERRORS=$((ERRORS + 1))
    continue
  fi

  # Check for title
  if ! echo "$FRONTMATTER" | grep -qE '^title:'; then
    echo "ERROR: $file - missing 'title' field"
    FILE_ERRORS=$((FILE_ERRORS + 1))
  fi

  # Check for description
  if ! echo "$FRONTMATTER" | grep -qE '^description:'; then
    echo "ERROR: $file - missing 'description' field"
    FILE_ERRORS=$((FILE_ERRORS + 1))
  fi

  # Check for keywords
  if ! echo "$FRONTMATTER" | grep -qE '^keywords:'; then
    echo "ERROR: $file - missing 'keywords' field"
    FILE_ERRORS=$((FILE_ERRORS + 1))
  else
    # Count keywords (lines starting with "  - " after "keywords:")
    KEYWORDS_SECTION=$(echo "$FRONTMATTER" | awk '/^keywords:/{f=1;next} f && /^[a-z]/{exit} f && /^ *-/' | wc -l | tr -d ' ')

    if [ "$KEYWORDS_SECTION" -lt 1 ]; then
      echo "ERROR: $file - keywords must have at least 1 item"
      FILE_ERRORS=$((FILE_ERRORS + 1))
    elif [ "$KEYWORDS_SECTION" -gt 3 ]; then
      echo "ERROR: $file - keywords must have at most 3 items (found $KEYWORDS_SECTION)"
      FILE_ERRORS=$((FILE_ERRORS + 1))
    fi
  fi

  if [ $FILE_ERRORS -gt 0 ]; then
    ERRORS=$((ERRORS + FILE_ERRORS))
  fi

done < <(git diff --name-only --diff-filter=A "${BASE_BRANCH}...HEAD" 2>/dev/null | \
  grep -E '^app/_src/.*\.(md|markdown)$' | \
  grep -v '/generated/' | \
  grep -v '/raw/' || true)

if [ $FILES_FOUND -eq 0 ]; then
  echo "No new docs files found"
  exit 0
fi

if [ $ERRORS -gt 0 ]; then
  echo ""
  echo "Found $ERRORS frontmatter error(s)"
  echo ""
  echo "Required frontmatter format:"
  echo "---"
  echo "title: Page Title"
  echo "description: 1-2 sentence description for SEO"
  echo "keywords:"
  echo "  - keyword1"
  echo "  - keyword2"
  echo "---"
  exit 1
fi

echo "All frontmatter valid"
