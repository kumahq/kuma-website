Describe 'check-version-urls.sh'
  ORIG_DIR="$PWD"
  SCRIPT_UNDER_TEST="$ORIG_DIR/tools/check-version-urls.sh"

  setup_repo() {
    TEST_REPO=$(mktemp -d)
    cd "$TEST_REPO"
    git init -q -b main
    git config user.email "test@kuma.io"
    git config user.name "Test"
    echo "# Base" > README.md
    git add README.md
    git commit -q -m "Initial commit"
  }

  cleanup_repo() {
    cd "$ORIG_DIR"
    rm -rf "$TEST_REPO"
  }

  commit_and_run() {
    git checkout -q -b test-branch
    git add -A
    git commit -q -m "Test changes" --allow-empty
    "$SCRIPT_UNDER_TEST" main
  }

  BeforeEach 'setup_repo'
  AfterEach 'cleanup_repo'

  Describe 'files without version URLs'
    It 'passes when no markdown files changed'
      echo "some text" > file.txt
      When run commit_and_run
      The status should be success
      The output should include "No markdown files changed"
    End

    It 'passes when markdown has no version URLs'
      cat > doc.md << 'EOF'
# Documentation

See [policies](/docs/{{ page.release }}/policies/meshtimeout) for more info.
EOF
      When run commit_and_run
      The status should be success
      The output should include "No hardcoded version URLs found"
    End

    It 'passes for non-docs version path'
      cat > doc.md << 'EOF'
# Documentation

Download from /releases/2.9.1/download
EOF
      When run commit_and_run
      The status should be success
      The output should include "No hardcoded version URLs found"
    End
  End

  Describe 'hardcoded version URLs'
    It 'fails for X.Y.x URL'
      cat > doc.md << 'EOF'
# Documentation

See [policies](/docs/2.9.x/policies/meshtimeout) for more info.
EOF
      When run commit_and_run
      The status should be failure
      The output should include "hardcoded version URL"
    End

    It 'fails for X.Y.Z URL'
      cat > doc.md << 'EOF'
# Documentation

See [policies](/docs/2.9.1/policies/meshtimeout) for more info.
EOF
      When run commit_and_run
      The status should be failure
      The output should include "hardcoded version URL"
    End

    It 'fails for multiple X.Y.x in one file'
      cat > doc.md << 'EOF'
# Documentation

See [policies](/docs/2.9.x/policies/meshtimeout) for more info.
Also see [another](/docs/2.8.x/other) page.
EOF
      When run commit_and_run
      The status should be failure
      The output should include "hardcoded version URL"
    End

    It 'fails for mixed X.Y.x and X.Y.Z'
      cat > doc.md << 'EOF'
# Documentation

See [policies](/docs/2.9.x/policies/meshtimeout) for more info.
Also see [another](/docs/2.8.1/other) page.
EOF
      When run commit_and_run
      The status should be failure
      The output should include "hardcoded version URL"
    End

    It 'fails for .markdown extension'
      cat > doc.markdown << 'EOF'
# Documentation

See [policies](/docs/2.9.x/policies/meshtimeout) for more info.
EOF
      When run commit_and_run
      The status should be failure
      The output should include "hardcoded version URL"
    End
  End

  Describe 'no-version-lint suppression'
    It 'passes X.Y.x with no-version-lint comment'
      cat > doc.md << 'EOF'
# Documentation

See [policies](/docs/2.9.x/policies/meshtimeout) for more info. <!-- no-version-lint -->
EOF
      When run commit_and_run
      The status should be success
      The output should include "No hardcoded version URLs found"
    End

    It 'passes X.Y.Z with no-version-lint comment'
      cat > doc.md << 'EOF'
# Documentation

See [old docs](/docs/2.9.1/policies/meshtimeout) <!-- no-version-lint -->
EOF
      When run commit_and_run
      The status should be success
      The output should include "No hardcoded version URLs found"
    End
  End

  Describe 'path exclusions'
    It 'passes X.Y.Z in /assets/images/ path'
      cat > doc.md << 'EOF'
# Documentation

![screenshot](/assets/images/docs/2.9.1/screenshot.png)
EOF
      When run commit_and_run
      The status should be success
      The output should include "No hardcoded version URLs found"
    End

    It 'skips files in /generated/ directory'
      mkdir -p app/assets/2.9.x/generated
      cat > app/assets/2.9.x/generated/doc.md << 'EOF'
# Generated Documentation

See [policies](/docs/2.9.x/policies/meshtimeout) for more info.
EOF
      When run commit_and_run
      The status should be success
      The output should include "No markdown files changed"
    End

    It 'skips files in /raw/ directory'
      mkdir -p app/assets/2.9.x/raw
      cat > app/assets/2.9.x/raw/doc.md << 'EOF'
# Raw Documentation

See [policies](/docs/2.9.x/policies/meshtimeout) for more info.
EOF
      When run commit_and_run
      The status should be success
      The output should include "No markdown files changed"
    End
  End
End
