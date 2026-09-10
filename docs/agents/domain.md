# Domain Docs

How the engineering skills consume this repo's domain documentation.

## Before exploring, read these

- `CONTEXT.md` at the repo root.
- ADRs in `docs/adr/` that touch the area you are about to work in.

If these files do not exist, proceed silently. Do not flag their absence or suggest creating them upfront. The `domain-modeling` skill creates them lazily when terms or decisions actually get resolved.

## File structure

This repo uses a single-context layout:

```text
/
├── CONTEXT.md
└── docs/adr/
    └── 0001-<decision-slug>.md
```

## Use the glossary's vocabulary

When your output names a domain concept in an issue title, refactor proposal, hypothesis, or test name, use the term defined in `CONTEXT.md`. Avoid synonyms the glossary explicitly rejects.

If a concept is missing from the glossary, reconsider whether it belongs to the project. Note real gaps for `domain-modeling`.

## Flag ADR conflicts

If your output contradicts an existing ADR, surface the conflict explicitly and explain why the decision warrants reconsideration.
