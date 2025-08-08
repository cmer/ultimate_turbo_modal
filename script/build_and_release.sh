#!/bin/bash
set -e
cd $(dirname $0)/..

if [ "$1" == "--help" ]; then
  echo "Usage: $0 [--skip-gem] [--skip-js]"
  echo ""
  echo "Options:"
  echo "  --skip-gem   Skip building and releasing the gem."
  echo "  --skip-js    Skip building and releasing the JavaScript."
  echo "  --help       Show this help message."
  exit 0
fi

# Check for uncommitted changes
if ! git diff --quiet; then
  echo "There are uncommitted changes. Aborting."
  exit 1
fi


if [ "$1" != "--skip-gem" ]; then
  echo "Building and releasing gem..."
  bundle exec rake build

  # Update demo app with latest gem and JavaScript
  echo "Updating demo app with latest code..."
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  DEMO_APP_DIR="$SCRIPT_DIR/../demo-app"

  # Build JavaScript package first
  echo "Building ultimate_turbo_modal JavaScript package..."
  (cd "$SCRIPT_DIR/../javascript" && yarn build)

  # Update demo app dependencies
  echo "Installing latest ultimate_turbo_modal in demo app..."
  (cd "$DEMO_APP_DIR" && bundle install)
  (cd "$DEMO_APP_DIR" && yarn install --force)

  # Check if Gemfile.lock or demo-app files are git dirty
  if ! git diff --quiet Gemfile.lock demo-app/Gemfile.lock demo-app/yarn.lock; then
    echo "Lock files are dirty. Adding, committing, and pushing."
    git add Gemfile.lock demo-app/Gemfile.lock demo-app/yarn.lock
    git commit -m "Update lock files for demo app"
  fi

  bundle exec rake build
  bundle exec rake release
else
  echo "Skipping gem build and release..."
fi

if [ "$1" != "--skip-js" ]; then
  echo "Building JavaScript..."
  cd javascript
  ./scripts/release-npm.sh
else
  echo "Skipping JavaScript build..."
fi

echo "Done!"
