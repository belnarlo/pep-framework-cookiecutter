# PEP-PF-FWK-012: update-tools handles a raw-file PEP_FRAMEWORK_SOURCE

**ID:** PEP-PF-FWK-012  
**Title:** update-tools handles a raw-file PEP_FRAMEWORK_SOURCE  
**Author:** Timo Vlot  
**Status:** Implemented  
**Type:** Bug  
**Priority:** High  
**Created:** 2026-11-03  
**Updated:** 2026-11-03  
**Supersedes:** N/A  
**Superseded-By:** N/A  

## Abstract

update-tools (and --add-ps1/--add-sh) failed in repos whose PEP_FRAMEWORK_SOURCE is a raw-file URL; it now uses the repo's git URL and rewrites the saved value.

## Motivation

Found 2026-11-03 while rolling out PEP-PF-FWK-011: in a work repo, `update-tools --add-ps1`
failed with "needs a path or git source that contains pep-tools.ps1". Cause: the repo's
committed `.peprc` holds `PEP_FRAMEWORK_SOURCE` as a raw-file URL
(`https://raw.githubusercontent.com/.../tools/pep-tools.sh`), which older versions of the
framework wrote. `update-tools` treats that source as one file to download, so there is
no `tools/` directory to take the sibling script from. The configured value also beats
the default git repo, so the tool never got to the good source. All the work repos had the
same value, so the manual fix would have been repeated in each, and the value would
still be wrong for everyone else on the repo.

PEP-PF-FWK-011 specified "a raw-file URL source errors" as acceptable. That was wrong:
it is the normal state of the existing work repos.

## Specification

### Requirements

- `update-tools` (both scripts): when the source (flag, config or environment) is a
  raw-file URL that names a GitHub repo, use that repo's git URL instead, for the whole
  run: the script, the hook and the sibling all come from the clone.
- After a successful update, rewrite `PEP_FRAMEWORK_SOURCE` to the git URL in every config
  file that holds the raw value (`.peprc.local`, then `.peprc`). Only that line changes.
  If `.peprc` was changed, say so, since it is a shared file that needs committing.
- A raw URL that doesn't name a GitHub repo keeps the old behaviour (download the one
  file); `--add-ps1` / `--add-sh` then errors with a message telling the user to pass
  `--source <git url>`.
- Both scripts stay feature-identical (PEP-PF-FWK-006).

### Implementation Approach

- Reuse `derive_git_url_from_raw` / `Get-GitUrlFromRawUrl`, already used by
  `update-templates`, `update-hooks` and `claude-skills`.
- Convert before the backup/clone step so the git branch handles everything.
- `rewrite_raw_source_config` / `Update-PepRawSourceConfig` do the in-place line rewrite.

### Success Criteria

- With a raw URL in `.peprc`, `update-tools --add-ps1` (or `--add-sh`) adds the sibling and
  `.peprc` then holds the git URL.
- With a raw URL in `.peprc.local`, a plain `update-tools` rewrites that file only.
- A non-GitHub raw URL with the flag is refused and nothing is added.

## Implementation Plan

### Phase 1: Both scripts and tests

- Conversion and rewrite in `update_tools` and `Update-PepTools`; tests; CHANGELOG.
- Built 2026-11-03 on Timo's personal Mac by Claude Code, with PEP-PF-FWK-011 and 013. Released in 2.3.

### Phase 2: Roll-out

- Work repos: run `update-tools` (the old script can't do this yet), then
  `update-tools --add-ps1`; commit the rewritten `.peprc` in the same PR.
  `doctor` (PEP-PF-FWK-013) reports any repo still holding a raw URL.
- Done 2026-11-03: all six work repos updated; the raw-URL source was rewritten in each (stated by Timo).

## Testing Strategy

- `tests/test-commit-msg-hook.sh`, both scripts. The GitHub URL is redirected to a local
  repo with git's `url.<base>.insteadOf`, so no network is used:
  - raw URL in `.peprc` plus the flag: sibling added, line rewritten.
  - raw URL in `.peprc.local`: rewritten there, `.peprc` untouched.
  - non-GitHub raw URL plus the flag: refused, nothing added.
- Result: 75 passed, 0 failed.

## Documentation Requirements

- CHANGELOG entry; correct the "raw URL errors" line in PEP-PF-FWK-011.

## Risks and Mitigation

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Rewriting a shared `.peprc` surprises someone | Low | Medium | Only the one line changes; the log says to commit it; `git restore .peprc` backs it out |
| The converted git clone needs `git` where curl alone used to do | Low | Low | `git` is already required for git sources and the hook |

## References

- PEP-PF-FWK-009 (update-tools refreshes both scripts), PEP-PF-FWK-011 (add the missing
  sibling), PEP-PF-FWK-013 (`doctor`)

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.1 | 2026-11-03 | Timo Vlot | Initial draft |
| 1.0 | 2026-11-03 | Timo Vlot | Implemented in both scripts; 6 new test assertions (75/75) |
| 1.1 | 2026-11-03 | Timo Vlot (with Claude) | Roll-out done: all six work repos updated and the raw-URL `PEP_FRAMEWORK_SOURCE` rewritten (stated by Timo) |
