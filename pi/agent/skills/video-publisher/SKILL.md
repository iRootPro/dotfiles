---
name: video-publisher
description: Use when publishing finished video to social platforms (YouTube Shorts, Reddit, Instagram Reels, TikTok) — generates platform-specific metadata, uploads via API, creates caption files with translations
---

## Overview

This skill handles publishing finished video files to social platforms. It analyzes video content, generates optimized metadata (title, description, tags), shows it for user approval, then uploads via platform APIs.

**Announcement:** "Using video-publisher to publish your video to social platforms."

## When to Use

Trigger on any of:
- "опубликуй", "выложи", "загрузи на ютуб", "upload to youtube"
- "publish this reel", "post this short"
- "выгрузи видео", "залей на ютуб"
- User has a finished .mp4 and wants to publish it
- After reels-builder completes a reel, user wants to publish it

## Supported Platforms

| Platform | Status | Method |
|----------|--------|--------|
| YouTube Shorts | Active | YouTube Data API v3 + OAuth2 |
| Reddit | Active | Manual post (caption file generated) |
| Instagram Reels | Planned | Meta Graph API |
| TikTok | Planned | TikTok Content Publishing API |

## Prerequisites

### YouTube Setup (one-time)

Check if credentials exist:
```bash
ls ~/.pi/youtube_credentials/token.json 2>/dev/null
```

If no token exists, guide the user through setup:

1. **Google Cloud Console** — https://console.cloud.google.com/
   - Create a new project (or select existing)
   - Enable "YouTube Data API v3" (APIs & Services → Library → search "YouTube Data API v3")
   - Go to APIs & Services → Credentials
   - Click "Create Credentials" → "OAuth client ID"
   - Application type: **Desktop app**
   - Download the JSON file

2. **Place credentials:**
   ```bash
   mkdir -p ~/.pi/youtube_credentials
   # User saves downloaded file as:
   # ~/.pi/youtube_credentials/client_secrets.json
   ```

3. **Authenticate (interactive, one-time):**
   Tell the user to run this command themselves (it opens a browser):
   ```
   ! python3 ~/.pi/agent/skills/video-publisher/youtube_upload.py auth
   ```
   This opens a browser for Google login → grants YouTube access → saves refresh token.

4. **Verify:**
   ```bash
   python3 ~/.pi/agent/skills/video-publisher/youtube_upload.py check
   ```

## Workflow

## YouTube Metadata Brief — Required Before Publishing

Before generating YouTube metadata, collect or infer a compact brief. If any required field is missing and cannot be confidently inferred from the video/filename/user request, ask the user before publishing.

### Required input

- **topic** — one clear phrase describing the video topic.
  - Example: `шу пуэр под мелким дождём у реки`
- **benefit / meaning** — what the viewer gets: a practical takeaway, emotional state, or reason to watch.
  - Example: `короткий чайный ритуал, чтобы переключиться и успокоиться`
- **format** — `Shorts` or `long`.
- **language** — `RU` for this channel unless the user explicitly requests otherwise.
- **target_audience** — who this is for.
  - Example: `люди со стрессом/перегрузкой`, `любители чая и slow living`, `новички в пуэре`.

### Optional input

- **keywords** — 3–7 relevant keywords.
  - Example: `шу пуэр, дождь, река, чай на природе, чайный ритуал`
- **tone** — `спокойный`, `экспертный`, `мотивационный`, `созерцательный`, etc.
- **title_limit** — default: 60 characters for Shorts, 70–90 for long videos.
- **CTA style** — `мягкий` or `прямой`.

### Metadata output contract

When generating metadata for YouTube, output this structure first, before upload approval:

1. **title_options** — 5 variants:
   - 2 practical titles: benefit + concrete context
   - 2 emotional titles: state/pain → small solution
   - 1 branded title: in the channel style (`Чай на природе` / outdoor tea ritual)
2. **description**:
   - first line: strong hook
   - one short benefit paragraph
   - soft subscription CTA
   - 3–5 relevant hashtags only
3. **pinned_comment** — one variant:
   - engagement question + CTA
4. **metadata**:
   - `primary_keyword`
   - `secondary_keywords` — up to 5
   - `risk_flags` — note if any title is too generic, clickbait-like, overpromising, or unclear

### Quality rules for YouTube metadata

