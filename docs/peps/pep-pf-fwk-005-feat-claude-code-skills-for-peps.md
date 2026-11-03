# PEP-PF-FWK-005: Claude Code skills for PEPs

**ID:** PEP-PF-FWK-005  
**Title:** Claude Code skills for PEPs  
**Author:** Timo Vlot  
**Status:** Implemented  
**Type:** Feature  
**Priority:** Medium  
**Created:** 2026-08-20  
**Updated:** 2026-11-03  
**Supersedes:** N/A  
**Superseded-By:** N/A  

> Raised retroactively on 2026-11-03 from commit `4070123`.

## Abstract

Ship Claude Code skills with the template (`draft-pep`, `pep-review`, `pep-standup`,
`write-blog`) behind an `include_claude_skills` option, plus a
`claude-skills <on|off|status>` command for repos that predate it.

## Motivation

Drafting and reviewing PEPs meant copy-pasting the Claude Prompt Context block into a
separate chat. Skills let Claude Code do it in the repo, using `pep-tools.sh` for
numbering so IDs stay consistent.

## Specification

### Requirements

- Four skills under `.claude/skills/`, installed when `include_claude_skills` is on.
- `claude-skills on|off|status` in bash and PowerShell.

### Implementation Approach

- `draft-pep` drives `new-pep` with piped input, then fills every section so the PEP
  never shows up in `stubs`.
- The cookiecutter hook removes the skills when the option is off.

### Success Criteria

- `draft-pep` produces a PEP with no template placeholders. Met: used to raise PEPs in
  the homelab repos.

## Implementation Plan

### Phase 1: Skills and command (2026-08-20)

- `4070123`.

## Testing Strategy

- Manual: drafting PEPs with the skill in generated repos.

## Documentation Requirements

- Root README section on the skills.

## Risks and Mitigation

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Skills drift from the CLI's behaviour | Low | Medium | Skills call `pep-tools.sh` instead of copying its logic |

## References

- PEP-PF-FWK-004 (the AI block the skills replace for most uses)

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-11-03 | Timo Vlot | Raised retroactively from commit `4070123` |
