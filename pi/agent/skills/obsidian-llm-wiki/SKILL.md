---
name: obsidian-llm-wiki
description: "Maintains an LLM-powered Obsidian knowledge wiki: ingests articles, books, notes, creates summaries, concept pages, maps of content, active-recall questions, reviews, and cross-links. Use when working with personal knowledge bases, Obsidian vaults, reading notes, research notes, learning systems, or wiki maintenance."
---

# Obsidian LLM Wiki

Use this skill when the user wants to turn an Obsidian vault or a folder of markdown notes into a persistent, LLM-maintained knowledge wiki.

The goal is not just to answer questions from notes. The goal is to help the user understand, remember, connect, and reuse knowledge over time.

## Core principles

1. **Do not destroy the user's existing note-taking style.** Add an LLM-maintained layer first.
2. **Prefer additive changes.** Create indexes, maps, summaries, questions, and syntheses before editing original notes.
3. **Raw notes are sources.** Existing notes, clipped articles, book notes, transcripts, and PDFs are treated as source material.
4. **Wiki pages are compounding artifacts.** Good answers, summaries, comparisons, and reviews should be saved back into the wiki when useful.
5. **Human directs, LLM maintains.** The user curates sources and asks questions; the agent handles structure, links, summaries, bookkeeping, and review material.
6. **Respect safety boundaries.** Never mass-edit, rename, or move existing notes unless the user explicitly asks.

## Default safe mode

Unless the user gives different instructions:

- Read existing vault notes freely.
- Write new LLM-maintained files under `_llm/` in the vault.
- Do **not** modify existing notes outside `_llm/` without explicit permission.
- Do **not** rename, move, or delete files without explicit permission.
- If the vault is a git repo, prefer checking `git status` before and after non-trivial edits.

## Recommended vault structure

When initializing a vault, create this structure if it does not exist:

```text
_llm/
  AGENTS.md          # Vault-specific conventions and user preferences
  index.md           # Content-oriented index of LLM-maintained pages
  log.md             # Chronological append-only activity log
  inbox.md           # Items to process later
  review.md          # Current review queue and learning priorities

  sources/           # Source summaries for articles, books, chapters, notes
  concepts/          # Concept pages and evergreen notes
  maps/              # Maps of content by domain/topic
  syntheses/         # Higher-level analysis and comparisons
  questions/         # Active recall questions and quizzes
  reviews/           # Weekly/monthly reviews
```

## Common workflows

### 1. Initialize an Obsidian LLM Wiki layer

When the user asks to set up a vault:

1. Identify the vault path.
2. Inspect top-level files and folders.
3. Create `_llm/` structure if missing.
4. Create `_llm/AGENTS.md` with vault-specific rules.
5. Create initial `_llm/index.md`, `_llm/log.md`, `_llm/inbox.md`, and `_llm/review.md`.
6. Do not reorganize existing notes.

Use `templates/vault-agents.md` as a starting point for `_llm/AGENTS.md`.

### 2. Ingest a source

A source can be a markdown note, article, book chapter, transcript, PDF text extraction, pasted text, or URL content.

Process:

1. Read the source.
2. Determine the domain: IT, programming, networks, security, computer science, health, sport, nutrition, spirituality, business, personal, etc.
3. Create or update a source summary in `_llm/sources/`.
4. Extract key ideas, concepts, people, tools, claims, and open questions.
5. Create or update concept pages in `_llm/concepts/` when useful.
6. Update relevant maps in `_llm/maps/`.
7. Add active-recall questions to `_llm/questions/`.
8. Update `_llm/index.md`.
9. Append an entry to `_llm/log.md`.
10. Report what changed and suggest next actions.

Use `templates/source-summary.md`, `templates/concept-page.md`, and `templates/learning-questions.md`.

### 3. Answer a question from the wiki

Process:

1. Read `_llm/index.md` first if present.
2. Search relevant files in the vault.
3. Read relevant source summaries, concept pages, maps, and original notes if needed.
4. Answer with citations/links to Obsidian notes.
5. If the answer is reusable, offer to save it under `_llm/syntheses/` or `_llm/concepts/`.

### 4. Create a map of content

Use for broad topics like Security, Networks, Nutrition, Training, Spirituality, Books.

A map should include:

- scope of the topic;
- important concepts;
- relevant existing notes;
- source summaries;
- current understanding;
- contradictions or uncertainties;
- gaps in knowledge;
- recommended next reading/practice;
- review questions.

Use `templates/map-of-content.md`.

### 5. Create learning/review material

For better memory, create:

- active recall questions;
- explain-back prompts;
- flashcard-like Q/A;
- practical exercises;
- review schedule suggestions.

For IT topics, prefer practical tasks: code, CLI, lab, packet capture, debugging, threat modeling.
For health topics, prefer tracking experiments, habits, measurements, and safety disclaimers.

### 6. Weekly or monthly review

When asked for review:

1. Inspect recently modified notes and `_llm/log.md`.
2. Summarize what changed.
3. List repeated themes.
4. Identify unresolved questions.
5. Propose what to repeat.
6. Propose what to read/practice next.
7. Save review in `_llm/reviews/`.

Use `templates/weekly-review.md`.

### 7. Lint / health-check the wiki

Look for:

- orphan LLM pages;
- missing backlinks;
- duplicate concept pages;
- outdated claims;
- contradictions between pages;
- concepts that are mentioned often but lack pages;
- source summaries not represented in maps;
- review questions without answers or scheduling.

Do not automatically rewrite everything. Produce a proposed maintenance plan first.

## Language and file naming conventions

Follow the vault-specific language preference from `_llm/AGENTS.md` when present.

If the user says they work with notes only in Russian:

- Write all LLM-maintained notes in Russian.
- Prefer Russian page titles and Russian filenames for new `_llm/` files.
- Keep common technical terms in English only when natural: `slice`, `append`, `defer`, `goroutine`, `coverage`, `mTLS`, etc.
- Explanations, summaries, questions, and reviews should be in Russian.

Otherwise, prefer readable kebab-case English filenames for LLM-maintained files, unless the vault uses another convention.

Examples:

- `_llm/concepts/tcp-handshake.md`
- `_llm/maps/security.md`
- `_llm/sources/book-designing-data-intensive-applications-chapter-1.md`
- `_llm/questions/networks-active-recall.md`

Keep Obsidian links human-readable:

```md
[[tcp-handshake]]
[[security]]
```

When linking to existing user notes with non-standard names, preserve the exact note name.

## Logging format

Append entries to `_llm/log.md` with this format:

```md
## [YYYY-MM-DD] type | Title

- Source/input: [[note-name]] or path/URL
- Changed: list of created/updated files
- Key outcome: one or two sentences
- Follow-ups: optional
```

Types: `init`, `ingest`, `query`, `review`, `lint`, `map`, `maintenance`.

## Output style to user

After making changes, respond concisely with:

- what was created/updated;
- important insights;
- suggested next step;
- any safety note or uncertainty.

## References and templates

- Workflow details: `references/workflows.md`
- Source summary template: `templates/source-summary.md`
- Concept page template: `templates/concept-page.md`
- Map of content template: `templates/map-of-content.md`
- Learning questions template: `templates/learning-questions.md`
- Weekly review template: `templates/weekly-review.md`
- Vault-specific AGENTS template: `templates/vault-agents.md`
