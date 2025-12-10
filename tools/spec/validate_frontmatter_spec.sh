Describe 'validate-frontmatter.sh'
  ORIG_DIR="$PWD"
  SCRIPT_UNDER_TEST="$ORIG_DIR/tools/validate-frontmatter.sh"

  setup_repo() {
    TEST_REPO=$(mktemp -d)
    cd "$TEST_REPO"
    git init -q -b main
    git config user.email "test@kuma.io"
    git config user.name "Test"
    mkdir -p app/_src/docs
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

  Describe 'no new files'
    It 'passes when no new docs files'
      echo "some text" > file.txt
      When run commit_and_run
      The status should be success
      The output should include "No new docs files found"
    End

    It 'passes for non-docs directory'
      mkdir -p other
      cat > other/doc.md << 'EOF'
# Just content
EOF
      When run commit_and_run
      The status should be success
      The output should include "No new docs files found"
    End
  End

  Describe 'valid frontmatter'
    It 'passes with all required fields'
      cat > app/_src/docs/valid.md << 'EOF'
---
title: Valid Page
description: This is a valid page with all required fields
keywords:
  - test
  - valid
---

# Content
EOF
      When run commit_and_run
      The status should be success
      The output should include "All frontmatter valid"
    End

    It 'passes with 1 keyword'
      cat > app/_src/docs/valid.md << 'EOF'
---
title: Valid Page
description: This is valid
keywords:
  - single
---

# Content
EOF
      When run commit_and_run
      The status should be success
      The output should include "All frontmatter valid"
    End

    It 'passes with 3 keywords'
      cat > app/_src/docs/valid.md << 'EOF'
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
      When run commit_and_run
      The status should be success
      The output should include "All frontmatter valid"
    End

    It 'passes with keywords followed by another field'
      cat > app/_src/docs/valid.md << 'EOF'
---
title: Test
description: Test description
keywords:
  - one
  - two
author: Someone
---

# Content
EOF
      When run commit_and_run
      The status should be success
      The output should include "All frontmatter valid"
    End
  End

  Describe 'missing fields'
    It 'fails for missing title'
      cat > app/_src/docs/missing.md << 'EOF'
---
description: No title here
keywords:
  - test
---

# Content
EOF
      When run commit_and_run
      The status should be failure
      The output should include "missing 'title' field"
    End

    It 'fails for missing description'
      cat > app/_src/docs/missing.md << 'EOF'
---
title: Missing Description
keywords:
  - test
---

# Content
EOF
      When run commit_and_run
      The status should be failure
      The output should include "missing or empty 'description' field"
    End

    It 'fails for missing keywords'
      cat > app/_src/docs/missing.md << 'EOF'
---
title: Missing Keywords
description: No keywords here
---

# Content
EOF
      When run commit_and_run
      The status should be failure
      The output should include "missing 'keywords' field"
    End

    It 'fails for no frontmatter'
      cat > app/_src/docs/none.md << 'EOF'
# Just Content

No frontmatter here
EOF
      When run commit_and_run
      The status should be failure
      The output should include "no frontmatter found"
    End

    It 'fails for all fields missing'
      cat > app/_src/docs/empty.md << 'EOF'
---
layout: page
---

# Content
EOF
      When run commit_and_run
      The status should be failure
      The output should include "missing 'title' field"
      The output should include "missing or empty 'description' field"
      The output should include "missing 'keywords' field"
    End
  End

  Describe 'keyword count validation'
    It 'fails for empty keywords array'
      cat > app/_src/docs/empty-kw.md << 'EOF'
---
title: Empty Keywords
description: Keywords field exists but empty
keywords:
---

# Content
EOF
      When run commit_and_run
      The status should be failure
      The output should include "keywords must have at least 1 item"
    End

    It 'fails for too many keywords'
      cat > app/_src/docs/many-kw.md << 'EOF'
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
      When run commit_and_run
      The status should be failure
      The output should include "keywords must have at most 3 items"
    End
  End

  Describe 'path exclusions'
    It 'skips files in /generated/ directory'
      mkdir -p app/_src/docs/generated
      cat > app/_src/docs/generated/doc.md << 'EOF'
# No frontmatter
EOF
      When run commit_and_run
      The status should be success
      The output should include "No new docs files found"
    End

    It 'skips files in /raw/ directory'
      mkdir -p app/_src/docs/raw
      cat > app/_src/docs/raw/doc.md << 'EOF'
# No frontmatter
EOF
      When run commit_and_run
      The status should be success
      The output should include "No new docs files found"
    End
  End
End
