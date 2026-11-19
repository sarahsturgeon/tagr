#!/bin/bash

case "$1" in
"major")
  BUMP_MODE="major"
  ;;
"minor")
  BUMP_MODE="minor"
  ;;
"patch")
  BUMP_MODE="patch"
  ;;
*)
  echo "Error - no mode given. Please give major/minor/patch"
  exit 1
  ;;
esac

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "Error - not a git repository"
  exit 1
fi

EXISTING_TAG=$(git tag --points-at HEAD | head -n 1)
if [[ -n "$EXISTING_TAG" ]]; then
  echo "Current commit already has a tag: $EXISTING_TAG"
  exit 0
fi

# Highest version tag, preferring the v prefix (and defaulting to it)
VERSION=$(git tag --list "v[0-9]*" --sort=-v:refname | head -n 1)
VERSION=${VERSION:-$(git tag --list "[0-9]*" --sort=-v:refname | head -n 1)}
VERSION=${VERSION:-"v0.0.0"}

PREFIX=""
if [[ "$VERSION" == v* ]]; then
  PREFIX="v"
fi

CLEANED_VERSION=${VERSION#"$PREFIX"}

MAJOR="${CLEANED_VERSION%%.*}"
CLEANED_VERSION="${CLEANED_VERSION#*.}"
MINOR="${CLEANED_VERSION%%.*}"
CLEANED_VERSION="${CLEANED_VERSION#*.}"
PATCH="${CLEANED_VERSION%%.*}"
CLEANED_VERSION="${CLEANED_VERSION#*.}"

case $BUMP_MODE in
"major")
  MAJOR=$((MAJOR + 1))
  MINOR=0
  PATCH=0
  ;;
"minor")
  MINOR=$((MINOR + 1))
  PATCH=0
  ;;
"patch")
  PATCH=$((PATCH + 1))
  ;;
esac

# Create new tag
NEW_TAG="$PREFIX$MAJOR.$MINOR.$PATCH"
echo "Last tag version '$VERSION'. New tag will be: '$NEW_TAG'"

if ! git tag -a "$NEW_TAG"; then
  echo "Error - failed to create tag $NEW_TAG"
  exit 1
fi

echo "Tagged with $NEW_TAG"
