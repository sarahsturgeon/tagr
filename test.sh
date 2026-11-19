#!/bin/bash
set -e

TAGGER="$(cd "$(dirname "$0")" && pwd)/tagr.sh"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# accepts the prefilled tag message unchanged
export GIT_EDITOR=true

commit() {
  git -c commit.gpgSign=false commit -q --allow-empty -m "$1"
}

fail() {
  echo "FAIL: $1"
  exit 1
}

expect_tag() {
  local actual
  actual=$(git tag --points-at HEAD)

  if [[ "$actual" != "$1" ]]; then
    fail "expected tag '$1' on HEAD, got '$actual'"
  fi
}

expect_failure() {
  local reason="$1"
  shift

  if "$TAGGER" "$@" >/dev/null 2>&1; then
    fail "expected an error when $reason"
  fi
}

cd "$WORK"
expect_failure "run outside a git repository" patch

git init -q repo
cd repo
git config user.name test
git config user.email test@example.com
git config tag.gpgSign false

expect_failure "given an unknown argument" bogus

commit one
"$TAGGER" patch
expect_tag v0.0.1

"$TAGGER" major
expect_tag v0.0.1

commit two
"$TAGGER" minor
expect_tag v0.1.0

git checkout -q -b side
commit "higher tag that main cannot reach"
"$TAGGER" major
expect_tag v1.0.0
git checkout -q -

commit three
"$TAGGER" patch
expect_tag v1.0.1

TAG_MESSAGE=$(git tag --list v1.0.1 --format="%(contents)")
if [[ "$TAG_MESSAGE" != *"- three"* ]]; then
  fail "expected the tag message to list commits since the last tag, got '$TAG_MESSAGE'"
fi

commit four
GIT_EDITOR=false expect_failure "the tag message is aborted" patch

PREVIEW=$("$TAGGER")
expect_tag ""
if [[ "$PREVIEW" != *"patch -> v1.0.2"* ]]; then
  fail "expected the preview to offer v1.0.2, got '$PREVIEW'"
fi

git init -q --bare "$WORK/remote"
git remote add origin "$WORK/remote"
"$TAGGER" minor --push
expect_tag v1.1.0

if ! git ls-remote --tags origin | grep -q "refs/tags/v1.1.0$"; then
  fail "expected v1.1.0 to be pushed to origin"
fi

echo "All tests passed"
