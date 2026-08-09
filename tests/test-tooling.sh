#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/skills-tooling-test.XXXXXX")"
TEST_ROOT="$(cd "$TEST_ROOT" && pwd -P)"
TEST_PARENT="$(cd "$(dirname "$TEST_ROOT")" && pwd -P)"

cleanup() {
  case "$TEST_ROOT" in
    "$TEST_PARENT"/skills-tooling-test.*) rm -rf -- "$TEST_ROOT" ;;
    *) echo "Refusing to clean unexpected test path: $TEST_ROOT" >&2 ;;
  esac
}
trap cleanup EXIT

assert_link_target() {
  local path="$1" expected="$2" actual
  [ -L "$path" ] || { echo "Expected symlink: $path" >&2; exit 1; }
  actual="$(readlink "$path")"
  [ "$actual" = "$expected" ] || {
    echo "Unexpected target for $path: $actual (expected $expected)" >&2
    exit 1
  }
}

write_skill() {
  local root="$1" name="$2"
  mkdir -p "$root/skills/$name"
  cat > "$root/skills/$name/SKILL.md" <<EOF
---
name: $name
description: Test skill used only by the tooling regression suite.
---

Test instructions.
EOF
}

SOURCE_A="$TEST_ROOT/source-a"
SOURCE_B="$TEST_ROOT/source-b"
TEST_HOME="$TEST_ROOT/home"
mkdir -p "$SOURCE_A" "$TEST_HOME"
cp "$REPO_ROOT/install.sh" "$SOURCE_A/install.sh"
write_skill "$SOURCE_A" example
write_skill "$SOURCE_A" project-example
printf 'example global\nproject-example project\n' > "$SOURCE_A/skills.manifest"

HOME="$TEST_HOME" /bin/bash "$SOURCE_A/install.sh" --source-root "$SOURCE_A" >/dev/null
assert_link_target "$TEST_HOME/.claude/skills/example" "$SOURCE_A/skills/example"
assert_link_target "$TEST_HOME/.codex/skills/example" "$SOURCE_A/skills/example"
[ -f "$TEST_HOME/.claude/.personal-skills-owned/skills/example" ]
[ -f "$TEST_HOME/.codex/.personal-skills-owned/skills/example" ]
[ ! -L "$TEST_HOME/.claude/skills/project-example" ]
[ ! -L "$TEST_HOME/.codex/skills/project-example" ]

unlink "$TEST_HOME/.claude/.personal-skills-owned/skills/example"
rmdir "$TEST_HOME/.claude/.personal-skills-owned/skills"
rmdir "$TEST_HOME/.claude/.personal-skills-owned"
mv "$SOURCE_A" "$SOURCE_B"
if HOME="$TEST_HOME" /bin/bash "$SOURCE_B/install.sh" --source-root "$SOURCE_B" >"$TEST_ROOT/unmarked-relocation.out" 2>&1; then
  echo "Installer unexpectedly adopted an unmarked broken link" >&2
  exit 1
fi
grep -q 'refusing to replace non-personal link' "$TEST_ROOT/unmarked-relocation.out"
HOME="$TEST_HOME" /bin/bash "$SOURCE_B/install.sh" --repair-broken-links --source-root "$SOURCE_B" >/dev/null
assert_link_target "$TEST_HOME/.claude/skills/example" "$SOURCE_B/skills/example"
assert_link_target "$TEST_HOME/.codex/skills/example" "$SOURCE_B/skills/example"

PROJECT_ROOT="$TEST_ROOT/project"
mkdir -p "$PROJECT_ROOT"
HOME="$TEST_HOME" /bin/bash "$SOURCE_B/install.sh" --project "$PROJECT_ROOT" project-example --source-root "$SOURCE_B" >/dev/null
assert_link_target "$PROJECT_ROOT/.agents/skills/project-example" "$SOURCE_B/skills/project-example"
HOME="$TEST_HOME" /bin/bash "$SOURCE_B/install.sh" --uninstall --project "$PROJECT_ROOT" project-example --source-root "$SOURCE_B" >/dev/null
[ ! -L "$PROJECT_ROOT/.agents/skills/project-example" ]

HOME="$TEST_HOME" /bin/bash "$SOURCE_B/install.sh" --uninstall --source-root "$SOURCE_B" >/dev/null
[ ! -L "$TEST_HOME/.claude/skills/example" ]
[ ! -L "$TEST_HOME/.codex/skills/example" ]
[ ! -e "$TEST_HOME/.claude/.personal-skills-owned" ]
[ ! -e "$TEST_HOME/.codex/.personal-skills-owned" ]

EXTERNAL_ROOT="$TEST_ROOT/external"
mkdir -p "$EXTERNAL_ROOT/skills/example"
printf 'example global\n' > "$EXTERNAL_ROOT/skills.manifest"

