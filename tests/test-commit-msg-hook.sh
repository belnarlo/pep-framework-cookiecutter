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
cp "${TOOLS_DIR}/pep-tools.sh" "${TOOLS_DIR}/pep-tools.ps1" "$SRC_TOOLS/"
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

# --- new-pep / new-branch: scripted use, numbering, stay mode ---------------

TOOLS_ROOT="${REPO_ROOT}/{{cookiecutter.project_slug}}"

# The bash and PowerShell tools must behave identically; run the same
# assertions against each. CLI is "sh" or "ps1" and selects pep().
pep() {
    if [ "$CLI" = "ps1" ]; then
        pwsh -NoProfile -File ./tools/pep-tools.ps1 "$@" </dev/null
    else
        bash ./tools/pep-tools.sh "$@" </dev/null
    fi
}

cli_tests() {
CLI="$1"
echo "# --- new-pep / new-branch via $CLI"
new_repo "$WORK/numbers-$CLI"
cp "${TOOLS_DIR}/pep-tools.sh" "${TOOLS_DIR}/pep-tools.ps1" tools/
mkdir -p docs/templates
cp "${TOOLS_ROOT}/docs/templates/pep-template.md" docs/templates/
git add -A && git commit -q -m "chore: add tooling"

# Non-interactive flags, with sed-special characters in the abstract
expect_success "[$CLI] new-pep with --type/--priority/--abstract/--no-open" \
    pep new-pep --type bug --priority high --abstract "A & B | C" --no-open 5 "First"
f5=$(ls docs/peps/pep-ps-xxx-005-*.md 2>/dev/null | head -1)
expect_success "[$CLI] scripted PEP has type, priority and abstract verbatim" \
    bash -c 'grep -q "Bug" "$1" && grep -q "High" "$1" && grep -qF "A & B | C" "$1"' _ "$f5"
expect_failure "[$CLI] new-pep rejects an unknown --type" \
    pep new-pep --type nonsense --no-open 9 "Bad"

# Next number looks at other local branches
git checkout -q -b feature/other
pep new-pep --type feature --priority low --abstract x --no-open 5 "Five" >/dev/null 2>&1
git add -A && git commit -q -m "chore: add pep five"
git checkout -q main
pep new-pep --type feature --priority low --abstract x --no-open "Next" >/dev/null 2>&1
expect_success "[$CLI] next number sees PEP 005 on another local branch (gets 006)" \
    test -n "$(ls docs/peps/pep-ps-xxx-006-*.md 2>/dev/null)"
rm -f docs/peps/pep-ps-xxx-006-*.md

# ...and remote-tracking branches (local bare repo, no network)
git init -q --bare "$WORK/origin-$CLI.git"
git remote add origin "$WORK/origin-$CLI.git"
git push -q origin feature/other:feature/remote-only
git branch -q -D feature/other
git fetch -q origin
pep new-pep --type feature --priority low --abstract x --no-open "Next" >/dev/null 2>&1
expect_success "[$CLI] next number sees PEP 005 on a remote-tracking branch (gets 006)" \
    test -n "$(ls docs/peps/pep-ps-xxx-006-*.md 2>/dev/null)"
rm -f docs/peps/pep-ps-xxx-006-*.md

# new-branch: default creates a branch; --here and BRANCH_PER_PEP=false stay
pep new-pep --type feature --priority low --abstract x --no-open 5 "Five" >/dev/null 2>&1
before=$(git rev-parse --abbrev-ref HEAD)
pep new-branch --here 5 >/dev/null 2>&1
expect_success "[$CLI] new-branch --here stays on the current branch" \
    test "$(git rev-parse --abbrev-ref HEAD)" = "$before"
echo 'BRANCH_PER_PEP=false' >> .peprc
pep new-branch 5 >/dev/null 2>&1
expect_success "[$CLI] BRANCH_PER_PEP=false stays on the current branch" \
    test "$(git rev-parse --abbrev-ref HEAD)" = "$before"
sed -i.bak '/BRANCH_PER_PEP/d' .peprc && rm -f .peprc.bak
pep new-branch 5 >/dev/null 2>&1
expect_success "[$CLI] new-branch creates feature/pep-ps-xxx-005-... by default" \
    bash -c 'git rev-parse --abbrev-ref HEAD | grep -q "^feature/pep-ps-xxx-005-"'

# update-hooks / update-tools refresh both hook copies
printf '#!/bin/bash\nexit 1\n' > tools/git-hooks/commit-msg
cp tools/git-hooks/commit-msg .git/hooks/commit-msg
pep update-hooks --source "$SRC_TOOLS" >/dev/null 2>&1
expect_success "[$CLI] update-hooks refreshes both hook copies" \
    bash -c 'cmp -s "$1" tools/git-hooks/commit-msg && cmp -s "$1" .git/hooks/commit-msg' _ "$SRC_TOOLS/git-hooks/commit-msg"
printf '#!/bin/bash\nexit 1\n' > tools/git-hooks/commit-msg
cp tools/git-hooks/commit-msg .git/hooks/commit-msg
pep update-tools --source "$SRC_TOOLS" >/dev/null 2>&1
expect_success "[$CLI] update-tools refreshes both hook copies" \
    bash -c 'cmp -s "$1" tools/git-hooks/commit-msg && cmp -s "$1" .git/hooks/commit-msg' _ "$SRC_TOOLS/git-hooks/commit-msg"

# update-templates keeps the repo's ai-block choice (or a customised template)
echo "# --- update-templates via $CLI"
new_repo "$WORK/templates-$CLI"
cp "${TOOLS_DIR}/pep-tools.sh" "${TOOLS_DIR}/pep-tools.ps1" tools/
mkdir -p docs/templates
T=docs/templates
SRC_T="${TOOLS_ROOT}/docs/templates"
old_variants() { printf 'old ai\n' > $T/pep-template-ai.md; printf 'old no-ai\n' > $T/pep-template-no-ai.md; }

old_variants; cp $T/pep-template-ai.md $T/pep-template.md
pep update-templates --source "${TOOLS_DIR}/pep-tools.sh" >/dev/null 2>&1
expect_success "[$CLI] update-templates keeps AI block on" \
    cmp -s $T/pep-template.md "$SRC_T/pep-template-ai.md"

old_variants; cp $T/pep-template-no-ai.md $T/pep-template.md
pep update-templates --source "${TOOLS_DIR}/pep-tools.sh" >/dev/null 2>&1
expect_success "[$CLI] update-templates keeps AI block off" \
    cmp -s $T/pep-template.md "$SRC_T/pep-template-no-ai.md"

old_variants; printf 'my own template\n' > $T/pep-template.md
pep update-templates --source "${TOOLS_DIR}/pep-tools.sh" >/dev/null 2>&1
expect_success "[$CLI] update-templates keeps a customised template, still updates the variants" \
    bash -c 'grep -qx "my own template" "$1/pep-template.md" && cmp -s "$1/pep-template-ai.md" "$2/pep-template-ai.md"' _ "$T" "$SRC_T"

rm -f $T/*.md; printf 'old\n' > $T/pep-template.md
pep update-templates --source "${TOOLS_DIR}/pep-tools.sh" >/dev/null 2>&1
expect_success "[$CLI] update-templates without local variants installs the default template" \
    cmp -s $T/pep-template.md "$SRC_T/pep-template.md"
}

cli_tests sh
if command -v pwsh >/dev/null 2>&1; then
    cli_tests ps1
else
    echo "skip - pwsh not installed, PowerShell tests not run"
fi

echo
echo "passed: $PASS  failed: $FAIL"
[ "$FAIL" -eq 0 ]
