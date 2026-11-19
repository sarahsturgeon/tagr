#!/bin/bash

USAGE="Usage: tagr.sh [major|minor|patch] [--push]"
BUMP_MODE=""
PUSH=false

for ARG in "$@"; do
  case "$ARG" in
  major | minor | patch)
    BUMP_MODE="$ARG"
    ;;
  --push)
    PUSH=true
    ;;
  *)
    echo "Error - unknown argument '$ARG'. $USAGE"
    exit 1
    ;;
  esac
done

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "Error - not a git repository"
  exit 1
fi

if [[ -n "$(git remote)" ]] && ! git fetch --tags --quiet 2>/dev/null; then
  echo "Warning - could not fetch tags from the remote"
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

NEXT_MAJOR="$PREFIX$((MAJOR + 1)).0.0"
NEXT_MINOR="$PREFIX$MAJOR.$((MINOR + 1)).0"
NEXT_PATCH="$PREFIX$MAJOR.$MINOR.$((PATCH + 1))"

case "$BUMP_MODE" in
major)
  NEW_TAG="$NEXT_MAJOR"
  ;;
minor)
  NEW_TAG="$NEXT_MINOR"
  ;;
patch)
  NEW_TAG="$NEXT_PATCH"
  ;;
*)
  echo "Current version: $VERSION"
  echo "  major -> $NEXT_MAJOR"
  echo "  minor -> $NEXT_MINOR"
  echo "  patch -> $NEXT_PATCH"
  echo "$USAGE"
  exit 0
  ;;
esac

EXISTING_TAG=$(git tag --points-at HEAD | head -n 1)
if [[ -n "$EXISTING_TAG" ]]; then
  echo "Current commit already has a tag: $EXISTING_TAG"
  exit 0
fi

echo "Last tag version '$VERSION'. New tag will be: '$NEW_TAG'"

CHANGELOG_RANGE="HEAD"
if git rev-parse --quiet --verify "refs/tags/$VERSION" >/dev/null; then
  CHANGELOG_RANGE="$VERSION..HEAD"
fi

if ! git tag -a "$NEW_TAG" --edit -F <(git log --pretty="- %s" "$CHANGELOG_RANGE"); then
  echo "Error - failed to create tag $NEW_TAG"
  exit 1
fi

echo "Tagged with $NEW_TAG"

if [[ "$PUSH" == true ]]; then
  if ! git push origin "$NEW_TAG"; then
    echo "Error - failed to push $NEW_TAG to origin"
    exit 1
  fi

  echo "Pushed $NEW_TAG to origin"
fi
