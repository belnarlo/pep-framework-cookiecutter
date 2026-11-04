# PEP-PF-FWK-014: doctor lints PEP files: status, file name and header

**ID:** PEP-PF-FWK-014  
**Title:** doctor lints PEP files: status, file name and header  
**Author:** Timo Vlot  
**Status:** Draft  
**Type:** Feature  
**Priority:** Medium  
**Created:** 2026-11-04  
**Updated:** 2026-11-04  
**Supersedes:** N/A  
**Superseded-By:** N/A  

## Abstract

Extend doctor so it also checks the PEP files themselves, not only the config and tools: header status, file name, ID and header fields. Today a PEP file with a space in its name or an unknown status passes doctor with all checks ok.

## Motivation

`doctor` (PEP-PF-FWK-013) checks `.peprc`, `.peprc.local`, the framework source, both scripts and the commit-msg hook. It never opens a PEP. During the work test run on 2026-11-03 a repo of 34 PEPs had one file name with a space in it ("bug fix" as the type word), and `doctor` still reported `5 ok, 0 info, 0 warn, 0 fail`. The other commands cope with it (`list`, `status`, `migrate --dry-run` and `fix-naming --dry-run` all counted 34 of 34), so nothing fails loudly; the file only breaks unquoted shell loops and ad hoc scripts, which is how it was first mishandled.

The same run showed why a status check needs care: body lines such as `**Status: COMPLETE**` (progress notes inside a PEP) look like statuses to a naive grep and produced a wrong report. A lint has to read the header only.

`status` already counts the known header statuses, but that is a report, not a check, and it only runs when asked.

## Specification

### Requirements

- `doctor` gains a PEP section. Each check is a warning, never a failure, so `doctor`'s exit code and the existing checks do not change.
- Checks, per file `docs/peps/pep-*.md` (the directory comes from `PEP_DIR`):
  1. **File name** is lower case, has no spaces, and matches `pep-<project>-<repo>-NNN-<type>-<slug>.md` with the project and repo codes from `.peprc`. The `<type>` word must be one the tool itself writes (read from the script's own list at check time, not copied into a second place).
  2. **Header ID** (`**ID:**`) matches the number and codes in the file name.
  3. **Header status** (`**Status:**`, header block only) is one of the known values `status` already uses: Draft, Active, Implemented, Rejected, Superseded, Informational. Case counts. Blank or missing is flagged.
  4. **Required header fields** exist: ID, Title, Author, Status, Type, Priority, Created, Updated.
  5. **Superseded** status has a `Superseded-By` that is not `N/A`.
  6. No two files share a number.
- Output is a count plus the first few offenders per check, with the fix command named where one exists (`migrate`, `fix-naming`), in the style of the existing doctor lines. `--quiet` keeps its meaning.
- Read-only. No check changes a file.
- Both scripts (`pep-tools.sh`, `pep-tools.ps1`) behave the same (PEP-PF-FWK-006).
- Constraint: no PEP content (titles, bodies) is printed, only file names and the status word, so the output is safe to paste into a ticket.

### Implementation Approach

- Add one function per script, called from the existing doctor flow after the config checks.
- Read the header with the same first-match logic `list` and `status` use, so body text is never mistaken for a header.
- Reuse the known-status list that `status` holds, moved to one shared variable so the two cannot drift.
- Offline-safe: the PEP checks need no network, so `--offline` still runs them.

### Success Criteria

- On a repo with one file name containing a space, `doctor` reports exactly one warning naming that file and suggesting the fix.
- On a repo whose PEPs are all clean, `doctor` output gains only "ok" lines and the exit code is unchanged.
- A PEP with an unknown header status is flagged; a PEP whose body contains `**Status: COMPLETE**` is not.
- Both scripts give identical results on the same repo.

## Implementation Plan

### Phase 1: Decide

- Confirm the check list above, and whether a bad file name should offer `migrate` or a new rename helper (on the repo with the space, `migrate --dry-run` reported nothing to migrate and `fix-naming --dry-run` reported 0 to fix, so neither covers it today).
- Decide where the shared status list lives.
- Dependencies: none.

### Phase 2: Build and test

- Write the checks in `pep-tools.sh`, then port to `pep-tools.ps1`.
- Add tests next to the existing doctor tests: one clean fixture, one fixture per check.
- Dependencies: Phase 1; PEP-PF-FWK-013 (doctor) is Implemented.

### Phase 3: Roll out

- `update-tools` in the work repos, then run `doctor` once in each and record which warnings appear.
- Dependencies: Phase 2. Staggered: two repos first, then the rest.

## Testing Strategy

- Fixture PEPs for each check: name with a space, upper-case name, ID mismatch, unknown status, missing field, Superseded without a replacement, duplicate number, and a body line that looks like a status.
- A clean fixture must produce no PEP warnings.
- Run both scripts against the same fixtures and diff the output.
- Before the push: the full existing test suite (it stood at 113/113 after PEP-PF-FWK-013), plus the new cases.

## Documentation Requirements

- Update the `doctor` section of the help text and the README.
- One line per check in the doctor output itself, so the output explains what to do.

## Risks and Mitigation

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Old PEPs trigger a wall of warnings | Medium | Medium | Warnings only; show a count and the first few; staggered rollout |
| The known-status list drifts from `status` | Low | Medium | One shared variable |
| The `.sh` and `.ps1` checks diverge | Medium | Medium | Same fixtures, diff the output (PEP-PF-FWK-006) |
| A check wrongly flags a legitimate type word | Low | Low | Read the type words from the tool's own list |

Backout: remove the PEP section and its call from `doctor` in both scripts (one commit to revert). `doctor` returns to its PEP-PF-FWK-013 behaviour; no PEP file is ever modified, so there is nothing to restore in the repos.

## References

- PEP-PF-FWK-013 (`doctor`), PEP-PF-FWK-006 (parity), PEP-PF-FWK-010 (`ask`, same test run)
- Vault: `00-inbox/work-pep-local-llm-test-summary-2026-11-04.md`

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.1 | 2026-11-04 | Timo Vlot | Initial draft |
| 0.2 | 2026-11-04 | Timo Vlot (with Claude) | Filled in from the 2026-11-03 work test run |
