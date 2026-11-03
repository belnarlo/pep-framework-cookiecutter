# PEP-PF-FWK-011: update-tools can add the missing sibling script

**ID:** PEP-PF-FWK-011  
**Title:** update-tools can add the missing sibling script  
**Author:** Timo Vlot  
**Status:** Implemented  
**Type:** Feature  
**Priority:** Medium  
**Created:** 2026-11-03  
**Updated:** 2026-11-03  
**Supersedes:** N/A  
**Superseded-By:** N/A  

## Abstract

update-tools gains opt-in --add-ps1 (bash) and --add-sh (PowerShell) so a repo that only has one script can be given the other.

## Motivation

PEP-PF-FWK-009 made `update-tools` refresh the sibling script, but only when the repo
already has it (some repos are deliberately single-shell). Found 2026-11-03: the work
repos (PS_Packer, PS_Powerdown, PS_Terraform, PS_Vault, PS_Monitoring) were created
bash-only but now need `pep-tools.ps1`, and nothing in the toolset can put it there;
the only route was a manual `cp`. A repo that needs the other shell has no supported
way to get it.

## Specification

### Requirements

- `pep-tools.sh update-tools --add-ps1`: also create `tools/pep-tools.ps1` when it is
  missing. `pep-tools.ps1 update-tools --add-sh` is the mirror.
- Opt-in only. Without the flag, behaviour is exactly as PEP-PF-FWK-009: a missing
  sibling is never added.
- Needs a git or local-path source that contains the sibling. A raw-file URL source
  errors, since it can't supply one.
- Parse-check the new file as in 009 (`pwsh` / `bash -n` when available). If it
  doesn't parse, remove it again and report an error; the main script stays updated.
- The new file is left unstaged; the log says to `git add` it.

### Implementation Approach

- Extend the existing sibling-sync function with an `add` argument; the create path
  runs only when the file is absent and the flag is set.
- Both scripts stay feature-identical (PEP-PF-FWK-006); help text updated in both.

### Success Criteria

- A bash-only repo plus `update-tools --add-ps1` ends with `tools/pep-tools.ps1`
  identical to the source; the PowerShell mirror likewise.
- No flag: no sibling appears.
- A sibling that doesn't parse is not left behind.

## Implementation Plan

### Phase 1: Both scripts and tests

- Flag, create path, help text, CHANGELOG, tests in `tests/test-commit-msg-hook.sh`.
- Built 2026-11-03 on Timo's personal Mac by Claude Code.

### Phase 2: Roll-out

- After push, in each work repo: `update-tools` (a pre-flag script can't parse the
  flag), then `update-tools --add-ps1`, then `git add tools/pep-tools.ps1`.

## Testing Strategy

- `tests/test-commit-msg-hook.sh`, local-path source, both scripts: flag adds the
  missing sibling with no backups left; a source sibling that doesn't parse is
  rejected and nothing is left behind. The no-flag case is covered by 009's tests.
- Result: 63 passed, 0 failed.

## Documentation Requirements

- Help text for `update-tools` and a CHANGELOG entry.

## Risks and Mitigation

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| A single-shell repo gets the other script by accident | Low | Low | Opt-in flag only; file left unstaged |
| Bad sibling copied in | Low | Low | Parse check; removed on failure |

## References

- PEP-PF-FWK-006 (parity), PEP-PF-FWK-009 (update-tools refreshes both scripts)

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.1 | 2026-11-03 | Timo Vlot | Initial draft |
| 1.0 | 2026-11-03 | Timo Vlot | Implemented in both scripts; 8 new test assertions (63/63) |
