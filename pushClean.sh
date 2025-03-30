#!/bin/bash

# Stop on error
set -e

NEW_BRANCH_NAME="main"

if [[ -z "$NEW_BRANCH_NAME" ]]; then
  echo "❌ Error: NEW_BRANCH_NAME is empty. Please set it before running the script."
  exit 1
fi

# Cleanup: delete temp-main if it already exists
if git show-ref --quiet refs/heads/temp-$NEW_BRANCH_NAME; then
  echo "🧹 Deleting existing 'temp-$NEW_BRANCH_NAME' branch..."
  git branch -D temp-$NEW_BRANCH_NAME
fi

# Step 1: Create orphan branch
git checkout --orphan temp-$NEW_BRANCH_NAME

# Step 2: Add all files and commit
git add -A
git commit -m "Initial commit"

# Step 3: Delete existing main if it exists and we're not on it
if git show-ref --quiet refs/heads/$NEW_BRANCH_NAME; then
  CURRENT_BRANCH=$(git branch --show-current)
  if [[ "$CURRENT_BRANCH" != "$NEW_BRANCH_NAME" ]]; then
    echo "🗑️  Deleting existing '$NEW_BRANCH_NAME' branch..."
    git branch -D "$NEW_BRANCH_NAME"
  else
    echo "❌ You're currently on the '$NEW_BRANCH_NAME' branch. Cannot delete it."
    echo "➡️  Please switch to another branch and try again."
    exit 1
  fi
fi

# Step 4: Rename orphan branch
git branch -m "$NEW_BRANCH_NAME"

# Prompt for GitHub repo URL
read -p "Enter your GitHub repository URL (e.g. https://github.com/user/repo.git): " GITHUB_REPO_URL

# Confirm we're inside a Git repo
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "❌ Error: This is not a Git repository."
  exit 1
fi

echo ""
echo "⚠️  This script will:"
echo "  - Create a new orphan branch with no history"
echo "  - Stage and commit all current files as a single 'Initial commit'"
echo "  - Delete your existing 'main' branch if it exists"
echo "  - Rename the orphan branch to 'main'"
echo "  - Overwrite the remote history on GitHub"
echo ""
echo "❗ This will permanently erase all Git history on GitHub."
echo ""

read -p "Do you want to continue? (yes/no): " CONFIRM

if [[ "$CONFIRM" != "yes" ]]; then
  echo "Aborted."
  exit 0
fi

# Step 5: Set remote
git remote remove origin 2>/dev/null || true
git remote add origin "$GITHUB_REPO_URL"

# Step 6: Force push as the new main
git push -f origin "$NEW_BRANCH_NAME"

echo ""
echo "✅ Done! Clean repo pushed to $GITHUB_REPO_URL with a single commit."
