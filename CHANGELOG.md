# Changelog

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

### Changed

- `update-tools` now also refreshes `tools/git-hooks/commit-msg` and reinstalls
  it into the repo's hooks directory. Before, it only replaced `pep-tools.sh`,
  so the hook in `.git/hooks/` stayed stale until someone ran `init`.
- New `update-hooks [--source <path|git>]` command does just the hook refresh.
- Hook installation uses `git rev-parse --git-path`, so worktrees and
  `core.hooksPath` work.
- `pep-tools.sh` and `pep-tools.ps1` version bumped to 2.1.

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
