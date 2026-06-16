# Vault-specific LLM Wiki instructions

This file configures how the LLM-maintained wiki layer works in this Obsidian vault.

## Vault path

`{{vault_path}}`

## User interests

Primary domains:

- IT: programming, networks, security/hacking, computer science
- Health: sport/training, nutrition, sleep, recovery
- Inner development: spirituality, meditation, psychology, discipline
- Books and articles across these topics

## Safety rules

- Existing notes outside `_llm/` are treated as user-owned source material.
- By default, write only inside `_llm/`.
- Do not rename, move, delete, or mass-edit existing notes without explicit permission.
- When unsure, propose changes instead of applying them.

## LLM layer structure

```text
_llm/
  AGENTS.md
  index.md
  log.md
  inbox.md
  review.md
  sources/
  concepts/
  maps/
  syntheses/
  questions/
  reviews/
```

## Preferred workflows

### Ingest

For a new article, book chapter, or note:

1. Create a source summary in `_llm/sources/`.
2. Extract key concepts.
3. Update or create concept pages in `_llm/concepts/`.
4. Update relevant maps in `_llm/maps/`.
5. Add active recall questions in `_llm/questions/`.
6. Update `_llm/index.md`.
7. Append to `_llm/log.md`.

### Review

For weekly/monthly review:

1. Inspect recent changes.
2. Summarize themes and insights.
3. Identify knowledge gaps.
4. Suggest repeat/practice items.
5. Save review in `_llm/reviews/`.

## Language policy

- The user works with notes only in Russian.
- All new LLM-maintained notes, maps, concept pages, source summaries, reviews, questions, and syntheses must be written in Russian.
- Prefer Russian page titles and Russian filenames for new `_llm/` notes.
- Technical terms may keep common English forms when natural: `slice`, `append`, `defer`, `goroutine`, `coverage`, `mTLS`, etc., but explanations should be in Russian.

## Style preferences

- Talk to the user in concise Russian.
- Use Obsidian links `[[как это]]`.
- Prefer practical examples and exercises, especially for IT/security and health topics.
