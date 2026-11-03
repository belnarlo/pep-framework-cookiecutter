# PEP-PF-FWK-003: PowerShell port and status reporting

**ID:** PEP-PF-FWK-003  
**Title:** PowerShell port and status reporting  
**Author:** Timo Vlot  
**Status:** Implemented  
**Type:** Feature  
**Priority:** Medium  
**Created:** 2026-08-04  
**Updated:** 2026-11-03  
**Supersedes:** N/A  
**Superseded-By:** N/A  

> Raised retroactively on 2026-11-03 from the commit history. The commits were
> labelled `chore:`; the detail below comes from their diffs.

## Abstract

Added `pep-tools.ps1`, a PowerShell version of `pep-tools.sh`, richer `status`
reporting (`--since`, `--show-all`), and `fix-naming` for PEPs written with the old ID
order.

## Motivation

Windows users needed the tools without bash. Status meetings needed a summary of what
changed since a date, not just a list. Some PEPs had been written with the old
`CODES-PEP-NNN` ID order and needed repairing.

## Specification

### Requirements

- `pep-tools.ps1` with the same commands as `pep-tools.sh`.
- `status --since YYYY-MM-DD` adds a Changes section; `--show-all` lists closed PEPs in
  full instead of collapsing old ones.
- `fix-naming [--dry-run]` repairs old-order IDs.

### Implementation Approach

- Field helpers (`get_pep_field`, `get_pep_abstract`, `get_pep_num_from_file`) shared
  by the reporting commands.
- Closed PEPs older than 60 days collapse to a summary line (`days_since`).

### Success Criteria

- Both scripts give the same output for the same repo; status output pastes straight
  into a meeting post. Met: used by the meeting-agenda workflow.

## Implementation Plan

### Phase 1: Port and reporting (2026-08-04 to 2026-08-07)

- `cc2869b` PowerShell port, `status --since`, naming bug; `8d5ce9c` follow-ups;
  `ca34725` `fix-naming`.

### Phase 2: Reporting polish (2026-08-25 to 2026-08-26)

- `5fa430e` `--show-all` and the 60-day collapse; `2403f1f` colour codes fixed in
  setup, the hook and the script.

## Testing Strategy

- Manual comparison of bash and PowerShell output. Automated parity tests came with
  PEP-PF-FWK-006.

## Documentation Requirements

- Template README and help text list the new commands.

## Risks and Mitigation

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| The two scripts drift apart | Medium | High | Shared assertions in the tests (PEP-PF-FWK-006) |

## References

- PEP-PF-FWK-006 (parity tests)

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-11-03 | Timo Vlot | Raised retroactively from commits `cc2869b`, `8d5ce9c`, `ca34725`, `5fa430e`, `2403f1f` |