mkdir -p "$EXTERNAL_ROOT/marker-state"
ln -s "$EXTERNAL_ROOT/marker-state" "$TEST_HOME/.claude/.personal-skills-owned"
if HOME="$TEST_HOME" /bin/bash "$SOURCE_B/install.sh" --source-root "$SOURCE_B" >"$TEST_ROOT/unsafe-marker.out" 2>&1; then
  echo "Installer unexpectedly accepted a symlinked marker directory" >&2
  exit 1
fi
grep -q 'unsafe ownership marker directory' "$TEST_ROOT/unsafe-marker.out"
[ ! -L "$TEST_HOME/.claude/skills/example" ]
unlink "$TEST_HOME/.claude/.personal-skills-owned"

ln -s "$EXTERNAL_ROOT/skills/example" "$TEST_HOME/.claude/skills/example"
if HOME="$TEST_HOME" /bin/bash "$SOURCE_B/install.sh" --source-root "$SOURCE_B" >"$TEST_ROOT/non-personal.out" 2>&1; then
  echo "Installer unexpectedly replaced a non-personal skill link" >&2
  exit 1
fi
grep -q 'refusing to replace non-personal link' "$TEST_ROOT/non-personal.out"
assert_link_target "$TEST_HOME/.claude/skills/example" "$EXTERNAL_ROOT/skills/example"
unlink "$TEST_HOME/.claude/skills/example"

ln -s "$EXTERNAL_ROOT/missing/skills/example" "$TEST_HOME/.claude/skills/example"
if HOME="$TEST_HOME" /bin/bash "$SOURCE_B/install.sh" --source-root "$SOURCE_B" >"$TEST_ROOT/non-personal-broken.out" 2>&1; then
  echo "Installer unexpectedly replaced a broken non-personal skill link" >&2
  exit 1
fi
grep -q 'refusing to replace non-personal link' "$TEST_ROOT/non-personal-broken.out"
assert_link_target "$TEST_HOME/.claude/skills/example" "$EXTERNAL_ROOT/missing/skills/example"
unlink "$TEST_HOME/.claude/skills/example"

write_skill "$SOURCE_B" orphan
if HOME="$TEST_HOME" /bin/bash "$SOURCE_B/install.sh" --dry-run --source-root "$SOURCE_B" >"$TEST_ROOT/parity.out" 2>&1; then
  echo "Manifest parity check unexpectedly accepted an unlisted skill" >&2
  exit 1
fi
grep -q 'source skill missing from manifest: orphan' "$TEST_ROOT/parity.out"

IMPORT_REPO="$TEST_ROOT/import-repo"
IMPORT_HOME="$TEST_ROOT/import-home"
mkdir -p "$IMPORT_REPO/skills" "$IMPORT_HOME/.agents/skills/linked-skill"
cp "$REPO_ROOT/import.sh" "$IMPORT_REPO/import.sh"
cat > "$IMPORT_HOME/.agents/skills/linked-skill/SKILL.md" <<'EOF'
---
name: linked-skill
description: Test skill containing a symlink that must be rejected.
---

Test instructions.
EOF
ln -s SKILL.md "$IMPORT_HOME/.agents/skills/linked-skill/linked.md"
HOME="$IMPORT_HOME" /bin/bash "$IMPORT_REPO/import.sh" --dry-run linked-skill >"$TEST_ROOT/import-linked.out" 2>&1
grep -q 'rejecting skill containing symlink' "$TEST_ROOT/import-linked.out"
[ ! -e "$IMPORT_REPO/skills/linked-skill" ]

mkdir -p "$IMPORT_HOME/.agents/skills/clean-skill"
cat > "$IMPORT_HOME/.agents/skills/clean-skill/SKILL.md" <<'EOF'
---
name: clean-skill
description: Clean test skill that should be imported.
---

Test instructions.
EOF
HOME="$IMPORT_HOME" /bin/bash "$IMPORT_REPO/import.sh" --force clean-skill >/dev/null
[ -f "$IMPORT_REPO/skills/clean-skill/SKILL.md" ]
[ ! -L "$IMPORT_REPO/skills/clean-skill/SKILL.md" ]

UPSTREAM_INSTALLER="$TEST_ROOT/install-upstream.sh"
cp "$REPO_ROOT/install-upstream.sh" "$UPSTREAM_INSTALLER"
GSTACK_DIR="$TEST_ROOT/custom-gstack" HOME="$TEST_HOME" \
  /bin/bash "$UPSTREAM_INSTALLER" --dry-run --only gstack >"$TEST_ROOT/upstream.out"
grep -q "git clone .* $TEST_ROOT/custom-gstack" "$TEST_ROOT/upstream.out"
grep -q 'setup --host codex' "$TEST_ROOT/upstream.out"
if /bin/bash "$UPSTREAM_INSTALLER" --dry-run --only invalid >"$TEST_ROOT/upstream-invalid.out" 2>&1; then
  echo "Upstream installer unexpectedly accepted an invalid package" >&2
  exit 1
fi
grep -q -- '--only must be gstack or gsd' "$TEST_ROOT/upstream-invalid.out"

echo "tooling regression tests passed"
