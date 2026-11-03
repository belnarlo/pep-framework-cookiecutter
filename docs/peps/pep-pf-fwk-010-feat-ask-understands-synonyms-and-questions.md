# PEP-PF-FWK-010: ask understands synonyms and questions

**ID:** PEP-PF-FWK-010  
**Title:** ask understands synonyms and questions  
**Author:** Timo Vlot  
**Status:** Draft  
**Type:** Feature  
**Priority:** Low  
**Created:** 2026-11-03  
**Updated:** 2026-11-03  
**Supersedes:** N/A  
**Superseded-By:** N/A  

## Abstract

Let ask find the right PEP for a synonym or a plain question, not only an exact word, by also giving the model a one-line-per-PEP index. Grep-only behaviour and the work-data rule stay as they are.

## Motivation

`ask` (PEP-PF-FWK-008) only finds PEPs that contain the exact term: grep picks the
matches and the model only reads them. So `ask dashboard` misses a PEP that says
"Grafana board", and `ask "which PEP moved secrets"` finds nothing, because the whole
phrase is searched. Timo wants synonyms and plain questions to work (2026-11-03).
Not urgent: the core-12 tests on the Alienware and the work question set decide first
whether the model step in `ask` earns its keep at all.

## Specification

### Requirements

- `ask` accepts a word, a phrase or a question.
- With a model configured, it can find a PEP that uses a different word for the same
  thing (synonym, abbreviation, product name vs. function).
- With no model configured, behaviour is unchanged (grep only, exact term).
- Work-data rule unchanged: only PEP IDs, titles and matched lines go to the model,
  never whole files.
- Same settings (`PEP_ASK_*` in `.peprc.local`), same exit codes; both scripts
  identical (PEP-PF-FWK-006).

### Implementation Approach

Two options, to be chosen from test results:

1. **Index:** also send the one-line-per-PEP index (ID, type, title, status, as
   `list` prints it; about 4K characters for 37 PEPs). Catches synonyms in titles
   only.
2. **Query expansion:** first ask the model for up to 5 grep keywords for the
   question (synonyms, the likely product name), grep for all of them, then answer as
   now. Catches body words too. Two model calls per question.

Option 2 with the index as extra context is the likely end state. Open questions:
cap on total matched lines sent; whether the keywords are shown to the user (they
should be, so a miss can be explained).

### Success Criteria

- `ask dashboard` finds a PEP that only says "Grafana" (fixture in the tests).
- `ask "which PEP moved secrets to Vault"` finds the right PEP in `homelab-saltstack`
  (PEP-HL-SLT-002).
- L1–L6 of the vault test set `local-llm-test-set` still pass, phrased as questions.

## Implementation Plan

### Phase 1: Decide

- After the Alienware core-12 run and the work question set: pick option 1, 2 or both.

### Phase 2: Build

- Both scripts, tests, README and CHANGELOG, as for PEP-PF-FWK-008.

## Testing Strategy

- Extend `tests/test-ask.sh`: the stand-in server returns fixed keywords for the
  expansion call; check the extra greps run and only matched lines are sent.
- Real-model check on the homelab repos against the questions above.

## Documentation Requirements

- README "Asking a model" section, CHANGELOG, help text.

## Risks and Mitigation

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Model invents keywords that match too much, so more lines go out | Low | Medium | Cap keywords and matched lines; show the keywords used |
| Two model calls make `ask` slow on a small model | Low | Medium | Expansion only when the first grep finds nothing, or a flag |

## References

- PEP-PF-FWK-008 (`ask`), PEP-PF-FWK-006 (parity)
- Vault: `20-areas/ai/local-llm-test-set.md`, `20-areas/ai/zed-local-repo-lookups.md`

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.1 | 2026-11-03 | Timo Vlot | Initial draft |
