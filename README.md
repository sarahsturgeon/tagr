# tagr

[![test](https://github.com/sarahsturgeon/tagr/actions/workflows/test.yml/badge.svg)](https://github.com/sarahsturgeon/tagr/actions/workflows/test.yml)

Easy git tagging! `tagr.sh` finds the highest semver tag in the repo, bumps it, and creates an annotated tag on the current commit.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/sarahsturgeon/tagr/main/tagr.sh -o ~/.local/bin/tagr.sh
chmod +x ~/.local/bin/tagr.sh
```

## Usage

```sh
tagr.sh                # show the current version and the possible next versions
tagr.sh patch          # v1.2.3 -> v1.2.4
tagr.sh minor          # v1.2.3 -> v1.3.0
tagr.sh major          # v1.2.3 -> v2.0.0
tagr.sh minor --push   # tag, then push the tag to origin
```

The editor opens with a list of the commits since the last version tag as the tag message. Delete every line to abort.

A repo with no version tags starts from `v0.0.0`. The `v` prefix is kept when the existing tags use it and omitted when they do not.

## Signing

Tags are signed when git is configured to sign them:

```sh
git config --global tag.gpgSign true
```

## Development

```sh
shellcheck tagr.sh test.sh
./test.sh
```
