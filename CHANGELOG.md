# Changelog

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

  Then `./tools/pep-tools.sh update-templates` to pick up the fixed templates.
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
