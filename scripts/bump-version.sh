#!/usr/bin/env bash
# Bump semver in VERSION, update CHANGELOG.md, commit, and tag.
#
# Usage:
#   ./scripts/bump-version.sh major              # 1.2.3 → 2.0.0
#   ./scripts/bump-version.sh minor              # 1.2.3 → 1.3.0
#   ./scripts/bump-version.sh patch              # 1.2.3 → 1.2.4
#   ./scripts/bump-version.sh set 0.1.0-beta.1   # set any explicit version

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION_FILE="$REPO_ROOT/VERSION"
CHANGELOG_FILE="$REPO_ROOT/CHANGELOG.md"

usage() {
  echo "Usage: $0 [major|minor|patch|set <version>]" >&2
  echo "  Examples:" >&2
  echo "    $0 patch                  # 1.0.0 → 1.0.1" >&2
  echo "    $0 minor                  # 1.0.0 → 1.1.0" >&2
  echo "    $0 major                  # 1.0.0 → 2.0.0" >&2
  echo "    $0 set 0.1.0-beta.1       # set an explicit pre-release version" >&2
  echo "    $0 set 1.0.0              # set an explicit stable version" >&2
  exit 1
}

[[ $# -lt 1 ]] && usage

COMPONENT="$1"

# ── Explicit set mode ─────────────────────────────────────────────────────────
if [[ "$COMPONENT" == "set" ]]; then
  [[ $# -ne 2 ]] && { echo "ERROR: 'set' requires a version argument" >&2; usage; }
  NEW_VERSION="$2"
  # Validate: semver with optional pre-release (e.g. 1.0.0, 0.1.0-beta.1, 1.2.3-rc.2)
  if [[ ! "$NEW_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$ ]]; then
    echo "ERROR: '$NEW_VERSION' is not valid semver (e.g. 1.0.0 or 0.1.0-beta.1)" >&2
    exit 1
  fi
  CURRENT="$(tr -d '[:space:]' < "$VERSION_FILE")"
  echo "▶ Setting $CURRENT → $NEW_VERSION"

# ── Increment mode ────────────────────────────────────────────────────────────
else
  [[ $# -ne 1 ]] && usage
  [[ "$COMPONENT" =~ ^(major|minor|patch)$ ]] || usage

  CURRENT="$(tr -d '[:space:]' < "$VERSION_FILE")"
  # Strip any pre-release suffix before incrementing
  BASE="${CURRENT%%-*}"
  if [[ ! "$BASE" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
    echo "ERROR: VERSION file contains invalid semver: '$CURRENT'" >&2
    exit 1
  fi

  MAJOR="${BASH_REMATCH[1]}"
  MINOR="${BASH_REMATCH[2]}"
  PATCH="${BASH_REMATCH[3]}"

  case "$COMPONENT" in
    major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
    minor) MINOR=$((MINOR + 1)); PATCH=0 ;;
    patch) PATCH=$((PATCH + 1)) ;;
  esac

  NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"
  echo "▶ Bumping $CURRENT → $NEW_VERSION"
fi

TODAY="$(date +%Y-%m-%d)"

# Update VERSION
echo "$NEW_VERSION" > "$VERSION_FILE"

# Update CHANGELOG: replace '## [Unreleased]' with new release entry,
# insert fresh '[Unreleased]' block above it.
if ! grep -q '## \[Unreleased\]' "$CHANGELOG_FILE"; then
  echo "ERROR: CHANGELOG.md is missing '## [Unreleased]' section." >&2
  exit 1
fi

awk -v ver="$NEW_VERSION" -v date="$TODAY" '
  /^## \[Unreleased\]$/ {
    print "## [Unreleased]"
    print ""
    print "## [" ver "] - " date
    next
  }
  { print }
' "$CHANGELOG_FILE" > "${CHANGELOG_FILE}.tmp"

mv "${CHANGELOG_FILE}.tmp" "$CHANGELOG_FILE"

echo "▶ Updated CHANGELOG.md"

# Stage and commit
git -C "$REPO_ROOT" add "$VERSION_FILE" "$CHANGELOG_FILE"
git -C "$REPO_ROOT" commit -m "chore: release v${NEW_VERSION}"

# Annotated tag
git -C "$REPO_ROOT" tag -a "v${NEW_VERSION}" -m "Release v${NEW_VERSION}"

echo "✓ Committed and tagged v${NEW_VERSION}"
echo ""
echo "Next steps:"
echo "  git push && git push --tags"