- Never use generic titles like `Сегодня дома`, `#shorts #health`, `Чай на природе`, or `Красивое видео`.
- Every title must communicate clear value: result, viewer state/pain, or practical scenario.
- No medical/guarantee promises: avoid `вылечит`, `гарантирует`, `избавит навсегда`, etc.
- Description must be concise: 3–6 lines total.
- Hashtags must be topical, not spammy, and must not contain spaces.
- Do not use unrelated reach hashtags.
- For Shorts, keep titles native and clickable but not clickbait. `#shorts` may be included only if it fits the selected title/strategy; never make the title just hashtags.
- Prefer tea-literate wording. Do not make inaccurate brewing claims.

### Built-in title formulas

Use these formulas as the default title engine:

- **State/pain + micro-solution**:
  - `Тревожно? Попробуй этот ритуал на 30 секунд`
  - `Перегрузился? Завари чай и послушай дождь`
- **Context + result**:
  - `Утренний чайный ритуал для спокойного фокуса`
  - `Шу пуэр под дождём для тихой перезагрузки`

### Phase 0: Preflight — verify token can do EVERYTHING this run needs

**Run BEFORE any upload**, especially before generating metadata (so the user isn't stuck with an uploaded video and no way to post the pinned/first comment):

```bash
python3 ~/.pi/agent/skills/video-publisher/youtube_upload.py check
```

This prints `Can upload:` and `Can comment:` flags and exits non-zero if scopes are missing.

- If `Can comment: NO`, stop and tell the user to re-auth before continuing:
  ```
  ! python3 ~/.pi/agent/skills/video-publisher/youtube_upload.py auth
  ```
  Explain why: posting the pinned/first comment drives the algorithm, and once a video is up you can't easily recover that window. Better to re-auth once now than upload and paste comments manually forever.
- If the user declines to re-auth (in a hurry), proceed but note upfront in Phase 3 that the pinned/first comment will need to be pasted manually, and deliver the comment text alongside the video link at the end.
- Never silently skip the check — always run it and report the result.

**Why this scope gap exists:** older tokens were issued with only `youtube.upload` + `youtube` scopes. Posting comments requires `youtube.force-ssl`, which was added to this skill later. Existing tokens don't auto-upgrade — the user must re-run `auth` once.

### Phase 1: Analyze Video Content

Extract preview frames from the video and analyze what's in it:

```bash
# Extract 4 frames at different timestamps.
# Use awk -v for float math. Do NOT write $(dur/4): shells/awk parse that as code,
# and it fails with decimals (e.g. "BEGIN 30.046683/4").
VIDEO="path/to/video.mp4"
DUR=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$VIDEO")
mkdir -p /tmp/pi_pub_frames
for pair in \
  "2 1" \
  "$(LC_ALL=C awk -v d="$DUR" 'BEGIN{printf "%.2f", d/4}') 2" \
  "$(LC_ALL=C awk -v d="$DUR" 'BEGIN{printf "%.2f", d/2}') 3" \
  "$(LC_ALL=C awk -v d="$DUR" 'BEGIN{printf "%.2f", d*3/4}') 4"; do
  set -- $pair
  ffmpeg -y -hide_banner -loglevel error -ss "$1" -i "$VIDEO" -frames:v 1 -q:v 2 "/tmp/pi_pub_frames/pub_preview_${2}.jpg"
done
```

Read the frames to understand the content: location, activity, objects, mood, weather, time of day. Always include the actual first 1-2 seconds in the analysis, because the upload title should match the real opening hook.

Also get video metadata:
```bash
ffprobe -v quiet -select_streams v:0 -show_entries stream=width,height -show_entries format=duration -of default=nw=1 "$VIDEO"
```

**Pre-upload file sanity check:**
- Confirm the file exists and is the exact final variant requested by the user (e.g. `*_smooth_soft_bed.mp4`, not an earlier draft with similar name).
- Confirm YouTube Shorts eligibility: vertical video (`height > width`) and duration <= 60s.
- Confirm audio stream exists. For ASMR-forward uploads, note whether the filename indicates a smoothed/final audio version (`smooth`, `soft_bed`, `final`, etc.) so the wrong rough ASMR draft is not uploaded by accident.
- If multiple similar files exist in the folder, list the chosen filename in Phase 3 and do not silently substitute another file.

### Phase 1.5: Analyze Channel Performance

Before generating metadata, fetch recent video stats to learn what works:

```bash
python3 ~/.pi/agent/skills/video-publisher/youtube_upload.py recent --count 10
```

From the stats, identify:
- **Best-performing titles** — what words/patterns got the most views?
- **Optimal duration** — short (15-25s) vs long (50-60s) view counts
- **Posting time patterns** — when do videos get the most traction?
- **Engagement patterns** — which topics get the most likes/comments?

Use these insights to inform metadata generation below. Mention specific findings to the user: "Your 21s shorts average 1100 views vs 650 for 60s videos — short format is working."

### Phase 2: Generate YouTube Metadata

Based on the video content, the metadata brief, and channel performance analysis, generate metadata optimized for CTR and subscription conversion without clickbait.

#### 2.1 Build or confirm the brief

Use this brief shape internally and show it if the user asks or if fields are uncertain:

```yaml
topic: "one phrase"
benefit: "what the viewer gets"
format: "Shorts | long"
language: "RU"
target_audience: "who this is for"
keywords: ["3-7 relevant keywords"]
tone: "спокойный | экспертный | мотивационный | созерцательный | ..."
title_limit: 60
cta_style: "мягкий | прямой"
```

Defaults for this channel:
- `language: RU`
- `format: Shorts` if vertical and <= 60s
- `title_limit: 60` for Shorts
- `tone: спокойный/созерцательный` for ASMR-warm videos; `tone: динамичный/мотивационный` for TikTok-hype cuts
- `cta_style: мягкий`, unless user requests a direct CTA

#### 2.2 Generate `title_options` — exactly 5 variants

Output five title options grouped by intent:

1. **Practical 1** — concrete benefit + scenario.
2. **Practical 2** — context + result.
3. **Emotional 1** — state/pain → micro-solution.
4. **Emotional 2** — sensory/emotional hook → relief or focus.
5. **Branded** — in the channel style, recognizable as `Чай на природе` without becoming generic.

Title quality rules:
- Every title must contain clear value: result, viewer state/pain, or scenario.
- Use the built-in formulas:
  - State/pain + micro-solution: `Тревожно? Попробуй этот ритуал на 30 секунд`
  - Context + result: `Утренний чайный ритуал для спокойного фокуса`
- Keep within `title_limit` when possible.
- Russian first. Do not mix languages unless keyword strategy requires it.
- Avoid generic labels: `Чай у реки`, `Сегодня дома`, `Красивый шортс`, `#shorts #health`.
- Avoid exaggerated clickbait: `ты не поверишь`, `шок`, `это изменит жизнь`, `секрет, который скрывают`.
- Avoid medical/guarantee claims: `вылечит`, `уберёт тревогу навсегда`, `гарантирует сон`.
- For Shorts, `#shorts` is optional and strategic; do not force it into all variants. If used, it counts against readability and should not be the main value.
- Never repeat a title pattern from the last 5 videos — use recent uploads to avoid fatigue.

#### 2.3 Generate `description`

Description must be short: 3–6 lines total.

Structure:

```text
[Line 1: strong hook — result/state/context]
[1 short paragraph: what viewer gets / why this moment matters]
[Soft CTA to subscribe]
[#3-5 relevant hashtags only]
```

Rules:
- No water, no long diary paragraphs.
- CTA should be soft by default: `Если такие чайные паузы откликаются — подпишись.`
- Hashtags: 3–5 only, topical, compact, no spaces.
- Good hashtag examples: `#чайнаприроде`, `#пуэр`, `#чайныйритуал`, `#natureasmr`, `#shorts`.
- Bad hashtags: `#health` if not health content, `#viral`, `#рекомендации`, spaced hashtags like `#slow living`.

#### 2.4 Generate `pinned_comment`

One comment only:
- Ask a specific engagement question related to the video.
- Add a small CTA if natural.
- Keep it conversational, not salesy.

Examples:
- `Какой звук в чайном ритуале вам ближе: вода, чайник или первый глоток? Если любите такие паузы — подписывайтесь 🍵`
- `Вы бы заварили чай под дождём или дождались солнца?`

#### 2.5 Generate `metadata`

Output:

```yaml
metadata:
  primary_keyword: "one strongest keyword"
  secondary_keywords: ["up to 5 keywords"]
  risk_flags:
    - "empty if clean, otherwise explain: too generic / clickbait-like / overpromising / unclear value"
```

Also generate API `tags` separately for upload, using 10–20 relevant keywords. Tags may contain spaces; hashtags in description may not.

Tag base set for this channel:
- чай
- чай на природе
- чайная церемония
- outdoor tea
- tea ceremony
- nature asmr
- slow living
- shorts

Add content-specific tags: `пуэр`, `шу пуэр`, `река`, `дождь`, `первый пролив`, `gongfu tea`, etc.

#### 2.6 ASMR / tea-specific guidance

When the video is ASMR-forward (pouring, leaves, water, quiet ambience), prefer sensory and state-based angles:
- `Перегрузился? Послушай чай под дождём`
- `Шу пуэр под дождём для тихой перезагрузки`
- `30 секунд воды, чая и тишины`

Be tea-literate:
- Do not claim `первый пролив самый густой`.
- Prefer accurate process language: `промыть и разбудить чай`, `короткие проливы`, `тёмный настой`, `шу пуэр`.

### Phase 3: User Approval

Present ALL generated metadata in this clear format:

```markdown
📹 Ready to publish: [filename]
📐 Duration: Xs | Resolution: 1080x1920

## title_options

### Practical
1. [title]
2. [title]

### Emotional
3. [title]
4. [title]

### Branded
5. [title]

✅ Recommended title: [number + title]

## description
[3–6 lines]

## pinned_comment
[pinned comment]

## metadata
- primary_keyword: [keyword]
- secondary_keywords: [up to 5]
- risk_flags: [none or notes]

🏷️ API tags: [tag1, tag2, ...]
🔒 Privacy: public | scheduled private until [local time]
```

Ask the user to choose title option 1–5 or approve the recommended title. In Pi, ask directly in chat; do not reference unavailable tools such as AskUserQuestion.

If the user has already reviewed the metadata and replies with a clear confirmation (`да`, `публикуй`, `ок`, `go`), use the recommended title unless they specified another option. Do not ask for a second confirmation unless the file path, privacy, or selected title changed.

### Phase 4: Upload

After user approval, upload via the platform script:

```bash
python3 ~/.pi/agent/skills/video-publisher/youtube_upload.py upload \
  --file "path/to/video.mp4" \
  --title "Title here" \
  --description "Description here" \
  --tags "tag1, tag2, tag3" \
  --privacy public
```

**Scheduled upload:** when the user asks to publish at a future time, use `--publish-at` with an explicit timezone. YouTube requires scheduled videos to be private until the publish time; the script sets this automatically and verifies `privacyStatus` + `publishAt` after upload.

```bash
python3 ~/.pi/agent/skills/video-publisher/youtube_upload.py upload \
  --file "path/to/video.mp4" \
  --title "Title here" \
  --description "Description here" \
  --tags "tag1, tag2, tag3" \
  --publish-at "2026-05-16T19:00:00+03:00" \
  --pending-comment "Comment text to post after publication" \
  --language ru
```

For scheduled uploads, do **not** try to post the pinned/first comment immediately. Save it as `pending_comment` in the result JSON and in the publishing `.md` file, then tell the user it can be posted after the video becomes public.

### Phase 5: Post-Upload

After successful upload:
1. Show the video URL and Studio URL to the user.
2. Save/locate the upload result JSON (`.upload_result_<video_id>.json`) in the source directory for traceability. For scheduled uploads, confirm the JSON/status contains `privacyStatus: private` and the expected `publishAt` time.
3. **Post the pinned/first comment only when the video is already public.** If this is an immediate public upload and Phase 0 preflight confirmed `Can comment: yes`, auto-post the generated `pinned_comment` via the API:
   ```bash
   python3 ~/.pi/agent/skills/video-publisher/youtube_upload.py comment \
     --video-id "VIDEO_ID" \
     --text "Comment text here"
   ```
   If this is a scheduled/private upload, do not call `comment` yet. YouTube rejects comments on private/scheduled videos. Instead, save the text as `pending_comment` and show it to the user for posting after publication.

   If preflight showed `Can comment: NO` and the user chose to proceed anyway, skip the API call entirely and deliver the comment text as a code block for manual posting, with a one-line reminder to run `! python3 ~/.pi/agent/skills/video-publisher/youtube_upload.py auth` next time.

   If commenting unexpectedly fails at runtime with 403/insufficientPermissions despite preflight passing, check whether the video is private/scheduled. If yes, treat it as `pending_comment`; otherwise surface the comment text to the user immediately (don't retry silently).
4. Suggest cross-posting schedule: "Post to Instagram in 4-6 hours".
5. If batch publishing (multiple videos), schedule them with delays.
6. **Generate captions file** (`.md`) in the video's source directory with sections for each platform. This is mandatory after every upload, not optional. Name it after the video file, e.g. `short_0605_asmr_sky_smooth_soft_bed_publishing.md`:
   - YouTube URL, Studio URL, selected title, all title_options, description, tags, pinned_comment, metadata
   - **Instagram** — adapted caption, max 5 hashtags in code block, pinned/first comment text
   - **Reddit** — English title, subreddits, detailed English comment with context, Russian translation
   - See "Platform-Specific Metadata" for format details

## Posting Strategy

### Optimal Posting Times
Based on channel analytics for calm/nature content:
- **Best slot:** 20:00-22:00 (evening wind-down — viewers relaxing before bed)
- **Good slot:** 7:00-8:00 (morning commute scroll)
- **Avoid:** 12:00-16:00 (low engagement for slow-living content)

When the user doesn't specify a time, suggest evening posting. If uploading immediately, note: "Consider scheduling this for 20:00 for better reach."

### Format Mix (Content Calendar)
Short-form content dramatically outperforms long-form in views (often 2x). Recommended ratio:
- **3-4 shorts (15-25s)** per week — maximum reach, new audience
- **1 long video (45-60s)** per week — depth, retention, loyal audience

When the user has multiple videos ready (batch from reels-builder), suggest a publishing schedule:
```
Day 1 (evening): Short #1 (hook/ASMR — highest reach potential)
Day 2 (morning): Short #2 (different angle — bridge/location/cup)
Day 3: Rest (let algorithm work)
Day 4 (evening): Long video (full process)
Day 5 (morning): Short #3 (contemplation/personal)
```

### Title Diversity Check
Before generating a title, fetch the last 5 video titles from the channel. Ensure the new title:
- Uses a **different formula** from the last 3 videos (see title types table above)
- Does NOT start with the same word as any of the last 5
- Introduces at least one new element (location, weather, action, question)

If the last 5 titles all follow "[Tea type] + [place]" pattern, force a different type (question, intrigue, sensory).

## Multi-Platform Publishing

When publishing to multiple platforms from the same video:

| Step | Platform | Timing |
|------|----------|--------|
| 1 | YouTube Shorts | Immediately |
| 2 | Reddit | 1-2 hours later (different audience, no overlap) |
| 3 | Instagram Reels | 4-6 hours later |
| 4 | TikTok | Next day |

**Important:** Each platform gets its own metadata:
- Same video file
- Different description format per platform (see below)
- No watermarks from other platforms

### Platform-Specific Metadata

**YouTube Shorts:**
- Title: up to 60 chars; clear value first. `#shorts` is optional, not mandatory.
- Generate 5 `title_options`: 2 practical, 2 emotional, 1 branded.
- Description: 3–6 lines total: strong hook, short benefit, soft subscribe CTA, 3–5 topical hashtags.
- Tags: 10–20 keywords for the API field; tags may contain spaces, hashtags may not.
- Pinned comment: specific engagement question + optional soft CTA (auto-post if possible).
- Metadata: include `primary_keyword`, up to 5 `secondary_keywords`, and `risk_flags`.
- For ASMR videos, lead with sound/sensory language rather than generic place labels.

**Instagram Reels:**
- No separate title (caption only)
- Caption: same evocative text + CTA question
- **Maximum 5 hashtags** (Instagram's current recommendation, more can reduce reach)
- Hashtags at the bottom, separated by dot lines
- Save caption as `.md` file with hashtags in a code block (so `#` copies correctly)
- Format:
```
[Evocative text]

[CTA question]

.
.
.

#tag1 #tag2 #tag3 #tag4 #tag5
```

**Reddit:**
- **Language:** English only (title + comment). Include a Russian translation block in the caption file so the user understands the content.
- **Upload:** Native video upload (NOT YouTube link) — native posts get dramatically better reach on Reddit.
- **Title:** Descriptive, authentic, no clickbait. Reddit culture punishes sensationalism. Under 100 chars.
  - Good: "Brewed shu puer by the river — apricot trees just started blooming"
  - Bad: "YOU WON'T BELIEVE this tea spot!!"
- **Subreddits:** Suggest 2-3 relevant subs based on content:

| Content | Subreddits |
|---------|-----------|
| Tea (any) | r/tea, r/gongfucha |
| Coffee | r/coffee, r/pourover |
| Nature/calm | r/cottagecore, r/cozyplaces |
| ASMR/process | r/oddlysatisfying |

- **Comment (first comment, not post body):** Detailed context in English — personal story, setup details, tea type, location context. Reddit values authenticity and detail. End with an engagement question.
- **Format in caption file:**
```markdown
## Reddit Post

### Subreddits
- r/tea
- r/gongfucha

### Title
\`\`\`
[English title — descriptive, authentic]
\`\`\`

### Comment (post as first comment with context)
\`\`\`
[Personal story: what happened, why this spot, what tea]

[Setup details: teapot type, brewing style, snacks]

[Sensory moment: what made it special]

[Engagement question]
\`\`\`

### Перевод комментария на русский (для справки)
\`\`\`
[Full Russian translation of the comment above]
\`\`\`

### Crosspost note
Post video natively (not as YouTube link) for better reach.
```

**TikTok (planned):**
- Caption: shorter, punchier, under 150 chars
- Hashtags: trending + niche mix, 5-8 total
- Sound: consider trending audio overlay

## Content-Based Metadata Generation

When analyzing video frames, look for these elements to build metadata:

| Visual Element | Keywords to Add | Description Angle |
|---------------|-----------------|-------------------|
| Tea/teapot | чай, пуэр, чайная церемония, tea | Focus on the tea type and process |
| Coffee/grinder | кофе, coffee, помол | Focus on coffee preparation |
| River/water | река, river, у воды | "Sound of water" angle |
| Forest/trees | лес, forest, тропинка | "Forest calm" angle |
| Lake | озеро, lake, отражение | "Reflection" angle |
| Rain/wet | дождь, rain, после дождя | Weather as the hook — very shareable |
| Fog/mist | туман, fog, мистика | Atmospheric angle |
| Snow/frost | мороз, зима, frost, winter | Temperature contrast angle |
| Sunrise/sunset | рассвет, закат, golden hour | Time-of-day angle |
| Person sitting | медитация, созерцание, тишина | Contemplation angle |
| Close-up pour | наливание, ASMR, satisfying | Sensory/ASMR angle |
| Smoothed ASMR / soft bed | звук воды, ASMR, natural sound, soft ambience | Emphasize sound design: "сначала вода", "просто послушай", "звук первого пролива" |
| Nuts/snacks | перекус, орехи, чайная церемония | "Full ceremony" angle |

## Channel Context & Learnings

This section captures verified insights from channel analytics. Update it as new data emerges.

**Channel:** Александр Неупокоев (~1470 subs, ~258 videos)
**Niche:** Outdoor tea ceremony (чай на природе), occasional coffee

**Proven patterns (updated May 2026):**
- Shorts in the 15-35s range reliably outperform longer edits; recent 23-35s outdoor tea shorts often land around ~900-1300 views.
- Specific weather/condition in title boosts views: "после дождя", "мокрый лес" > generic "у реки"
- Variety content (coffee instead of tea) gets highest engagement rate (4.1% likes)
- Worst performer: generic titles without unique hook ("Воскресный чай у реки" — 290 views)
- Best performers: specific conditions + personal angle ("Моё утро: чай в лесу перед работой" — 839)
- Engagement (likes) peaks when there's a personal element or unusual location
- Sensory titles involving sound or specific actions perform well (e.g. кипяток, тонкая струя, пар, шум реки).
- Videos with 0 comments indicate missing CTA — always include engagement question

**Common title words to avoid overusing:** "чай", "природа", "утро" appear in almost every title. Vary the lead word.

## Error Handling

### "quota exceeded"
YouTube API has a daily quota (default 10,000 units, upload costs 1,600). Maximum ~6 uploads per day. If exceeded, wait until midnight Pacific Time.

### "authentication required"
Token expired or revoked. Re-run:
```bash
python3 ~/.pi/agent/skills/video-publisher/youtube_upload.py auth
```

### "file too large"
YouTube accepts up to 128GB / 12 hours. Shorts should be under 60 seconds. If the file is over 256MB, consider re-encoding with higher CRF (lower quality, smaller file).
