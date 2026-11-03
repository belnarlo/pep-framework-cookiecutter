# PEP-PF-FWK-007: Version 2.2 fixes

**ID:** PEP-PF-FWK-007  
**Title:** Version 2.2 fixes  
**Author:** Timo Vlot  
**Status:** Implemented  
**Type:** Bug  
**Priority:** Medium  
**Created:** 2026-10-18  
**Updated:** 2026-11-03  
**Supersedes:** N/A  
**Superseded-By:** N/A  

> Raised retroactively on 2026-11-03. Detail: `CHANGELOG.md`, sections 2.2 and 2.2.1.

## Abstract

Versions 2.2 and 2.2.1: new PEPs no longer supersede themselves, `update-templates`
keeps each repo's AI-block choice, `update-tools` cleans up and rolls back safely, and
`setup-existing.sh` survives a URL in `ZABBIX_HOST`.

## Motivation

Bugs found while rolling the framework out to more homelab repos:

- `new-pep` replaced every `PEPID` in the template, so each PEP listed itself under
  Supersedes and Superseded-By.
- `update-templates` copied the default template over the active one, silently turning
  the AI block off.
- A failed download in `update-tools` could leave a broken `pep-tools.sh`.
- A URL in `ZABBIX_HOST` broke a `sed` in setup and stopped the run halfway.

## Specification

### Requirements

- Supersedes and Superseded-By default to `N/A`.
- `update-templates` refreshes the active template from the variant that matches it;
  a customised template is left alone with a warning.
- `update-tools` checks the new script parses before keeping it, otherwise restores the
  old one; removes its `.bak` on success.
- Setup's `ZABBIX_HOST` edit uses `|` as the `sed` delimiter.

### Implementation Approach

- Same fixes in `pep-tools.sh` and `pep-tools.ps1`.
- Parse check: `bash -n`, or the PowerShell parser.

### Success Criteria

- A failed update changes nothing; updates keep the AI-block choice; tests pass. Met.

## Implementation Plan

### Phase 1: 2.2 (2026-10-18)

- `dc7b62b` supersede lines; `ed584c1` AI-block choice kept; `6e00f9a` trailing space
  in `pep-template-ai.md`; `fcb4756` `update-tools` clean-up and rollback.

### Phase 2: 2.2.1 (2026-10-20)

- `f6e52c0` `ZABBIX_HOST` URL.

## Testing Strategy

- `tests/test-commit-msg-hook.sh` extended for the update paths (45 checks passing on
  2026-11-03).

## Documentation Requirements

- `CHANGELOG.md` 2.2 and 2.2.1, with a loop to fix existing PEPs' supersede lines.

## Risks and Mitigation

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Existing PEPs keep the wrong supersede lines | Low | High | Fix loop in the changelog |

## References

- PEP-PF-FWK-004 (the AI-block feature this fixes)

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-11-03 | Timo Vlot | Raised retroactively from commits `dc7b62b`–`f6e52c0` |
