# PEP-PF-FWK-004: AI block toggle, next and stubs, git update sources

**ID:** PEP-PF-FWK-004  
**Title:** AI block toggle, next and stubs, git update sources  
**Author:** Timo Vlot  
**Status:** Implemented  
**Type:** Feature  
**Priority:** Medium  
**Created:** 2026-08-12  
**Updated:** 2026-11-03  
**Supersedes:** N/A  
**Superseded-By:** N/A  

> Raised retroactively on 2026-11-03 from the commit history. The commits were
> labelled `chore:`; the detail below comes from their diffs.

## Abstract

An optional AI block (Claude Prompt Context) in the PEP template with `ai-block` and
`strip-ai-block` commands, `next` and `stubs` commands, and git repos as a source for
`update-tools` and `update-templates`.

## Motivation

Some repos wanted a prompt-context section in each PEP and others didn't. There was no
quick way to see what to work on next, or which PEPs were still template boilerplate.
Updates needed a local checkout of this repo as their source.

## Specification

### Requirements

- Two template variants (with and without the AI block), switched by
  `ai-block <on|off|status>`; `strip-ai-block [--dry-run]` removes the section from
  existing PEPs.
- `next`: Draft and Active PEPs by priority. `stubs [--threshold N]`: PEPs still mostly
  boilerplate.
- `update-tools` and `update-templates` accept a git URL or raw URL as `--source`.

### Implementation Approach

- `pep-template-ai.md` and `pep-template-no-ai.md` beside the active template.
- Git sources are cloned to a temporary directory and cleaned up afterwards; a raw URL
  is mapped back to its repo (`derive_git_url_from_raw`).

### Success Criteria

- A repo can switch the AI block and update from GitHub with no local checkout. Met.

## Implementation Plan

### Phase 1: AI block, next, stubs (2026-08-12)

- `90d8614`, including the setup and cookiecutter prompts for the AI block.

### Phase 2: Git sources (2026-08-13)

- `fc61b8c` git sources and blog-artifact clean-up; `1fca2d2` raw-URL handling.

## Testing Strategy

- Manual at the time. The update path got automated tests later (PEP-PF-FWK-007).

## Documentation Requirements

- Help text and the template README.

## Risks and Mitigation

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| `update-templates` overwrites a repo's AI-block choice | Medium | Happened | Fixed in PEP-PF-FWK-007 |

## References

- PEP-PF-FWK-007 (AI-block choice kept on update)

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-11-03 | Timo Vlot | Raised retroactively from commits `90d8614`, `fc61b8c`, `1fca2d2` |
