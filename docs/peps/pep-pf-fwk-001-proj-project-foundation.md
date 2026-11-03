# PEP-PF-FWK-001: Project Foundation

**ID:** PEP-PF-FWK-001  
**Title:** Project Foundation  
**Author:** Timo Vlot  
**Status:** Implemented  
**Type:** Project  
**Priority:** Medium  
**Created:** 2025-09-20  
**Updated:** 2026-11-03  
**Supersedes:** N/A  
**Superseded-By:** N/A  

> Raised retroactively on 2026-11-03, when this repo started using its own PEPs.
> Written from the commit history; no plan existed at the time.

## Abstract

The framework's first working version: a cookiecutter template for new repos,
`setup-existing.sh` for existing ones, `tools/pep-tools.sh`, and the PEP and blog
templates.

## Motivation

Changes across the work and homelab repos needed one consistent way to be proposed,
numbered, tracked and linked from commits. A template repo means every project gets
the same files and commands instead of a hand-copied variant.

## Specification

### Requirements

- New repos are generated with `cookiecutter`; existing repos get the same files from
  `setup-existing.sh`.
- `pep-tools.sh` creates numbered PEPs and blogs from templates and lists them.
- Project settings live in `.peprc`.

### Implementation Approach

- Everything a generated repo receives lives under `{{cookiecutter.project_slug}}/`.
  Files at this repo's root (README, CHANGELOG, `setup-existing.sh`, `hooks/`) are the
  framework's own and are never copied.
- A `post_gen_project.py` hook finishes the generated repo.
- Bash for the CLI, so it runs on macOS and Linux with no install.

### Success Criteria

- A repo can be generated or set up and a first PEP created with `new-pep`. Met: in use
  in the work and homelab repos.

## Implementation Plan

### Phase 1: Template and setup (2025-09-20)

- `c934919` First PEP template setup; `6ec0f30` a setup default; `1927af4`
  `cookiecutter.json` update.

### Phase 2: First-use fixes (2025-09-22)

- `beab2ca` hook filename typo fixed (`post_gen_rpoject.py`), templates moved under
  `docs/templates/`; `9795bac` logic and editor fixes in `pep-tools.sh`.

## Testing Strategy

- Manual: generating a repo and running `setup-existing.sh` on an existing one. No
  automated tests at this stage.

## Documentation Requirements

- `README.md` at the root (framework) and in the template (generated repos).

## Risks and Mitigation

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Framework files leak into generated repos | Medium | Low | Only `{{cookiecutter.project_slug}}/` is copied |
| `setup-existing.sh` breaks on real repos | Medium | High | Hardened later: PEP-PF-FWK-002 |

## References

- PEP-PF-FWK-002 (setup hardening, the follow-up)

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-11-03 | Timo Vlot | Raised retroactively from commits `c934919`–`9795bac` |
