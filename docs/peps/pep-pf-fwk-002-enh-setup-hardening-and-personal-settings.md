# PEP-PF-FWK-002: Setup hardening and personal settings

**ID:** PEP-PF-FWK-002  
**Title:** Setup hardening and personal settings  
**Author:** Timo Vlot  
**Status:** Implemented  
**Type:** Enhancement  
**Priority:** Medium  
**Created:** 2025-11-04  
**Updated:** 2026-11-03  
**Supersedes:** N/A  
**Superseded-By:** N/A  

> Raised retroactively on 2026-11-03 from the commit history.

## Abstract

Made `setup-existing.sh` reliable on real repos and on macOS, split personal settings
out of `.peprc` into a gitignored `.peprc.local`, and added `update-tools` so repos can
pull a newer `pep-tools.sh`.

## Motivation

Running `setup-existing.sh` on real repos hit problems ("ran into bother using it"),
and macOS's bash 3.2 crashed it outright. Author, editor and source path were in the
committed `.peprc`, so one person's settings were pushed to everyone. Repos had no way
to update their copy of the tools.

## Specification

### Requirements

- `setup-existing.sh` works on macOS's bash 3.2.
- Personal settings (`PEP_AUTHOR`, `DEFAULT_EDITOR`, `AUTO_OPEN_EDITOR`,
  `PEP_FRAMEWORK_SOURCE`) go in `.peprc.local`, gitignored; `.peprc` keeps shared
  project config only.
- A "no blogs" answer removes `docs/blogs`.

### Implementation Approach

- `${var,,}` replaced with `tr`-based lowercasing (bash 4 only).
- `.peprc.local.example` as the onboarding template.
- `update-tools` exits straight after replacing `pep-tools.sh`: bash reads scripts in
  chunks, so a replaced script mid-run gave spurious syntax errors.

### Success Criteria

- Setup completes on macOS; no personal settings in committed files. Met.

## Implementation Plan

### Phase 1: setup-existing.sh fixes (2025-11-04 to 2026-06-05)

- `e65c3fb`, `8a88573` setup fixes (plus `sample-pep.md`); `ceed376` project details
  in setup.

### Phase 2: Settings and updates (2026-06-05)

- `32dea6f` editor opening fixed, update option added; `0dfc194` `.peprc` /
  `.peprc.local` split; `78e8955` exit after `update-tools`.

### Phase 3: macOS and blogs (2026-06-08)

- `76cafda` bash 3.2 fix; `9885845` "no blogs" honoured in setup and the cookiecutter
  hook.

## Testing Strategy

- Manual runs of `setup-existing.sh` on macOS and on existing repos.

## Documentation Requirements

- README updates in `ceed376`; `.peprc.local.example` documents personal settings.

## Risks and Mitigation

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Personal settings committed | Low | Medium | `.peprc.local` is gitignored |
| A replaced script crashes mid-run | Medium | High | Exit right after `update-tools` |

## References

- PEP-PF-FWK-001

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-11-03 | Timo Vlot | Raised retroactively from commits `e65c3fb`–`9885845` |
