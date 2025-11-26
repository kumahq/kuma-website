#!/usr/bin/env bash
set -euo pipefail

# Tests for check-version-urls.sh
# Creates temp git repos to test version URL detection

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_UNDER_TEST="$SCRIPT_DIR/check-version-urls.sh"
TEST_DIR=$(mktemp -d)
PASSED=0
FAILED=0

cleanup() {
  rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Initialize a git repo with a base commit
setup_repo() {
  local repo="$1"
  mkdir -p "$repo"
  cd "$repo"
  git init -q -b main
  git config user.email "test@kuma.io"
  git config user.name "Test"
  echo "# Base" > README.md
  git add README.md
  git commit -q -m "Initial commit"
}

# Test helper
test_case() {
  local name="$1"
  local expected="$2"
  local setup_fn="$3"

  local repo="$TEST_DIR/repo_$RANDOM"
  setup_repo "$repo"

  # Run setup function to create test files
  $setup_fn

  # Create branch and commit changes
  git checkout -q -b test-branch
  git add -A
  git commit -q -m "Test changes" --allow-empty

  # Run the script
  set +e
  output=$("$SCRIPT_UNDER_TEST" main 2>&1)
  result=$?
  set -e

  cd "$SCRIPT_DIR"

  if [ "$result" -eq "$expected" ]; then
    echo "✓ $name"
    PASSED=$((PASSED + 1))
  else
    echo "✗ $name (expected: $expected, got: $result)"
    echo "  Output: $output"
    FAILED=$((FAILED + 1))
  fi
}

# --- Setup functions for each test case ---

# No markdown files changed
setup_no_md_files() {
  echo "some text" > file.txt
}

# Markdown file without version URLs
setup_clean_md() {
  cat > doc.md << 'EOF'
# Documentation

See [policies](/docs/{{ page.release }}/policies/meshtimeout) for more info.
EOF
}

# Hardcoded X.Y.x URL (should fail)
setup_hardcoded_minor() {
  cat > doc.md << 'EOF'
# Documentation

See [policies](/docs/2.9.x/policies/meshtimeout) for more info.
EOF
}

# Hardcoded X.Y.Z URL (should fail)
setup_hardcoded_patch() {
  cat > doc.md << 'EOF'
# Documentation

See [policies](/docs/2.9.1/policies/meshtimeout) for more info.
EOF
}

# X.Y.x URL with no-version-lint comment (should pass)
setup_with_lint_comment_minor() {
  cat > doc.md << 'EOF'
# Documentation

See [policies](/docs/2.9.x/policies/meshtimeout) for more info. <!-- no-version-lint -->
EOF
}

# X.Y.Z URL with no-version-lint comment (should pass)
setup_with_lint_comment_patch() {
  cat > doc.md << 'EOF'
# Documentation

See [old docs](/docs/2.9.1/policies/meshtimeout) <!-- no-version-lint -->
EOF
}

# X.Y.Z in image path (should pass)
setup_image_path() {
  cat > doc.md << 'EOF'
# Documentation

![screenshot](/assets/images/docs/2.9.1/screenshot.png)
EOF
}

# File in /generated/ directory (should be skipped)
setup_generated_dir() {
  mkdir -p app/assets/2.9.x/generated
  cat > app/assets/2.9.x/generated/doc.md << 'EOF'
# Generated Documentation

See [policies](/docs/2.9.x/policies/meshtimeout) for more info.
EOF
}

# File in /raw/ directory (should be skipped)
setup_raw_dir() {
  mkdir -p app/assets/2.9.x/raw
  cat > app/assets/2.9.x/raw/doc.md << 'EOF'
# Raw Documentation

See [policies](/docs/2.9.x/policies/meshtimeout) for more info.
EOF
}

# Multiple X.Y.x errors in one file
setup_multiple_errors() {
  cat > doc.md << 'EOF'
# Documentation

See [policies](/docs/2.9.x/policies/meshtimeout) for more info.
Also see [another](/docs/2.8.x/other) page.
EOF
}

# Mixed X.Y.x and X.Y.Z errors
setup_mixed_errors() {
  cat > doc.md << 'EOF'
# Documentation

See [policies](/docs/2.9.x/policies/meshtimeout) for more info.
Also see [another](/docs/2.8.1/other) page.
EOF
}

# .markdown extension
setup_markdown_ext() {
  cat > doc.markdown << 'EOF'
# Documentation

See [policies](/docs/2.9.x/policies/meshtimeout) for more info.
EOF
}

# Non-docs version path (should pass)
setup_non_docs_path() {
  cat > doc.md << 'EOF'
# Documentation

Download from /releases/2.9.1/download
EOF
}

# --- Run tests ---

echo "Running tests..."
echo ""

test_case "no markdown files changed" 0 setup_no_md_files
test_case "clean markdown file" 0 setup_clean_md
test_case "hardcoded X.Y.x URL fails" 1 setup_hardcoded_minor
test_case "hardcoded X.Y.Z URL fails" 1 setup_hardcoded_patch
test_case "X.Y.x with no-version-lint passes" 0 setup_with_lint_comment_minor
test_case "X.Y.Z with no-version-lint passes" 0 setup_with_lint_comment_patch
test_case "X.Y.Z in /assets/images/ path passes" 0 setup_image_path
test_case "files in /generated/ skipped" 0 setup_generated_dir
test_case "files in /raw/ skipped" 0 setup_raw_dir
test_case "multiple X.Y.x in one file" 1 setup_multiple_errors
test_case "mixed X.Y.x and X.Y.Z errors" 1 setup_mixed_errors
test_case ".markdown extension checked" 1 setup_markdown_ext
test_case "non-docs version path passes" 0 setup_non_docs_path

echo ""
echo "Results: $PASSED passed, $FAILED failed"

if [ $FAILED -gt 0 ]; then
  exit 1
fi
