# PEP-PF-FWK-008: ask command for PEP lookups

**ID:** PEP-PF-FWK-008  
**Title:** ask command for PEP lookups  
**Author:** Timo Vlot  
**Status:** Implemented  
**Type:** Feature  
**Priority:** Medium  
**Created:** 2026-11-03  
**Updated:** 2026-11-03  
**Supersedes:** N/A  
**Superseded-By:** N/A  

## Abstract

`pep-tools.sh ask <term>` greps the repo's PEPs for a term and has a local model name
the matching PEP and title. With no model configured it prints the matches only, so
it's useful to everyone.

## Motivation

Asking a small local model "which PEP is the Neurons work?" in Zed's agent failed:
too many tools, too little context, and no idea what a PEP is. Letting grep find the
matches and giving the model only those lines needs no tool calling and works on a
small model. It also keeps to Timo's work-data rule: search snippets may go to the
homelab model; whole files may not. Inside `pep-tools.sh` it already knows the PEP
directory and ID format, and every repo gets it through `update-tools`.

## Specification

### Requirements

- `ask <term>`: case-insensitive search of the PEP directory. Per matching PEP: file
  name, ID and title lines, up to 5 matching lines.
- No match: message, exit 1.
- Settings only from `.peprc.local` (personal, gitignored), never `.peprc`, since
  repos are shared: `PEP_ASK_URL` (OpenAI-compatible base URL), `PEP_ASK_MODEL`
  (default `local`), `PEP_ASK_KEY_ENV` (name of the env var holding the key, default
  `LITELLM_MASTER_KEY`).
- The key is read only from that env var: never from a file, never printed.
- No URL, or `curl`/`jq` missing: print the matches, exit 0.
- Otherwise POST the matches to `$PEP_ASK_URL/chat/completions`, temperature 0, with a
  fixed system prompt (answer with ID and title per relevant match, say so if none
  fits). Only the snippets are sent.
- Endpoint error or timeout (60 s): print the matches and a warning, exit 2.
- The same command in `pep-tools.ps1` (the scripts stay feature-identical).

### Implementation Approach

- Reuse the script's existing PEP-directory and field helpers.
- Build the request with `jq -n` so no term or snippet is ever spliced into JSON by
  hand; pass the key to `curl` in a header read from the environment.
- Reference implementation: the bash `pepq` function in the vault runbook
  `zed-local-repo-lookups` (step 8).

### Success Criteria

- `ask ryot` in `homelab-saltstack` names PEP-HL-SLT-037 using the homelab `local`
  model.
- With no `.peprc.local` settings, the matches print and nothing calls the network.
- Tests pass with no network.

## Implementation Plan

### Phase 1: Command and tests

- `ask` in both scripts, help text, README, commented settings in the `.peprc.local`
  that `init` writes, CHANGELOG entry with the next version.
- Built 2026-11-03 on Timo's personal Mac by Claude Code (planned for the work MacBook; done here instead). Released in 2.3.

### Phase 2: Roll-out

- `update-tools` in one homelab repo, then the rest. Work repos follow their own
  branch-per-PEP routine.

## Testing Strategy

- In `tests/`, no network: no URL gives matches only; a stub `curl` on `PATH` for the
  model path; no match exits 1; an endpoint error exits 2 with the matches printed.
- Existing `tests/test-commit-msg-hook.sh` still passes.

## Documentation Requirements

- Help text, template README, CHANGELOG.

## Risks and Mitigation

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Work content reaches a hosted model | High | Low | Only snippets sent; the endpoint is personal config; use a LiteLLM alias with no hosted fallback (`lookup`) for work repos |
| Key leaks into a committed file or argv | High | Low | Read only from an env var; settings only in gitignored `.peprc.local` |
| Small model names the wrong PEP | Low | Medium | The matches are printed too, so the answer can be checked |

## References

- PEP-PF-FWK-006 (scripted commands and parity tests)
- Vault: `zed-local-repo-lookups`, `local-llm-test-plan`

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.1 | 2026-11-03 | Timo Vlot | Initial draft |
| 1.0 | 2026-11-03 | Timo Vlot | Implemented in both scripts (2.3); `tests/test-ask.sh` 30/30 against a stand-in server; settings read from `.peprc.local` only |
