# Changelog

## 2.3 — 2026-11-03

### Added (identical in `pep-tools.sh` and `pep-tools.ps1`)

- `ask <term>` (PEP-PF-FWK-008): which PEP is about a term? It searches the
  PEPs case-insensitively and prints, per matching PEP, its ID, title and up to
  five matching lines. With `PEP_ASK_URL` set, it sends those lines (never
  whole files) to an OpenAI-compatible endpoint and prints the model's answer
  plus the matched files. Settings, all in `.peprc.local` only (ignored in
  `.peprc`, so a shared repo can't redirect it): `PEP_ASK_URL`,
  `PEP_ASK_MODEL` (default `local`), `PEP_ASK_KEY_ENV` (the environment
  variable holding the key, default `LITELLM_MASTER_KEY`; the key is never
  read from a file or put on a command line). Exit codes: 0 answered or
  matches shown, 1 no match, 2 the model request failed (matches still shown).
  The bash version needs `curl` and `jq` for the model call. `init` and
  `.peprc.local.example` carry the settings, commented out.

### Fixed

- `update-tools` keeps both scripts in step (PEP-PF-FWK-009). Each script used
  to replace only itself, so a repo updated with bash kept an old
  `pep-tools.ps1` (found in two homelab repos, 51 lines behind). Now, when the
  repo has the other script, it is refreshed from the same source, backed up
  first, parse-checked (`pwsh` or `bash -n`, when installed; otherwise it says
  it wasn't checked) and restored on failure. A failed sibling update exits
  non-zero but leaves the main script updated. A repo without the other script
  doesn't get one. Raw-file URL sources print a warning instead.
- Script version headers now say 2.3 (they had stayed at 2.1 through 2.2).

### Getting it in an existing repo

```bash
./tools/pep-tools.sh update-tools
./tools/pep-tools.sh update-templates
```

Repos on 2.2 with both scripts: also run `pwsh tools/pep-tools.ps1 update-tools`
once (a 2.2 script doesn't know about the sibling yet). From 2.3 on, one run
does both.

### Tests

- `tests/test-ask.sh`: `ask` on both scripts against a stand-in model server on
  127.0.0.1 (Python), no network.
- `tests/test-commit-msg-hook.sh`: sibling refresh, bash-only repos, and a
  sibling that doesn't parse.

## 2.2.1 — 2026-10-20

### Fixed

- `setup-existing.sh` no longer stops halfway when the Zabbix host is a URL.
  The `.peprc` edit for `ZABBIX_HOST` used `/` as the `sed` delimiter, so a
  value such as `http://zabbix/` failed with "bad flag in substitute command",
  and `set -e` ended the run before `.peprc.local`, the hook permissions and
  `pep-tools.sh init`. It now uses `|`, like `GRAFANA_URL`.

## 2.2 — 2026-10-18

### Fixed

- New PEPs no longer list themselves under **Supersedes** and **Superseded-By**.
  The templates had `PEPID (if applicable)` on both lines, and `new-pep`
  replaces every `PEPID` with the new PEP's ID, so each PEP claimed to supersede
  itself. Both lines now default to `N/A`. Existing PEPs keep the wrong lines
  until fixed; in each repo:

  ```bash
  for f in docs/peps/pep-*.md; do
    id=$(sed -n 's/^\*\*ID:\*\* \(PEP-[A-Z0-9-]*\).*/\1/p' "$f")
    sed -i.bak "s/^\(\*\*Supersede[sd]-*B*y*:\*\*\) $id (if applicable)  $/\1 N\/A  /" "$f" && rm "$f.bak"
  done
  ```

  Then `./tools/pep-tools.sh update-tools` and
  `./tools/pep-tools.sh update-templates` to pick up the fixed templates.
- `update-templates` keeps the repo's AI-block choice (both `pep-tools.sh` and
  `pep-tools.ps1`). It used to copy the default `pep-template.md` over the
  active template, silently turning the AI block off in repos that had it on.
  It now checks the active template first, the same way as `ai-block status`:
  - **on** or **off:** the active template is refreshed from the matching new
    variant.
  - **customised** (matches neither variant): left alone, with a warning. The
    variants are still updated, so you can merge by hand.
  - **no local variants** (very old installs): the default template, as before.

  Run `update-tools` before `update-templates`, so the new logic is the one
  doing the update.
- `update-tools` removes its `tools/pep-tools.sh.bak` (or `.ps1.bak`) once the
  update succeeds. It first checks the new script parses (`bash -n`, or the
  PowerShell parser). If it doesn't, or the copy or download fails, the old
  script is restored and the backup removed, so a failed update changes
  nothing. A failed `curl`/`wget` download used to stop the script under
  `set -e` without restoring, which could leave a broken `pep-tools.sh`.
- `pep-template-ai.md` lost a stray trailing space, so repos whose pre-commit
  trims whitespace no longer see a diff on every `update-templates`.
- Monitoring projects' generated README no longer suggests
  `grafana-cli admin export-dashboard`, which doesn't exist (and `grafana-cli` is
  deprecated in favour of `grafana cli`). It now shows an HTTP API export.

## 2.1 — 2026-10-01

### Fixed

- The `commit-msg` hook no longer validates merge commits. Git's default merge
  message names the branch, for example
  `Merge branch 'main' into feature/pep-ps-slt-059-x`, which the hook read as a
  malformed PEP reference. `git pull` and `git merge` on a PEP branch were
  refused and left a half-finished merge. The hook now exits early when the
  message starts with the word `Merge` or a merge is in progress
  (`MERGE_HEAD`).
  All other checks are unchanged.

### Added (identical in `pep-tools.sh` and `pep-tools.ps1`)

- `new-pep` takes the next free number across all local and remote-tracking
  branches (read-only, `git ls-tree`). Remote refs are as of the last
  `git fetch`.
- `new-pep --type T --priority P --abstract TEXT --no-open` for scripted use.
  Invalid `--type` or `--priority` values are errors, not silent defaults.
  The editor never opens without a terminal. Titles, abstracts and author
  names containing `&` or `|` are now escaped correctly.
- `new-branch --here`, or `BRANCH_PER_PEP="false"` in `.peprc`, stays on the
  current branch instead of creating `feature/<pep>`.

### Changed

- `update-tools` now also refreshes `tools/git-hooks/commit-msg` and reinstalls
  it into the repo's hooks directory. Before, it only replaced `pep-tools.sh`,
  so the hook in `.git/hooks/` stayed stale until someone ran `init`.
- New `update-hooks [--source <path|git>]` command does just the hook refresh.
- Hook installation uses `git rev-parse --git-path`, so worktrees and
  `core.hooksPath` work.
- `pep-tools.sh` and `pep-tools.ps1` version bumped to 2.1. The two scripts
  must stay feature-identical; the tests run the same assertions on both.

### Getting the fix in an existing repo

```bash
./tools/pep-tools.sh update-tools
./tools/pep-tools.sh update-hooks
```

Run both. Repos still on 2.0 need the second command, because the 2.0 script
does not know how to refresh the hook. On Windows, use
`.\tools\pep-tools.ps1` with the same two commands. Then commit the updated
`tools/` files.

### Tests

- `tests/test-commit-msg-hook.sh` covers merge commits, PEP validation and the
  hook refresh. It needs no network and cleans up after itself.
