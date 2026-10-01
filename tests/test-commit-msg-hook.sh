#!/bin/bash
# Tests for tools/git-hooks/commit-msg and the update-hooks/update-tools
# rollout path. Builds throwaway repos in a temp directory, needs no network
# and removes everything on exit.
#
# Usage: tests/test-commit-msg-hook.sh
# Override the hook under test with HOOK_SRC=/path/to/commit-msg (used to
# prove the tests fail against the old hook).

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS_DIR="${REPO_ROOT}/{{cookiecutter.project_slug}}/tools"
HOOK_SRC="${HOOK_SRC:-${TOOLS_DIR}/git-hooks/commit-msg}"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Isolate from the caller's git config (signing, hooksPath, templates).
export GIT_CONFIG_GLOBAL=/dev/null
export GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_NAME="Test" GIT_AUTHOR_EMAIL="test@example.invalid"
export GIT_COMMITTER_NAME="Test" GIT_COMMITTER_EMAIL="test@example.invalid"

PASS=0
FAIL=0

ok()   { PASS=$((PASS + 1)); echo "ok   - $1"; }
nok()  { FAIL=$((FAIL + 1)); echo "FAIL - $1"; }

# expect_success <description> <command...>
expect_success() {
    local desc="$1"; shift
    if out=$("$@" 2>&1); then ok "$desc"; else nok "$desc"; echo "$out" | sed 's/^/       /'; fi
}

# expect_failure <description> <command...>
expect_failure() {
    local desc="$1"; shift
    if out=$("$@" 2>&1); then nok "$desc (expected refusal, got success)"; else ok "$desc"; fi
}

# commit_file <message> — stage a fresh file and commit with the given message
commit_file() {
    local n
    n=$(date +%s%N 2>/dev/null || echo "$RANDOM$RANDOM")
    echo "$n $RANDOM" > "file-$n-$RANDOM.txt"
    git add -A && git commit -q -m "$1"
}

new_repo() {
    local dir="$1"
    mkdir -p "$dir" && cd "$dir" || exit 1
    git init -q -b main .
    mkdir -p docs/peps tools/git-hooks
    printf 'PROJECT_CODE="PS"\nREPO_CODE="XXX"\n' > .peprc
    touch docs/peps/.gitkeep
    git add -A && git commit -q -m "chore: init"
}

install_hook() {
    cp "$HOOK_SRC" tools/git-hooks/commit-msg
    cp tools/git-hooks/commit-msg .git/hooks/commit-msg
    chmod +x .git/hooks/commit-msg
}

# --- Merge commits and PEP validation ---------------------------------------

new_repo "$WORK/merge"
install_hook

git checkout -q -b feature/pep-ps-xxx-059-test
cat > docs/peps/pep-ps-xxx-059-feature-test.md <<'EOF'
# PEP-PS-XXX-059: Test

**Status:** Draft
EOF
git add -A && git commit -q -m "pep-ps-xxx-059: add pep" || nok "setup: commit PEP file"

git checkout -q main
commit_file "chore: main change one"
git checkout -q feature/pep-ps-xxx-059-test

expect_success "normal commit 'pep-ps-xxx-059: work'" commit_file "pep-ps-xxx-059: work"
expect_success "plain 'git merge main' with the default message" git merge main

git checkout -q main
commit_file "chore: main change two"
git checkout -q feature/pep-ps-xxx-059-test
expect_success "'git merge -m \"chore: x\" main'" git merge -m "chore: x" main

# MERGE_HEAD path: a message that does not start with "Merge " must still pass
# while a merge is in progress.
git checkout -q main
commit_file "chore: main change three"
git checkout -q feature/pep-ps-xxx-059-test
git merge -q --no-commit main >/dev/null 2>&1
expect_success "merge in progress, message mentions PEP without format" \
    git commit -q -m "wrap up pep-ps-xxx-059 merge"

expect_failure "'chore: mentions pep-ps-xxx-059' is refused" \
    commit_file "chore: mentions pep-ps-xxx-059"
expect_failure "PEP number with no PEP file is refused" \
    commit_file "pep-ps-xxx-777: no such pep"

# --- Rollout: update-hooks / update-tools refresh both copies ---------------

stale_hook() {
    # Simulate a repo vendored before the fix: a hook that always refuses.
    printf '#!/bin/bash\nexit 1\n' > tools/git-hooks/commit-msg
    cp tools/git-hooks/commit-msg .git/hooks/commit-msg
    chmod +x .git/hooks/commit-msg
}

# Stand-in for a source checkout: tools dir with the real script and hook.
SRC_TOOLS="$WORK/source-tools"
mkdir -p "$SRC_TOOLS/git-hooks"
cp "${TOOLS_DIR}/pep-tools.sh" "$SRC_TOOLS/pep-tools.sh"
cp "$HOOK_SRC" "$SRC_TOOLS/git-hooks/commit-msg"

new_repo "$WORK/rollout-hooks"
cp "${TOOLS_DIR}/pep-tools.sh" tools/pep-tools.sh
stale_hook
bash ./tools/pep-tools.sh update-hooks --source "$SRC_TOOLS" >/dev/null 2>&1
expect_success "update-hooks refreshes tools/git-hooks/commit-msg" \
    cmp -s "$SRC_TOOLS/git-hooks/commit-msg" tools/git-hooks/commit-msg
expect_success "update-hooks reinstalls .git/hooks/commit-msg" \
    cmp -s "$SRC_TOOLS/git-hooks/commit-msg" .git/hooks/commit-msg
expect_success "installed hook is executable" test -x .git/hooks/commit-msg

new_repo "$WORK/rollout-tools"
cp "${TOOLS_DIR}/pep-tools.sh" tools/pep-tools.sh
stale_hook
bash ./tools/pep-tools.sh update-tools --source "$SRC_TOOLS" >/dev/null 2>&1
expect_success "update-tools refreshes tools/git-hooks/commit-msg" \
    cmp -s "$SRC_TOOLS/git-hooks/commit-msg" tools/git-hooks/commit-msg
expect_success "update-tools reinstalls .git/hooks/commit-msg" \
    cmp -s "$SRC_TOOLS/git-hooks/commit-msg" .git/hooks/commit-msg

echo
echo "passed: $PASS  failed: $FAIL"
[ "$FAIL" -eq 0 ]
