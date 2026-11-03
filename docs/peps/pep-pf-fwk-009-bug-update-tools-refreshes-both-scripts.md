# PEP-PF-FWK-009: update-tools refreshes both scripts

**ID:** PEP-PF-FWK-009  
**Title:** update-tools refreshes both scripts  
**Author:** Timo Vlot  
**Status:** Implemented  
**Type:** Bug  
**Priority:** Medium  
**Created:** 2026-11-03  
**Updated:** 2026-11-03  
**Supersedes:** N/A  
**Superseded-By:** N/A  

## Abstract

`update-tools` in either script also refreshes the other script when the repo has it,
so `pep-tools.sh` and `pep-tools.ps1` can't drift apart.

## Motivation

Each script's `update-tools` only replaces itself: `pep-tools.sh` updates
`tools/pep-tools.sh` (and the hook), `pep-tools.ps1` updates `tools/pep-tools.ps1`.
Most people only run one of them, so the other copy goes stale. Found 2026-11-03:
`homelab-grafana` and `homelab-jarvis` had current bash tools but a `pep-tools.ps1`
51 lines behind, after every update had been run with bash. The scripts are meant to
be feature-identical (PEP-PF-FWK-006), and a stale sibling breaks that for anyone on
the other platform.

## Specification

### Requirements

- `update-tools` (both scripts): after updating itself, if the sibling script exists in
  `tools/`, refresh it from the same source.
- If the sibling isn't in the repo, don't add it (some repos are bash-only).
- Git and local-path sources: take the sibling from the same `tools/` directory as the
  main script.
- Raw-file URL source: the sibling can't be derived reliably; warn and say which
  command to run, as the hook warning already does.
- Same safety as the main script: back up first; if the sibling copy fails or doesn't
  parse, restore it and say so. A failed sibling update doesn't undo the main update,
  and is reported clearly.
- Parse checks: bash checks the `.ps1` with `pwsh` when it's installed, otherwise
  copies without checking and says so; PowerShell checks the `.sh` with `bash -n` when
  bash is available, likewise.

### Implementation Approach

- Reuse each script's existing backup, restore and parse-check code; add a sibling step
  after the main update and before the exit (bash must still exit straight after
  replacing itself, PEP-PF-FWK-002).
- Keep both scripts feature-identical; the tests run the same assertions on both.

### Success Criteria

- In a repo with both scripts, `./tools/pep-tools.sh update-tools --source <template>`
  leaves both identical to the template; the same for `pep-tools.ps1 update-tools`.
- In a bash-only repo, no `.ps1` appears.
- A broken sibling in the source leaves the repo's sibling unchanged, with an error.

## Implementation Plan

### Phase 1: Both scripts and tests

- Sibling step in `update_tools` and `Update-PepTools`; help text; CHANGELOG entry.
- Built 2026-11-03 on Timo's personal Mac by Claude Code, with PEP-PF-FWK-008.
  Released in 2.3.

### Phase 2: Roll-out

- One `update-tools` run per repo now refreshes both. The per-repo Todoist tasks for the
  work repos already include a manual PowerShell step; it is only needed once, for
  repos still on 2.2 (a 2.2 script can't refresh its sibling).

## Testing Strategy

- In `tests/`, no network, local-path source:
  - Both scripts present: both updated.
  - Bash-only repo: no `.ps1` created.
  - Broken sibling in the source: the repo's sibling restored, error shown, main script
    still updated.
  - Raw-URL source: warning printed, sibling untouched.
- Existing `tests/test-commit-msg-hook.sh` still passes.

## Documentation Requirements

- Help text for `update-tools`, CHANGELOG, and the template README's upgrade section.

## Risks and Mitigation

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| A bad sibling copy breaks the other platform | Medium | Low | Backup, parse check when the parser exists, restore on failure |
| No `pwsh` on a Linux box, so the `.ps1` isn't checked | Low | Medium | Copied from the same release as the checked `.sh`; the output says it wasn't checked |

## References

- PEP-PF-FWK-003 (PowerShell port), PEP-PF-FWK-006 (parity), PEP-PF-FWK-007
  (update-tools rollback)

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.1 | 2026-11-03 | Timo Vlot | Initial draft |
| 1.0 | 2026-11-03 | Timo Vlot | Implemented in both scripts (2.3); sibling tests in `tests/test-commit-msg-hook.sh` (55/55); checked live on this repo's own `tools/` |
