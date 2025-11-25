#!/usr/bin/env bash
set -euo pipefail

# Tests for validate-frontmatter.sh
# Runs validation logic against fixture files without git

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIXTURES_DIR="$SCRIPT_DIR/test-fixtures/frontmatter"
PASSED=0
FAILED=0

# Create fixtures directory
mkdir -p "$FIXTURES_DIR"

# Helper to run validation on a single file
validate_file() {
  local file="$1"
  local ERRORS=0

  FRONTMATTER=$(awk '/^---$/{if(++c==2)exit; next}c==1' "$file")

  if [ -z "$FRONTMATTER" ]; then
    echo "no-frontmatter"
    return
  fi

  if ! echo "$FRONTMATTER" | grep -qE '^title:'; then
    ERRORS=$((ERRORS + 1))
  fi

  if ! echo "$FRONTMATTER" | grep -qE '^description:'; then
    ERRORS=$((ERRORS + 1))
  fi

  if ! echo "$FRONTMATTER" | grep -qE '^keywords:'; then
    ERRORS=$((ERRORS + 1))
  else
    KEYWORDS_COUNT=$(echo "$FRONTMATTER" | awk '/^keywords:/{f=1;next} f && /^[a-z]/{exit} f && /^ *-/' | wc -l | tr -d ' ')
    if [ "$KEYWORDS_COUNT" -lt 1 ]; then
      ERRORS=$((ERRORS + 1))
    elif [ "$KEYWORDS_COUNT" -gt 3 ]; then
      ERRORS=$((ERRORS + 1))
    fi
  fi

  echo "$ERRORS"
}

# Test helper
test_case() {
  local name="$1"
  local expected="$2"
  local file="$3"

  result=$(validate_file "$file")
  if [ "$result" = "$expected" ]; then
    echo "✓ $name"
    PASSED=$((PASSED + 1))
  else
    echo "✗ $name (expected: $expected, got: $result)"
    FAILED=$((FAILED + 1))
  fi
}

echo "Creating test fixtures..."

# Valid file with all fields
cat > "$FIXTURES_DIR/valid.md" << 'EOF'
---
title: Valid Page
description: This is a valid page with all required fields
keywords:
  - test
  - valid
---

# Content
EOF

# Valid with 1 keyword
cat > "$FIXTURES_DIR/valid-1-keyword.md" << 'EOF'
---
title: Valid Page
description: This is valid
keywords:
  - single
---

# Content
EOF

# Valid with 3 keywords
cat > "$FIXTURES_DIR/valid-3-keywords.md" << 'EOF'
---
title: Valid Page
description: This is valid
keywords:
  - one
  - two
  - three
---

# Content
EOF

# Missing description
cat > "$FIXTURES_DIR/missing-description.md" << 'EOF'
---
title: Missing Description
keywords:
  - test
---

# Content
EOF

# Missing keywords
cat > "$FIXTURES_DIR/missing-keywords.md" << 'EOF'
---
title: Missing Keywords
description: No keywords here
---

# Content
EOF

# Missing title
cat > "$FIXTURES_DIR/missing-title.md" << 'EOF'
---
description: No title here
keywords:
  - test
---

# Content
EOF

# Too many keywords (4)
cat > "$FIXTURES_DIR/too-many-keywords.md" << 'EOF'
---
title: Too Many Keywords
description: Has 4 keywords
keywords:
  - one
  - two
  - three
  - four
---

# Content
EOF

# Empty keywords array
cat > "$FIXTURES_DIR/empty-keywords.md" << 'EOF'
---
title: Empty Keywords
description: Keywords field exists but empty
keywords:
---

# Content
EOF

# No frontmatter
cat > "$FIXTURES_DIR/no-frontmatter.md" << 'EOF'
# Just Content

No frontmatter here
EOF

# All fields missing
cat > "$FIXTURES_DIR/all-missing.md" << 'EOF'
---
layout: page
---

# Content
EOF

echo ""
echo "Running tests..."
echo ""

# Run tests
test_case "valid file with all fields" "0" "$FIXTURES_DIR/valid.md"
test_case "valid with 1 keyword" "0" "$FIXTURES_DIR/valid-1-keyword.md"
test_case "valid with 3 keywords" "0" "$FIXTURES_DIR/valid-3-keywords.md"
test_case "missing description" "1" "$FIXTURES_DIR/missing-description.md"
test_case "missing keywords" "1" "$FIXTURES_DIR/missing-keywords.md"
test_case "missing title" "1" "$FIXTURES_DIR/missing-title.md"
test_case "too many keywords (4)" "1" "$FIXTURES_DIR/too-many-keywords.md"
test_case "empty keywords array" "1" "$FIXTURES_DIR/empty-keywords.md"
test_case "no frontmatter" "no-frontmatter" "$FIXTURES_DIR/no-frontmatter.md"
test_case "all fields missing" "3" "$FIXTURES_DIR/all-missing.md"

echo ""
echo "Results: $PASSED passed, $FAILED failed"

# Cleanup
rm -rf "$FIXTURES_DIR"

if [ $FAILED -gt 0 ]; then
  exit 1
fi
