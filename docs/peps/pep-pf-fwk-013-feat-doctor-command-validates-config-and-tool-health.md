# PEP-PF-FWK-013: doctor command validates config and tool health

**ID:** PEP-PF-FWK-013  
**Title:** doctor command validates config and tool health  
**Author:** Timo Vlot  
**Status:** Implemented  
**Type:** Feature  
**Priority:** Medium  
**Created:** 2026-11-03  
**Updated:** 2026-11-03  
**Supersedes:** N/A  
**Superseded-By:** N/A  

## Abstract

A doctor command checks .peprc/.peprc.local, the framework source, both scripts and the commit hook, and update-tools runs it quietly afterwards.

## Motivation

Found 2026-11-03: every work repo had a stale raw-file `PEP_FRAMEWORK_SOURCE` in its
committed `.peprc` (PEP-PF-FWK-012), and the work repos were missing `pep-tools.ps1`
(PEP-PF-FWK-009/011). Nothing in the toolset noticed either. A misspelt key in `.peprc` is
silently ignored, so config mistakes also last until something visibly breaks.
The framework needs a way to say "this repo's setup is wrong, and here is the fix".

## Specification

### Requirements

`doctor [--offline] [--quiet]` in both scripts. Each check prints OK, INFO, WARN or FAIL
with the fix. Exit 1 if anything FAILs; a WARN is exit 0.

1. **Framework source** (each of `.peprc.local`, `.peprc`): git URL = OK (reachable
   unless `--offline`); raw-file URL = WARN naming the git URL to use; other
   single-file URL = WARN; local path with no `pep-tools` script, or missing = FAIL.
2. **Unknown settings:** a key not in the known list = WARN with file and line, plus
   "did you mean" for a wrong-case match.
3. **Secrets:** a key containing KEY/TOKEN/SECRET/PASSWORD/PASSWD/WEBHOOK with a value
   in `.peprc` = FAIL (committed file); in `.peprc.local` = WARN. Names ending `_ENV`
   (the variable *name* for `ask`) are exempt. `PEP_ASK_*` in `.peprc` = WARN (ignored
   there). `.peprc.local` tracked by git = FAIL; not gitignored = WARN.
4. **Both scripts:** versions differ = WARN; only one present = INFO (single-shell repos
   are legitimate).
5. **Commit hook:** not installed, or different from `tools/git-hooks/commit-msg` = WARN.
6. **Latest version** (not `--offline`): the repo's tools differ from the framework's
   `main` = WARN; unreachable = INFO.
- `--quiet` prints only WARN/FAIL and a summary line when there is a problem.
- `update-tools` runs the new script's `doctor --quiet --offline` after updating, as a
  child process, and never lets it fail the update.
- Both scripts stay feature-identical (PEP-PF-FWK-006).

### Implementation Approach

- Config files are read line by line in both scripts rather than trusting the sourced
  variables, so the check sees each file's own value.
- The latest-version URL can be overridden with `PEP_DOCTOR_LATEST_URL` (used by the tests
  with a `file://` URL).

### Success Criteria

- A healthy repo: exit 0 and `--quiet` prints nothing.
- The 2026-11-03 raw-URL state is reported as a WARN with the fix.
- A typo'd key, a committed secret, a tracked `.peprc.local`, mismatched scripts and a
  missing hook are each reported.

## Implementation Plan

### Phase 1: Both scripts and tests

- `doctor`, help text, the `update-tools` hook, CHANGELOG, tests.
- Built 2026-11-03 on Timo's personal Mac by Claude Code, with PEP-PF-FWK-011 and 012. Released in 2.3.

### Phase 2: Roll-out

- After the work repos are updated, run `doctor` once in each; fix what it reports.
- Done 2026-11-03: all six work repos updated (stated by Timo). `doctor` reported `.peprc.local` tracked by git in the work repos; Timo fixed every one (stated by Timo; some were fixed before `doctor` was run on them, so not every repo's report was seen).

## Testing Strategy

- `tests/test-commit-msg-hook.sh`, both scripts, throwaway repos, no network (the version
  check uses a `file://` URL): healthy, raw source, missing path, unknown and wrong-case
  key, committed secret, `_ENV` name exempt, `PEP_ASK_*` in `.peprc`, tracked and
  un-ignored `.peprc.local`, version drift, missing and modified hook, newer and matching
  framework version. 38 assertions.
- Result: 113 passed, 0 failed.

## Documentation Requirements

- Help text and CHANGELOG.

## Risks and Mitigation

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| The known-keys list lags behind new settings, causing false WARNs | Low | Medium | One list per script, next to the checks; add a key with the setting that introduces it |
| The secret check misses an oddly named secret | Medium | Medium | It is a safety net, not a scanner; Vault remains the rule |
| The online check slows or fails in a locked-down network | Low | Medium | 5-second timeout, INFO on failure, `--offline` skips it |

## References

- PEP-PF-FWK-009, 011, 012; PEP-PF-FWK-006 (parity)

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.1 | 2026-11-03 | Timo Vlot | Initial draft |
| 1.0 | 2026-11-03 | Timo Vlot | Implemented in both scripts; 113/113 tests |
| 1.1 | 2026-11-03 | Timo Vlot (with Claude) | Roll-out done: all six work repos updated (stated by Timo). First real-world catch: `.peprc.local` committed in the work repos (personal settings only, no secrets in the one inspected); all untracked (stated by Timo) |
