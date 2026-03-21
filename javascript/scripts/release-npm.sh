#!/bin/bash
set -e

# Check npm authentication
if ! npm whoami &>/dev/null; then
  echo "Not logged in to npm. Run 'npm login' first."
  exit 1
fi

# Check for uncommitted changes
if ! git diff --quiet; then
  echo "There are uncommitted changes. Aborting."
  exit 1
fi

# Update version
echo "Updating version in package.json..."
npm run update-version

# Install dependencies
echo "Installing dependencies..."
npm install

# Build project
echo "Building project..."
npm run build

# Add, commit, and push changes
VERSION=$(cat ../VERSION)
echo "Adding changes to git..."
git add .
echo "Committing changes (Release NPM v$VERSION)..."
git commit -m "Release NPM v$VERSION"
echo "Pushing changes..."
git push

# Publish to npm
if echo "$VERSION" | grep -qE '[-.]*(alpha|beta|rc|pre|next)'; then
  TAG=$(echo "$VERSION" | sed -E 's/.*[-.]*(alpha|beta|rc|pre|next).*/\1/')
  echo "Publishing prerelease to npm with tag '$TAG'..."
  npm publish --tag "$TAG"
else
  echo "Publishing to npm..."
  npm publish
fi

echo "Release complete!"
