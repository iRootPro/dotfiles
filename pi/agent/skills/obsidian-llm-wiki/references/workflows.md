# Obsidian LLM Wiki workflows

## Initialization checklist

1. Confirm vault path.
2. Check whether `_llm/` exists.
3. Create missing directories:
   - `_llm/sources/`
   - `_llm/concepts/`
   - `_llm/maps/`
   - `_llm/syntheses/`
   - `_llm/questions/`
   - `_llm/reviews/`
4. Create core files if missing:
   - `_llm/AGENTS.md`
   - `_llm/index.md`
   - `_llm/log.md`
   - `_llm/inbox.md`
   - `_llm/review.md`
5. Do a shallow scan of the vault and summarize top-level structure.
6. Ask before deep processing large numbers of notes.

## Ingest checklist

For each source:

1. Identify title and stable source reference.
2. Read the source carefully.
3. Extract:
   - main thesis;
   - key ideas;
   - concepts;
   - claims/evidence;
   - practical applications;
   - links to existing notes;
   - questions for recall.
4. Write source summary.
5. Update/create concept pages.
6. Update map pages.
7. Update questions.
8. Update index.
9. Append log entry.
10. Tell the user what changed.

## Query checklist

1. Read `_llm/index.md` if present.
2. Search relevant terms across `_llm/` and the vault.
3. Read enough context to answer accurately.
4. Answer with links to notes.
5. If the answer is reusable, ask whether to save it.

## Review checklist

1. Use git or file modification dates to identify recent changes.
2. Read `_llm/log.md`.
3. Summarize recent learning.
4. Identify repeated themes.
5. Identify gaps and contradictions.
6. Generate active recall questions.
7. Propose next actions.

## Lint checklist

1. Find `_llm/` pages with few/no links.
2. Find concepts mentioned repeatedly but lacking pages.
3. Find source summaries not linked from maps.
4. Find maps that have not been updated recently.
5. Find duplicate or overlapping pages.
6. Produce a maintenance proposal before applying broad changes.
