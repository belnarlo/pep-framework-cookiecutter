# PEP-PF-FWK-006: Version 2.1: scripted new-pep and hook fixes

**ID:** PEP-PF-FWK-006  
**Title:** Version 2.1: scripted new-pep and hook fixes  
**Author:** Timo Vlot  
**Status:** Implemented  
**Type:** Feature  
**Priority:** Medium  
**Created:** 2026-10-01  
**Updated:** 2026-11-03  
**Supersedes:** N/A  
**Superseded-By:** N/A  

> Raised retroactively on 2026-11-03. Detail: `CHANGELOG.md`, section 2.1.

## Abstract

Version 2.1: `new-pep` scriptable with flags and numbered across all branches,
stay-on-branch mode, an Informational status, merge commits skipped by the commit-msg
hook, and `update-tools` refreshing the hook too.

## Motivation

`git pull` and `git merge` on a PEP branch were refused, because the hook read Git's
merge message as a malformed PEP reference. Two branches could pick the same PEP
number. Claude Code and scripts couldn't drive `new-pep` without its prompts. Homelab
repos commit straight to main and didn't want a branch per PEP.

## Specification

### Requirements

- The hook skips merge commits; all other checks unchanged.
- `new-pep` takes the next free number across local and remote-tracking branches.
- `new-pep --type --priority --abstract --no-open`; invalid values are errors.
- `new-branch --here` or `BRANCH_PER_PEP="false"` stays on the current branch.
- Informational: a standing status, neither open nor closed.
- `update-tools` also refreshes and reinstalls the hook; new `update-hooks`.

### Implementation Approach

- Numbering reads branches with `git ls-tree` (read-only).
- Hook installed via `git rev-parse --git-path`, so worktrees and `core.hooksPath`
  work.
- Bash and PowerShell kept feature-identical.

### Success Criteria

- Merges on PEP branches work; tests pass on both scripts. Met.

## Implementation Plan

### Phase 1: 2.1 (2026-10-01)

- `4c7729f` Informational status; `47ea9e3` merge commits skipped; `5fc1a7b` scripted
  `new-pep`, cross-branch numbering, stay-on-branch mode.

### Phase 2: Follow-up (2026-10-09)

- `54661f9` `migrate` strips trailing whitespace from Type and Title.

## Testing Strategy

- `tests/test-commit-msg-hook.sh`: merge commits, PEP validation and the hook refresh,
  same assertions on both scripts, no network.

## Documentation Requirements

- `CHANGELOG.md` 2.1, including how to get the fix into an existing repo.

## Risks and Mitigation

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Repos on 2.0 keep a stale hook | Medium | High | Changelog says to run `update-hooks` as well |

## References

- PEP-PF-FWK-003 (PowerShell port)

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-11-03 | Timo Vlot | Raised retroactively from commits `4c7729f`, `47ea9e3`, `5fc1a7b`, `54661f9` |
