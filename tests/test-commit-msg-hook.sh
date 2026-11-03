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
expect_success "[$CLI] update-tools removes its backup after a good update" \
    bash -c '! ls tools/*.bak >/dev/null 2>&1'

# A source that doesn't parse is rolled back, with no backup left behind
BROKEN="$WORK/broken-$CLI"
mkdir -p "$BROKEN"
printf 'if then fi (\n' > "$BROKEN/pep-tools.sh"
printf 'function { (\n' > "$BROKEN/pep-tools.ps1"
cp tools/pep-tools.sh "$WORK/before-$CLI.sh"; cp tools/pep-tools.ps1 "$WORK/before-$CLI.ps1"
expect_failure "[$CLI] update-tools refuses a source that doesn't parse" \
    pep update-tools --source "$BROKEN"
expect_success "[$CLI] ...and leaves the old script in place, with no backup" \
    bash -c 'cmp -s "$1" tools/pep-tools.sh && cmp -s "$2" tools/pep-tools.ps1 && ! ls tools/*.bak >/dev/null 2>&1' _ "$WORK/before-$CLI.sh" "$WORK/before-$CLI.ps1"

# update-tools keeps the sibling script in step (PEP-PF-FWK-009)
echo "# --- update-tools sibling via $CLI"
if [ "$CLI" = "ps1" ]; then own=pep-tools.ps1; sib=pep-tools.sh; else own=pep-tools.sh; sib=pep-tools.ps1; fi
new_repo "$WORK/sibling-$CLI"
cp "${TOOLS_DIR}/pep-tools.sh" "${TOOLS_DIR}/pep-tools.ps1" tools/
printf '# stale sibling\n' > "tools/$sib"
pep update-tools --source "$SRC_TOOLS" >/dev/null 2>&1
expect_success "[$CLI] update-tools refreshes the sibling $sib too" \
    cmp -s "$SRC_TOOLS/$sib" "tools/$sib"
expect_success "[$CLI] ...with no backups left" \
    bash -c '! ls tools/*.bak >/dev/null 2>&1'

new_repo "$WORK/sibling-only-$CLI"
cp "${TOOLS_DIR}/$own" tools/
pep update-tools --source "$SRC_TOOLS" >/dev/null 2>&1
expect_success "[$CLI] update-tools doesn't add $sib to a repo without it" \
    test ! -e "tools/$sib"

new_repo "$WORK/sibling-broken-$CLI"
cp "${TOOLS_DIR}/pep-tools.sh" "${TOOLS_DIR}/pep-tools.ps1" tools/
printf '# old but working sibling\n' > "tools/$sib"
cp "tools/$sib" "$WORK/sib-before-$CLI"
printf '# stale own\n' >> "tools/$own"
HALF="$WORK/half-broken-$CLI"
mkdir -p "$HALF/git-hooks"
cp "$SRC_TOOLS/$own" "$HALF/"
cp "$HOOK_SRC" "$HALF/git-hooks/commit-msg"
if [ "$sib" = "pep-tools.ps1" ]; then printf 'function { (\n' > "$HALF/$sib"; else printf 'if then fi (\n' > "$HALF/$sib"; fi
expect_failure "[$CLI] update-tools reports a sibling that doesn't parse" \
    pep update-tools --source "$HALF"
expect_success "[$CLI] ...keeps the old sibling and still updates $own, no backups" \
    bash -c 'cmp -s "$1" "tools/$3" && cmp -s "$2/$4" "tools/$4" && ! ls tools/*.bak >/dev/null 2>&1' _ "$WORK/sib-before-$CLI" "$HALF" "$sib" "$own"

# update-tools --add-ps1 / --add-sh creates the missing sibling (PEP-PF-FWK-011)
echo "# --- update-tools --add-sibling via $CLI"
if [ "$CLI" = "ps1" ]; then addflag=--add-sh; else addflag=--add-ps1; fi
new_repo "$WORK/add-sibling-$CLI"
cp "${TOOLS_DIR}/$own" tools/
pep update-tools --source "$SRC_TOOLS" $addflag >/dev/null 2>&1
expect_success "[$CLI] update-tools $addflag adds the missing $sib"     cmp -s "$SRC_TOOLS/$sib" "tools/$sib"
expect_success "[$CLI] ...with no backups left"     bash -c '! ls tools/*.bak >/dev/null 2>&1'

