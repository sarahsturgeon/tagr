#!/bin/bash
set -e

TAGGER="$(cd "$(dirname "$0")" && pwd)/tagger.sh"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# shellcheck disable=SC2016
printf '#!/bin/sh\necho "release" > "$1"\n' > "$WORK/editor"
chmod +x "$WORK/editor"
export GIT_EDITOR="$WORK/editor"

commit() {
  git -c commit.gpgSign=false commit -q --allow-empty -m "$1"
}

expect_tag() {
  local actual
  actual=$(git tag --points-at HEAD)

  if [[ "$actual" != "$1" ]]; then
    echo "FAIL: expected tag '$1' on HEAD, got '$actual'"
    exit 1
  fi
}

expect_failure() {
  if "$TAGGER" patch >/dev/null 2>&1; then
    echo "FAIL: expected an error when $1"
    exit 1
  fi
}

cd "$WORK"
expect_failure "run outside a git repository"

git init -q repo
cd repo
git config user.name test
git config user.email test@example.com
git config tag.gpgSign false

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

commit four
export GIT_EDITOR=false
expect_failure "the tag message is aborted"

echo "All tests passed"
