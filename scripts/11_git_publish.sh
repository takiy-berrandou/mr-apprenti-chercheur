#!/usr/bin/env bash
set -euo pipefail

REPO_NAME="mr-apprenti-chercheur"

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI 'gh' not found in current environment."
  echo "Activate your gh environment first, e.g.:"
  echo "conda activate gh-cli"
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "GitHub CLI is not authenticated."
  echo "Run: gh auth login"
  exit 1
fi

# Initialize git if needed
if [ ! -d ".git" ]; then
  git init
fi

# Configure identity if not already configured
git config user.name "Takiy Berrandou" || true
git config user.email "$(gh api user --jq .email 2>/dev/null || echo 'takiy@example.com')" || true

# Add useful files only
git add README.md .gitignore config scripts notebooks data/harmonised

# First commit, if needed
git commit -m "Initial educational MR project" || true

# Now branch exists, so renaming works
git branch -M main

# Create or connect GitHub repo
if gh repo view "${REPO_NAME}" >/dev/null 2>&1; then
  echo "GitHub repo exists: ${REPO_NAME}"

  if ! git remote get-url origin >/dev/null 2>&1; then
    GITHUB_USER=$(gh api user --jq .login)
    git remote add origin "https://github.com/${GITHUB_USER}/${REPO_NAME}.git"
  fi

  git push -u origin main
else
  gh repo create "${REPO_NAME}" --public --source=. --remote=origin --push
fi