new_repo "$WORK/add-sibling-broken-$CLI"
cp "${TOOLS_DIR}/$own" tools/
ABROKEN="$WORK/add-broken-$CLI"
mkdir -p "$ABROKEN/git-hooks"
cp "$SRC_TOOLS/$own" "$ABROKEN/"
cp "$HOOK_SRC" "$ABROKEN/git-hooks/commit-msg"
if [ "$sib" = "pep-tools.ps1" ]; then printf 'function { (\n' > "$ABROKEN/$sib"; else printf 'if then fi (\n' > "$ABROKEN/$sib"; fi
expect_failure "[$CLI] update-tools $addflag reports a sibling that doesn't parse" \
    pep update-tools --source "$ABROKEN" $addflag
expect_success "[$CLI] ...and doesn't leave $sib behind" \
    test ! -e "tools/$sib"

# A raw-file PEP_FRAMEWORK_SOURCE is upgraded to its git repo (PEP-PF-FWK-012).
# The GitHub URL is redirected to a local repo, so no network is used.
echo "# --- raw-URL source via $CLI"
ORIGIN="$WORK/origin-$CLI"
mkdir -p "$ORIGIN/{{cookiecutter.project_slug}}"
cp -R "$SRC_TOOLS" "$ORIGIN/{{cookiecutter.project_slug}}/tools"
(cd "$ORIGIN" && git init -q -b main . && git add -A && git commit -q -m origin)
RAW="https://raw.githubusercontent.com/belnarlo/pep-framework-cookiecutter/main/%7B%7Bcookiecutter.project_slug%7D%7D/tools/pep-tools.sh"
GITURL="https://github.com/belnarlo/pep-framework-cookiecutter.git"
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0="url.$ORIGIN.insteadOf" GIT_CONFIG_VALUE_0="$GITURL"

new_repo "$WORK/raw-shared-$CLI"
cp "${TOOLS_DIR}/$own" tools/
printf 'PEP_FRAMEWORK_SOURCE="%s"\n' "$RAW" >> .peprc
pep update-tools $addflag >/dev/null 2>&1
expect_success "[$CLI] update-tools $addflag works when .peprc holds a raw-file URL" \
    cmp -s "$SRC_TOOLS/$sib" "tools/$sib"
expect_success "[$CLI] ...and rewrites that .peprc line to the git URL" \
    grep -qxF "PEP_FRAMEWORK_SOURCE=\"$GITURL\"" .peprc

new_repo "$WORK/raw-local-$CLI"
cp "${TOOLS_DIR}/$own" tools/
printf 'PEP_FRAMEWORK_SOURCE="%s"\n' "$RAW" > .peprc.local
pep update-tools >/dev/null 2>&1
expect_success "[$CLI] a raw-file URL in .peprc.local is rewritten to the git URL" \
    grep -qxF "PEP_FRAMEWORK_SOURCE=\"$GITURL\"" .peprc.local
expect_success "[$CLI] ...and nothing is added to .peprc" \
    bash -c '! grep -q PEP_FRAMEWORK_SOURCE .peprc'

new_repo "$WORK/raw-other-$CLI"
cp "${TOOLS_DIR}/$own" tools/
printf 'PEP_FRAMEWORK_SOURCE="https://example.invalid/x/%s"\n' "$own" >> .peprc
expect_failure "[$CLI] $addflag with a raw URL that isn't a GitHub repo is refused" \
    pep update-tools $addflag
expect_success "[$CLI] ...and no $sib appears" \
    test ! -e "tools/$sib"
unset GIT_CONFIG_COUNT GIT_CONFIG_KEY_0 GIT_CONFIG_VALUE_0

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
