---
name: reels-builder
description: Use when user wants to create a vertical video story (reel/short) from phone clips (MOV/MP4) — scanning source files, selecting moments, assembling with crossfades and background music
---

## Overview

This skill guides the assembly of vertical video stories (reels/shorts) from iPhone MOV/MP4 clips. The result is a ready-to-run bash script that handles color correction, slow motion, crossfade transitions, and audio mixing with background music.

**Announcement:** "Using reels-builder to assemble a vertical video story from your clips."

## Pi + Codex Notes

This skill is adapted for Pi with the OpenAI Codex provider. Use Pi's available tools (`bash`, `read`, `write`, `edit`) for scanning files, generating scripts, and running ffmpeg/ffprobe commands.

When invoking this skill explicitly in Pi, use:
```text
/skill:reels-builder <папка с клипами или задача>
```

Always communicate progress and choices to the user in Russian when the surrounding project/session requires Russian. Do not silently pick format, hook, audio mode, music, or segment order — ask for confirmation first.

## When to Use

Trigger on any of:
- "собери ролик", "сделай reels", "монтаж видео", "сделай историю из видео"
- "make a reel", "assemble clips", "build a video story"
- User points to a folder with MOV/MP4 files and wants a montage
- User asks to combine phone clips into a short vertical video

## Video Formats

Before starting assembly, determine the reel format. Different formats serve different goals:

### Format A: "Hook" (15-20 sec) — Maximum reach
Best for: going viral, attracting new viewers. Short = high completion rate = algorithm boost.
```
0-2s:  Close-up + ASMR sound (pouring, steam, crackling) — HOOK
2-6s:  Action (hands, process)
6-12s: Landscape + context (where we are)
12-18s: Payoff (first sip, steam from cup, slomo)
18-20s: Loop frame (visually connects to first frame)
```
- 7-8 cuts, 2-3 seconds each
- One 4-second "hero hold" for the payoff shot
- Crossfade duration: 0.3s (tighter transitions)

### Format B: "Journey" (25-35 sec) — Follower growth
Best for: building audience, deeper engagement. Shows the full arc: effort → reward.
```
0-2s:  Hook (sound/close-up)
2-8s:  The path (trail, walking, forest)
8-16s: Setup (unpacking, arranging)
16-24s: Process (brewing, pouring, slomo)
24-30s: Result (cup, steam, landscape)
30-35s: Closing (pull-back / loop point)
```
- 9-12 cuts, 2-4 seconds each
- Crossfade duration: 0.5s

### Format C: "Full Process" (45-60 sec) — 1 in 5 videos
Best for: established audience, deep engagement. Current format, but MUST have a strong hook in the first 2 seconds (not a landscape opener).
- 8-12 cuts, 3-6 seconds each
- Crossfade duration: 0.5s

### Format D: "TikTok / Hype Cut" (13-25 sec) — Experimental reach
Best for: testing a younger / faster Shorts-Reels-TikTok style without replacing the calm ASMR brand. Use when the user asks for "драйвовое", "хайповое", "динамичное", "молодёжное", "TikTok-style", or wants to test a different edit from the same footage.
```
0-2s:   Immediate action hook (pouring, breaking tea, kettle hit) + short title text
2-7s:   Fast tactile sequence (tea, hands, water) with hard cuts / flash accents
7-12s:  1-2 very short location/rain/context flashes
12-18s: Main payoff (dark pour / steam / cup / sip)
18-25s: Soft final thought or loop back to the hook
```
- 12-18 cuts, usually 0.8-1.8 seconds each
- Prefer hard cuts over crossfades; use very short white flash transitions (0.04-0.07s) sparingly
- Use speed-up / speed-ramp feeling: `setpts=0.72-0.92*PTS` for most action segments
- Use subtle punch-in / crop motion / micro-shake for energy, not heavy distortion
- Keep the output as a separate experimental file (`*_dynamic_hype*`, `*_tiktok*`, `*_soft_text*`) and never overwrite the warm ASMR versions

**Brand rule:** The channel can have two lanes:
- `asmr-warm` — warm, slow, natural, meditative, smooth sound-first tea videos
- `tiktok-hype` — faster, modern, text-led, but still tea-literate and not fake/overhyped

**Ask the user which format to use, or suggest batch generation (multiple formats from the same clips).**

## Hook Types

The first 1-3 seconds determine whether a viewer stops scrolling. Always discuss hook choice with the user.

| Hook | First Frame | Effect | Best For |
|------|------------|--------|----------|
| `closeup` | Extreme close-up of action (steam, pour, flame) | Visual scroll-stop | Most reels |
| `sound` | 1-2s pure ASMR sound (click, crunch, water) with close-up | Audio hook | ASMR audience |
| `wide-to-close` | 0.5s landscape → hard cut to close-up | Scale contrast | Journey format |
| `motion` | Start mid-action (already pouring, already walking) | Immediate dynamics | Short hooks |

**Default hook: `closeup`.** The establishing landscape shot should come AFTER the hook, not before.

When building the segment list, the hook clip must be placed first and should be a close-up action shot (hands, teapot, pouring, fire). Move landscape/path shots to position 2-3.

## Loop Point

To maximize rewatches (strongest algorithm signal), the last 0.5-1s of the video should visually connect to the first frame. Implementation:

**Option 1: Visual match** — Last segment ends on a similar composition to the first (e.g., both are close-ups of the teapot, or both show the same landscape angle).

**Option 2: Fade loop** — Add a 0.5s fade-to-black at the end and 0.5s fade-from-black at the start. When the video loops on Instagram/YouTube, this creates a smooth breathing transition.

Technical implementation for fade loop:
```bash
# Add to the final assembled video:
# Fade in from black at start (0.5s) + fade out to black at end (0.5s)
-vf "fade=t=in:st=0:d=0.5,fade=t=out:st=${FADE_OUT_START}:d=0.5"
-af "afade=t=in:st=0:d=0.5,afade=t=out:st=${FADE_OUT_START}:d=0.5"
```

## Batch Generation

From a single filming session (one folder of clips), propose multiple reels:
- 2-3 "Hook" reels (15-20s) — each uses 3-4 different clip selections
- 1 "Journey" reel (25-35s)
- 1 "Full Process" reel (45-60s) — only if enough varied footage

This turns one outdoor session into 4-5 content pieces instead of a single 60-second reel. Present the batch plan to the user and generate separate scripts (or one script with multiple outputs).

## YouTube Shorts Retention Workflow

When the user asks specifically for a YouTube Short / Shorts-oriented edit, the skill must act as a retention editor, not only as a montage tool. The goal is to produce Shorts that hold attention and logically lead to one clear subscription / engagement action.

### Required Inputs

Collect or infer these before rendering:

- **Raw clips** — folder path or explicit file list
- **Topic** — what the Short is about in one sentence
- **Desired duration** — e.g. 20-35 seconds
- **Style** — e.g. calm, atmospheric, minimalist, ASMR-warm, tiktok-hype
- **Voice** — voiceover yes/no; if yes, script/tone; if no, rely on text and sound design
- **Music** — yes/no, mood, reference track or choose from available music folder
- **CTA** — the exact final action, e.g. subscribe, comment, save, watch next; only one CTA per Short

If the user omits some of these, infer sensible defaults and state them clearly before building. For this channel's tea/nature content, good defaults are:
- duration: 20-35s
- style: calm / atmospheric / minimalist unless user requests hype
- voice: no voice, use text overlays + ASMR
- music: quiet bed for ASMR-warm, stronger beat for tiktok-hype
- CTA: soft subscribe / comment prompt, never multiple CTAs

### Required Planning Output

Before rendering a Shorts-oriented edit, produce these planning artifacts in the chat or in a saved markdown file next to the build script:

#### 1) `edit_plan`

A second-by-second structure with retention intent:

```text
0-2s: hook — first visual/text/audio reason to stop scrolling
2-15s: development — process, motion, question, progression
15-28s: payoff / meaning — strongest visual, result, insight, emotional point
final 2-3s: CTA — one clear action, visually readable
```

Rules:
- The first frame and/or first text must hook within 1 second.
- The opening shot should be action or visual tension, not a generic landscape.
- Every 2-4 seconds must introduce some movement, new information, or emotional shift.
- The edit must answer: **"why watch until the end?"** Examples: to see the pour, the taste moment, the weather payoff, the before/after, the answer to a question, or the final CTA.

#### 2) `shot_selection`

List selected and rejected clips:

```text
Selected:
- IMG_0001.MOV 00:05-00:07 — pour hook; chosen because liquid motion is immediate
- IMG_0004.MOV 00:01-00:03 — hands/tea texture; chosen because tactile ASMR

Rejected:
- IMG_0002.MOV — too static / no meaningful motion
- IMG_0003.MOV — duplicate angle / weaker light / wind noise
```

For every selected shot, explain why it serves hook, development, payoff, or CTA. For every rejected shot, give a practical reason: too static, duplicate, shaky, weak audio, bad framing, too long, no story value.

#### 3) `text_overlays`

Specify on-screen text by timecode:

```text
0.3-2.5s: "ШУ ПУЭР" / "МЕЛКИЙ ДОЖДЬ"
4.1-6.8s: "СНАЧАЛА ПРОМЫТЬ" / "И РАЗБУДИТЬ ЧАЙ"
18.0-22.5s: "ПОГОДА СТАЛА" / "ЧАСТЬЮ ВКУСА"
```

Rules:
- 3-7 words per screen maximum.
- No paragraph text.
- Text must be readable on a phone: strong contrast, safe-zone aware, visible for at least ~1.2s unless intentionally used as a flash.
- For `tiktok-hype`, approved default style is Onest-800 native Shorts typography (see Dynamic TikTok / Hype Style section).
- For calm/minimalist styles, use fewer text moments and softer wording.
- Do not overload the video: if the visuals already explain the moment, let the shot breathe.

#### 4) `audio_plan`

Describe sound design by segment:

```text
0-2s: no fade-in; immediate water/tea sound + music already audible
2-12s: music bed low; keep tactile clip sounds louder on hand/tea/water moments
12-20s: reduce wide/wind ambience; emphasize pour or cup sound
final: music fades out 1.5-2.5s; CTA remains readable
```

Rules:
- Decide where there is intentional quiet, music, ASMR, or accent sound.
- Avoid perceived silence in the first second unless silence itself is the hook.
- For ASMR-warm: source sounds lead, music is a soft bed.
- For tiktok-hype: music/beat leads, but tactile ASMR hits remain audible.
- Remove wind rumble and normalize loudness so the Short does not feel amateur.

#### 5) `export_presets`

Always include export targets:

```text
resolution: 1080x1920
fps: 30 or 60000/1001; use 30fps if user explicitly wants standard YouTube Shorts export
codec: H.264, yuv420p, faststart
audio: AAC 192k, normalized / limited
text_safe_zone: keep important text away from top/bottom UI; prefer central/lower-middle, avoid bottom 250px and right-side UI area
max_duration: <= 60s for Shorts
```

Technical defaults for this skill still use 60000/1001 fps for iPhone/xfade compatibility. If the user explicitly requires 30fps export, add a final delivery transcode to 30fps after the edit is assembled.

### Mandatory Quality Rules

These apply to every YouTube Shorts-oriented render:

- First frame/text must catch attention within 1 second.
- No long empty fragments without meaningful movement.
- Do not overload with text.
- Every Short must answer: **"why watch this to the end?"**
- The ending must have exactly one clear CTA.
- The CTA must fit the content and tone: soft for calm tea/nature, direct for hype/educational content.
- If the plan does not contain a strong hook, payoff, and CTA, revise the plan before rendering.

## Workflow

### Phase 0: Scan

Find all source clips and gather metadata.

1. Glob for `**/*.{MOV,mov,MP4,mp4}` in the target directory
2. Run `ffprobe` on each file to extract:
   - Duration
   - Resolution (width × height)
   - Orientation (portrait/landscape)
   - Creation date
   - **Has audio stream** — check if audio stream exists (some iPhone clips, especially timelapse/slo-mo, may have no audio)
3. Generate a preview frame from each clip:
   ```bash
   ffmpeg -ss 1 -i "$clip" -frames:v 1 -q:v 2 "${clip%.MOV}_preview.jpg"
   ```
4. **Analyze audio quality** of each clip to recommend keep/mute:
   ```bash
   # Volume levels
   ffmpeg -i "$clip" -t 10 -af "volumedetect" -f null /dev/null 2>&1 | grep -E "mean_volume|max_volume"
   # Zero-crossing rate (high ZCR = wind/hiss noise, low ZCR = nature/ambient)
   # Use python3 with wave module to compute ZCR from a short WAV extract
   ```
   Classification guide:
   - **Keep**: mean_volume > -50dB AND ZCR < 400Hz → likely nature sounds (birds, water, ambient)
   - **Mute**: ZCR > 800Hz → wind/hiss noise
   - **Mute**: mean_volume < -55dB → too quiet to matter
   - **Mute**: max_volume spike > 20dB above mean → sudden unwanted noise
5. Present a summary table to the user: filename, duration, resolution, orientation, audio quality recommendation

### Phase 1: Format & Clip Selection

First, determine the reel format (see "Video Formats" above). Ask the user or suggest based on available footage. For batch generation, plan multiple reels from the same clips.

Then interactively select moments with the user. Do NOT proceed silently — discuss each choice.

For each selected moment, record:
- **Source file** — which MOV/MP4
- **Start–End** — timecodes (e.g. `00:12–00:18`)
- **Scene description** — brief label for reference
- **Speed** — `normal` or `slomo`
- **Audio** — `keep` or `mute` (based on Phase 0 audio analysis)
- **Role** — `hook` / `action` / `landscape` / `payoff` / `closing`

Multiple segments from the same source file are allowed — useful for different moments or angles from one continuous clip.

**Segment duration guide by format:**
- Format A (15-20s): segments 2-3s each, 7-8 total
- Format B (25-35s): segments 2-4s each, 9-12 total
- Format C (45-60s): segments 3-6s each, 8-12 total

**Duration budget math (CRITICAL — check BEFORE extraction):**

Crossfades eat `(N-1) × XD` seconds. For N=12 segments with XD=0.5, that's 5.5s lost.

```
effective_total = sum(segment_durations) - (N - 1) × XFADE_DURATION
```

Verify `effective_total >= user_target` BEFORE running extraction. If short, add segments or extend existing ones. Finding out after a 10-minute render that the reel is 24.8s instead of 30s wastes time.

**Per-segment duration cap (CRITICAL):**

For every segment, verify `ss + duration <= source_clip.duration`. When the requested range exceeds the clip, ffmpeg silently produces a shorter segment (e.g. requesting `-ss 0 -t 2.5` on a 0.84s clip yields 0.85s output). This silently shrinks the reel below the user's target.

Before extraction, for each selected segment run:
```bash
SRC_DUR=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$SRC")
AVAILABLE=$(LC_ALL=C awk "BEGIN{printf \"%.3f\", $SRC_DUR - $SS}")
# Require AVAILABLE >= DUR; otherwise warn and either shorten SS or drop the segment
```

Short iPhone clips (< 2s) often come from brief taps — flag them at scan time and exclude from candidates unless the user explicitly picks them.

Ask the user:
- Which format (A/B/C) or batch
- Which hook type (closeup/sound/wide-to-close/motion)
- Which clips to include and in what order
- Which moments within each clip (start/end times)
- Whether any segments should be slow motion
- Confirm audio keep/mute recommendations from Phase 0

### Phase 2: Script Generation

Generate a single `build_story.sh` bash script that:
- Extracts each selected segment with color correction and speed adjustment
- Applies crossfade transitions between segments
- Mixes clip audio with background music
- Produces the final output file

**Output file location:** Always save the final `.mp4` in the same source directory the user pointed to (the dated folder with clips). For example, if source clips are in `Чай на природе/24.03.2026/`, the output goes to `Чай на природе/24.03.2026/reel.mp4`. The `build_story.sh` script itself goes in the parent project directory.

The script should be self-contained, well-commented, and idempotent (safe to re-run).

Structure:
```bash
#!/usr/bin/env bash
set -euo pipefail

# === Config ===
# (all parameters in variables at the top)

# === Float math helper ===
calc() { LC_ALL=C awk "BEGIN{printf \"%.6f\", $1}"; }
# NEVER use `bc` — it breaks on decimal numbers depending on locale
# CRITICAL: LC_ALL=C is required — without it, some locales use comma as
# decimal separator (e.g. "4,000000" instead of "4.000000"), which breaks
# ffmpeg filter strings (xfade offset=3,504 is parsed as two arguments)

# === Phase 1: Extract segments ===
# (one ffmpeg command per segment)
# CRITICAL: -t BEFORE -i (input duration limit, not output!)
# CRITICAL: Always add -r 60000/1001 -video_track_timescale 60000 to ALL segments
#           (iPhone clips may have different timebases; xfade requires matching tbn)

# === Phase 2: Probe actual durations ===
# (ffprobe each segment, store in variables DUR_0, DUR_1, ... — NOT arrays)

# === Phase 3: Crossfade assembly ===
# (calculate xfade offsets from PROBED durations, not expected)
# Use simple sequential filter labels: [v1], [v2], ... and [a1], [a2], ...
# Write filter to file, pass via -filter_complex "$(cat file)"
# NOTE: -filter_complex_script is DEPRECATED in modern ffmpeg — use $(cat) instead

# === Phase 4: Audio mix ===
# (combine clip audio with background music)

# === Cleanup ===
# (remove temp files)
```

**Two-stage render pattern (RECOMMENDED):**

Split the final ffmpeg invocation into two stages rather than one giant filter_complex:

1. **Stage 1 — Stitch:** `seg_*.mp4` → `stitched.mp4` via `xfade` + `acrossfade`. Uses clip audio only (with highpass/compand on kept, silence on muted). Video encode happens here.
2. **Stage 2 — Mix:** `stitched.mp4` + `music.mp3` → `final.mp4` via `amix`. Video is `-c:v copy` (no re-encode), only audio is rebuilt.

Benefits:
- **Fast music iteration.** Swapping the music track or adjusting volumes re-runs only stage 2 (seconds, not minutes).
- **Fewer filter graph variables.** xfade offsets and amix ducking don't need to coexist in one filter.
- **Debuggable.** If the mix sounds wrong, you can listen to `stitched.mp4` in isolation to isolate which stage is broken.

Stage 2 skeleton:
```bash
FADE_OUT_START="$(calc "${TOTAL} - 2.5")"
MIX_FILTER="[0:a]volume=0.55[ca];[1:a]volume=0.32,afade=t=out:st=${FADE_OUT_START}:d=2.5[m];[ca][m]amix=inputs=2:duration=first:dropout_transition=0[aout]"

ffmpeg -y -i "${TMP}/stitched.mp4" -i "${MUSIC}" \
  -filter_complex "${MIX_FILTER}" \
  -map 0:v -map "[aout]" \
  -t "${TOTAL}" \
  -c:v copy -c:a aac -b:a 192k -movflags +faststart \
  "${OUT}"
```

**IMPORTANT: The script MUST be invoked via `/bin/bash script.sh`, never sourced in zsh.**

**ASMR smoothing render pattern (CRITICAL for ASMR-forward reels):**

When audio mode is `asmr` or `asmr-soft-bed`, generate an additional smoothing stage rather than relying only on the audio produced by `acrossfade`. This is especially important when the user says transitions sound obvious, harsh, or "склейки слышно".

Recommended structure:
1. **Stage 1 — Video stitch:** create `stitched.mp4` normally and keep `segment_00.mp4`, `segment_01.mp4`, ... in the temp directory.
2. **Stage 2 — Smooth ASMR rebuild:** copy video from `stitched.mp4`, but rebuild audio from the individual segment audio streams. Delay each segment to its visual start time, add per-segment `afade` in/out, role-based volume, wind filtering, limiter, then `amix` all streams together.
3. **Optional bed:** for `asmr-soft-bed`, add a very quiet continuous music/ambience bed (`volume=0.08-0.16`) with no fade-in and a 2.5s fade-out. The bed should mask room-tone changes without becoming the main soundtrack.
4. **Fast iteration:** create at least two audio-only variants using `-c:v copy`: `strong_asmr` and `soft_bed`. This takes seconds and lets the user choose by feel.

Start times after crossfades:
```bash
# START_0 is always 0. For segment i > 0:
# START_i = sum(DUR_0..DUR_{i-1}) - i * XFADE_DURATION
START_0="0.000000"
START_1="$(calc "${DUR_0} - ${XD}")"
START_2="$(calc "${DUR_0} + ${DUR_1} - 2*${XD}")"
```

Smooth ASMR filter shape:
```bash
# input 0 = stitched video, input 1 = optional music bed,
# inputs 2..N = segment_00.mp4..segment_N.mp4
# delay is START_i in milliseconds
[2:a]highpass=f=200,volume=0.90,afade=t=in:st=0:d=0.05,afade=t=out:st=${FADE_OUT_0}:d=0.85,alimiter=limit=0.90,adelay=${DELAY_0}:all=1[a0];
[3:a]highpass=f=200,volume=0.75,afade=t=in:st=0:d=0.45,afade=t=out:st=${FADE_OUT_1}:d=0.85,alimiter=limit=0.90,adelay=${DELAY_1}:all=1[a1];
[1:a]volume=0.12,afade=t=out:st=${FADE_OUT_START}:d=2.5[m];
[a0][a1]...[m]amix=inputs=${N}:duration=longest:normalize=0,highpass=f=80,alimiter=limit=0.92[aout]
```

For pure `asmr`, omit `[m]` and the music input, but still use delayed per-segment audio with fades. Do not make the ambience clips as loud as action clips.

### Phase 3: Color & Style

Present color preset options to the user:

| Preset | Description |
|--------|-------------|
| `warm` | Warm tones, slightly boosted saturation — good for golden hour, cozy scenes |
| `natural` | Minimal correction, gentle contrast lift |
| `vintage` | Desaturated, warm temperature, vignette — retro film look |
| `cold` | Cool blue tones, clean contrast — winter, water, urban |

Ask the user which preset to apply (or `none` for no correction).

**Per-segment color override for skin tones:** The `warm` preset adds red shift (`colorbalance=rs=0.04`) and high saturation (`1.15`) which makes human skin unnaturally red. When a segment contains people/faces, automatically override to `natural` preset for that segment. Note this in the discussion with the user — don't silently apply warm to face shots.

### Dynamic TikTok / Hype Style

When generating a `tiktok-hype` variant, keep the tea aesthetic but increase momentum:

**Video effects:**
- Start with action, not landscape: pouring tea, water into pot, breaking tea, opening wrapper.
- Use short segments (0.8-1.8s) and hard cuts. Avoid long crossfades.
- Use `setpts=0.72-0.92*PTS` to speed up most clips; keep sip/human payoff closer to normal speed (`0.90-1.0*PTS`).
- Add subtle motion to static footage with `scale=1210:2152,crop=1080:1920` and small crop offsets; use micro-shake only on 1-3 cuts.
- Use very short white flash transitions (`fade=t=in/out:d=0.04-0.07:color=white`) on beat accents.
- Color can be more punchy than ASMR: contrast `1.12-1.18`, saturation `1.12-1.22`, `unsharp=5:5:0.7-0.9`. Do not overdo skin tones.

**Text overlays for modern style:**
- Approved default for `tiktok-hype`: **native Russian Shorts typography**, not cards. Use large centered text directly on the video, with a subtle dark horizontal band behind the text area. This felt much less foreign than translucent UI cards.
- Approved font: **Onest weight 800**. If only the Google variable font is available, instantiate it to a static font first (e.g. `fonttools varLib.instancer Onest[wght].ttf wght=800 -o Onest-800.ttf`). In this project the approved font lives at `Май/11.05.2026/_instanced_fonts/Onest-800.ttf`.
- Approved visual recipe for 1080x1920:
  - dark band: `rectangle 0,1210 1080,1580`, fill around `#00000034`
  - title: Onest-800, all caps, centered, white fill `#FFFFFF`, black stroke `#000000C8`, stroke width `5`, shadow offset about `+4+4` with `#00000099`
  - subtitle/accent line: Onest-800, centered, warm yellow fill `#F2D35F`, same black stroke/shadow
  - opening title sizes: title ~90px, subtitle ~70px
  - process/final lines: title ~66-88px, subtitle ~58-62px depending on phrase length
  - fade text in/out quickly (`0.12-0.18s`) so it feels native to Shorts
- Avoid the styles that were rejected as too foreign/dirty: large translucent rounded cards, centered text inside grey UI blocks, thick vertical bars, neon/cyber accents, small editorial lower-third cards, or generic template-looking bubbles.
- Use big, short, readable phrases. For this channel, the approved wording style is tea-literate but still Shorts-native:
  ```text
  ШУ ПУЭР
  МЕЛКИЙ ДОЖДЬ

  СНАЧАЛА ПРОМЫТЬ
  И РАЗБУДИТЬ ЧАЙ

  ПОТОМ
  КОРОТКИЕ ПРОЛИВЫ

  У РЕКИ ВКУС
  ПОЧЕМУ-ТО ГЛУБЖЕ

  ПОГОДА СТАЛА
  ЧАСТЬЮ ВКУСА
  ```
- Text should remain tea-literate. Do not claim "первый пролив самый густой" for gongfu / puer; first infusion is often a rinse. Prefer accurate lines like "сначала промыть и разбудить чай" and "потом короткие проливы".
- For CTAs, avoid pushy lines like "ты бы остался?" if they feel too clickbaity. Softer ending statements often fit this channel better: "погода стала частью вкуса", "иногда дождь — часть церемонии", "и уходить уже не хочется".

**Implementation note:** If ffmpeg lacks `drawtext`, generate transparent full-frame PNG overlays with ImageMagick (`magick -size 1080x1920 xc:none ...`) and apply them with `overlay`, including alpha fades. This was used successfully in `build_short_11052026_v12_onest_shorts_text.sh`.

### Phase 4: Audio Design

Present audio modes to the user:

| Mode | Description | Best For |
|------|-------------|----------|
| `asmr` | Natural sounds only, no music. Enhanced: pouring, steam, crunch, birds | Maximum engagement & saves. ASMR content has the highest save-to-view ratio |
| `asmr-soft-bed` | ASMR-forward, but with a very quiet continuous ambience/music bed that masks clip-to-clip room-tone changes | Outdoor phone clips where pure ASMR exposes audible transition seams |
| `hybrid` | Nature sounds 60-70% + quiet music 30-40% | Main mode, balance of atmosphere and audio completeness |
| `music` | Music-driven, clip audio quiet or muted | Atmospheric landscape reels, music-synced edits |
| `tiktok-hype` | Beat/music-forward, clip ASMR kept as tactile hits under the music | Dynamic youth-style experiments, TikTok/Reels tests |

**Default recommendation: `hybrid`** for most reels. Suggest `asmr` for close-up/process reels with good source audio recorded in one consistent environment. For multi-clip outdoor phone footage, prefer `asmr-soft-bed` over pure `asmr` unless the source audio is very consistent.

Then ask:
1. Audio mode (asmr / hybrid / music)
2. If hybrid/music: background music file path, or pick from available
3. If hybrid/music: sync transitions to musical beats?
4. Fade in/out durations for music (default: **0s in, 2.5s out** — see below)

**"No silence at start" is the default.** A 3s music fade-in creates perceived silence over the opening hook — the exact moment viewers decide to keep watching. Unless the user explicitly asks for a fade-in, music should start at full volume on frame 1. The fade-out at the end is fine.

When the user says "music starts immediately", "no silence at the beginning", "начинай сразу" or similar — that confirms `afade=t=in` should NOT be applied to the music track. Apply only the fade-out:
```bash
# Correct: music starts at volume 0 cold, fades out at end
[1:a]volume=0.30,afade=t=out:st=${FADE_OUT_START}:d=2.5[m]
```

Verify the picked music track has audible content in its first 500ms (not a silent intro):
```bash
ffmpeg -i "$music" -t 0.5 -af "volumedetect" -f null /dev/null 2>&1 | grep mean_volume
# mean_volume > -25dB = good, immediate sound
# mean_volume < -40dB = silent intro, pick a different track or ffmpeg-trim the intro
```

**Audio levels by mode:**

| Mode | Clip audio (good) | Clip audio (muted) | Music | Mix method |
|------|-------------------|-------------------|-------|------------|
| `asmr` | role-based: action 0.75-1.0, wide/wind/person 0.25-0.5 | volume=0 | none | Smoothed per-segment ASMR mix |
| `asmr-soft-bed` | role-based: action 0.65-0.85, wide/wind/person 0.25-0.4 | volume=0 | volume=0.08-0.16 | Smoothed per-segment ASMR + continuous bed |
| `hybrid` | volume=0.55 (~-5dB) | volume=0 | volume=0.20 (~-14dB) | amix, duration=first |
| `music` | volume=0.15 (~-16dB) | volume=0 | volume=0.30 (~-10dB) | amix, duration=first |
| `tiktok-hype` | volume=0.30-0.40 for tactile hits | volume=0 | volume=0.24-0.30 | amix, duration=first, hard cuts |

**ASMR mode audio processing:**
For `asmr` / `asmr-soft-bed`, do NOT simply run one equal-volume `acrossfade` chain and call it done. Outdoor iPhone clips often have different wind, room tone, river level, hand noise, and mic direction; if every segment is equally loud, the viewer hears the ambience change at every cut.

Use a **role-based ASMR mix**:
- `hook` / `action` / `pouring` / `tea leaves`: louder (`volume=0.75-1.0`)
- `landscape` / `wide river` / `windy ambience`: softer (`volume=0.25-0.45`)
- `person/sip` clips: medium-low (`volume=0.35-0.55`) unless the sip sound is clean
- bad wind/hiss clips: mute or keep only under a bed

Apply light compression to even out dynamics:
```bash
# Compression: smooth out loud/quiet differences
-af "highpass=f=200,compand=attacks=0.2:decays=0.7:points=-80/-80|-50/-36|-30/-20|-12/-9|0/-7:gain=4,alimiter=limit=0.90"
# Optional subtle reverb (if ffmpeg has aecho):
-af "aecho=0.8:0.88:60:0.25"
```

**Wind removal for outdoor ASMR (CRITICAL for phone clips):**

Phone mics pick up wind as low-frequency rumble even on seemingly calm days. When Phase 0 audio analysis shows `max_volume` spikes 15dB+ above `mean_volume` on clips shot outdoors, apply a highpass filter at 200Hz to the kept clip audio. This preserves action ASMR (pouring water, breaking tea cake, paper unwrapping) while killing wind rumble — preventing the `amix` stage from ducking the music under wind noise.

```bash
# Outdoor ASMR chain: wind removal → dynamics → level
-af "highpass=f=200,compand=attacks=0.3:decays=0.8:points=-80/-80|-45/-30|-20/-15|0/-10:gain=3,volume=0.75"
```

Apply this chain whenever `keep_audio=1` on outdoor segments. For indoor clips with a clean mic, drop the highpass (200Hz cut removes bass warmth that matters indoors).

Present the audio analysis results from Phase 0 as a table and let the user confirm which segments to keep/mute before generating the script.

**Music beat analysis (when syncing to music):**

Analyze the music energy profile to identify structure and key moments:
```python
# Convert to WAV, compute energy in 250ms windows
# Identify: quiet sections, main sections, peaks
# Map video segments to music sections:
#   quiet intro → establishing shots (nature, travel)
#   main section → setup, preparation
#   peak energy → key action, climax
```

Adjust segment durations so crossfade transitions align with musical accents. Calculate desired transition timestamps first, then derive segment durations:
```
d_0 = t_0 + XD
d_k = t_k - t_{k-1} + XD   (for k >= 1)
```
Where `t_k` is the desired timestamp of transition k.

### Phase 5: Build & Verify

1. Run the generated `build_story.sh`
2. Verify output with `ffprobe`:
   - Correct resolution (1080×1920)
   - Expected duration (sum of segments minus crossfade overlaps)
   - Audio present
3. Extract verification frames from the final reel and inspect them before declaring success:
   ```bash
   OUT="path/to/final.mp4"
   DUR=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$OUT")
   mkdir -p /tmp/reel_verify
   ffmpeg -y -hide_banner -loglevel error -ss 0.2 -i "$OUT" -frames:v 1 /tmp/reel_verify/first_frame.jpg
   ffmpeg -y -hide_banner -loglevel error -ss 1.5 -i "$OUT" -frames:v 1 /tmp/reel_verify/hook_1_5s.jpg
   ffmpeg -y -hide_banner -loglevel error -ss "$(LC_ALL=C awk -v d="$DUR" 'BEGIN{printf "%.2f", d/2}')" -i "$OUT" -frames:v 1 /tmp/reel_verify/mid.jpg
   ```
   Read these frames. Confirm the first 1-2 seconds match the chosen hook. If the hook was supposed to be close-up/action but the first frame is a landscape/establishing shot, treat that as an issue: adjust the first segment start time or reorder segments and re-render before publishing.
4. **Verify ASMR/audio transitions** when mode is `asmr` or `asmr-soft-bed`:
   - Do not rely only on `ffprobe` and frames; listen mentally by inspecting audio levels around every crossfade boundary.
   - Extract 1.2s snippets around each transition and/or create a low-res audio-review copy.
   - If ambience jumps are obvious, re-render using the ASMR smoothing stage with stronger per-segment fades and lower volume for wide/windy clips.
   ```bash
   # Example: inspect loudness around a known transition time T
   T="7.34"
   SS=$(LC_ALL=C awk -v t="$T" 'BEGIN{printf "%.2f", t-0.6}')
   ffmpeg -y -hide_banner -loglevel error -ss "$SS" -t 1.2 -i "$OUT" \
     -af volumedetect -f null /dev/null 2>&1 | grep -E "mean_volume|max_volume"
   ```
5. **Final loudness normalization before publishing:** after the user picks the final variant, normalize the final audio with `loudnorm` using video copy so the Short is not too quiet on YouTube/Telegram. This is especially important for ASMR-soft-bed renders, which can otherwise measure around -35 to -45 dB mean volume.
   ```bash
   TMP="${OUT%.mp4}.normtmp.mp4"
   if [[ "$AUDIO_MODE" == "tiktok-hype" ]]; then
     NORM="loudnorm=I=-16:TP=-1.5:LRA=9"
   else
     NORM="loudnorm=I=-20:TP=-2:LRA=12"
   fi
   ffmpeg -y -hide_banner -loglevel error -i "$OUT" \
     -map 0:v -map 0:a -c:v copy \
     -af "$NORM" -c:a aac -b:a 192k -ar 48000 -movflags +faststart "$TMP"
   mv "$TMP" "$OUT"
   ```
   Re-check `volumedetect` after normalization. A calm ASMR Short should be comfortably audible without becoming aggressive; hype/music-led Shorts can be louder.
6. If issues found — suggest adjustments and re-run. For ASMR seam issues, produce `strong_asmr` and `soft_bed` audio variants before changing the video edit.
7. Clean up temp files only after the user approves the final variant. For ASMR projects, keep `segment_*.mp4` and `stitched.mp4` until publishing, because they allow fast audio-only iteration.
8. Offer iteration: "Want to adjust clip order, timings, or volume?"

## Technical Defaults

These are the standard encoding parameters:

| Parameter | Value |
|-----------|-------|
| Resolution | 1080×1920 (vertical 9:16) |
| Pixel format | yuv420p |
| Codec | H.264 High profile, level 5.1 (level 4.1 causes MB rate warnings at 1080x1920@59.94fps) |
| CRF | 18 |
| Preset | medium |
| Framerate | -r 60000/1001 (59.94fps) — forced on ALL segments for xfade compatibility |
| Timescale | -video_track_timescale 60000 — forced on ALL segments for matching tbn |
| Movflags | +faststart |
| Crossfade duration | 0.5s fade transition |
| Clip audio level (no music) | -3dB |
| Clip audio level (with music mix) | volume=0.45 (~-7dB) for kept segments, volume=0 for muted |
| Music level | hybrid: volume=0.20-0.25; music mode: 0.30; asmr-soft-bed: 0.08-0.16 |
| Audio codec | AAC 128k minimum; use 192k for ASMR-forward reels |
| Final loudness | ASMR/calm: `loudnorm=I=-20:TP=-2:LRA=12`; hype/music-led: `loudnorm=I=-16:TP=-1.5:LRA=9`; apply with `-c:v copy` after the final edit |
| Slomo | setpts=1.25*PTS + atempo=0.8 (80% speed). For muted segments: `volume=0` (or `atempo=0.8,volume=0` for slomo) |
| Music fade in | 0s (default — avoid silence over the hook) |
| Music fade out | 5s |

Landscape clips are auto-cropped to 9:16 center:
```
crop=ih*9/16:ih,scale=1080:1920
```

Portrait clips are scaled to fit:
```
scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2
```

## Color Presets

```
warm:    eq=contrast=1.05:brightness=0.02:saturation=1.15,colorbalance=rs=0.04:gs=0.0:bs=-0.06
natural: eq=contrast=1.03:brightness=0.01:saturation=1.05
vintage: eq=contrast=1.08:brightness=-0.01:saturation=0.85,colortemperature=6800,vignette=PI/5
cold:    eq=contrast=1.05:brightness=0.02:saturation=1.0,colorbalance=rs=-0.03:bs=0.05
```

## Crossfade Offset Calculation

**CRITICAL: Always calculate offsets from PROBED actual durations, never from expected/planned durations.** ffmpeg segment extraction produces durations that differ slightly from requested (e.g. 3.003s instead of 3s). Accumulating these errors across many segments causes xfade offsets to point past the end of the video → black screen or freezing.

**Workflow:**
1. Extract all segments
2. Probe each with `ffprobe -v quiet -show_entries format=duration -of csv=p=0`
3. Calculate offsets from probed values
4. Write filter_complex to a temp file, pass via `$(cat "$TMP/filter.txt")`

**Dynamic offset calculation in bash:**
```bash
# Use awk for float math — NEVER use bc (locale-dependent, breaks on decimals)
calc() { LC_ALL=C awk "BEGIN{printf \"%.6f\", $1}"; }

# Store durations in named variables, NOT bash arrays (zsh-incompatible indexing)
DUR_0="..."; DUR_1="..."; DUR_2="..."

# Use simple sequential labels: [v1], [v2], ... (NOT [v0001] — inconsistent naming)
ACC="${DUR_0}"
OFFSET="$(calc "${ACC} - ${XD}")"
VFILTER="[0:v][1:v]xfade=transition=fade:duration=${XD}:offset=${OFFSET}[v1]"
AFILTER="[0:a][1:a]acrossfade=d=${XD}[a1]"
ACC="$(calc "${ACC} + ${DUR_1} - ${XD}")"

for idx in 2 3 4; do
  PREV="$((idx - 1))"
  eval "CUR_DUR=\${DUR_${idx}}"
  OFFSET="$(calc "${ACC} - ${XD}")"
  VFILTER="${VFILTER};[v${PREV}][${idx}:v]xfade=transition=fade:duration=${XD}:offset=${OFFSET}[v${idx}]"
  AFILTER="${AFILTER};[a${PREV}][${idx}:a]acrossfade=d=${XD}[a${idx}]"
  ACC="$(calc "${ACC} + ${CUR_DUR} - ${XD}")"
done

# Write to file and pass via $(cat) — -filter_complex_script is DEPRECATED
echo "${VFILTER};${AFILTER}" > "${TMP}/filter.txt"
# Then use: -filter_complex "$(cat "${TMP}/filter.txt")"
```

**Formula:** offset for transition into segment i = accumulated_merged_duration - XFADE_DURATION

**Example:** 3 segments with probed durations 4.004s, 3.003s, 5.005s, XD=0.5:
- Transition 0: offset = 4.004 - 0.5 = 3.504, merged = 4.004 + 3.003 - 0.5 = 6.507
- Transition 1: offset = 6.507 - 0.5 = 6.007, merged = 6.507 + 5.005 - 0.5 = 11.012

Total output duration = 11.012s

## Common Issues

### Audible ASMR transitions / ambience jumps (CRITICAL for ASMR)
When the user says "слышны переходы", "склейки слышно", "неприятно по ощущениям", or the ASMR feels like the mic environment changes at every cut, the problem is usually not video timing — it is inconsistent source ambience.

**Symptoms:**
- river/wind noise suddenly changes at cuts
- close-up action clips sound much louder than landscape clips
- `acrossfade` is technically smooth but the tone still changes abruptly
- music is too quiet or absent to mask ambience changes

**Fix:**
1. Keep the video edit unchanged (`-c:v copy`).
2. Rebuild audio from `segment_*.mp4` with delayed per-segment audio instead of using the stitched audio track.
3. Add `afade=t=in:d=0.35-0.50` and `afade=t=out:d=0.70-0.90` to every segment except the opening hook (opening can use `d=0.05`).
4. Use role-based volume: action/pour louder, wide/windy/person clips softer.
5. For outdoor footage, use `highpass=f=200` before compression/limiting.
6. Add a quiet continuous bed (`volume=0.08-0.16`) if pure ASMR still exposes room-tone changes.
7. Render two quick variants: `strong_asmr` and `soft_bed`; let the user pick by feel.

### Timebase mismatch between segments (CRITICAL)
Different iPhone clips can have different timebases (e.g. 60fps MOV → tbn=15360 vs 59.94fps MOV → tbn=60000). The `xfade` filter **requires matching timebases** and will fail with: `First input link main timebase do not match the corresponding second input link xfade timebase`.

**Fix:** Always force consistent framerate and timescale on ALL segments during extraction:
```bash
ffmpeg -y -ss "$SS" -t "$T" -i "$SRC" \
  -vf "$VF" -af "$AF" \
  -r 60000/1001 -video_track_timescale 60000 \
  -c:v libx264 ... "$SEG"
```

### zsh compatibility (CRITICAL)
The generated script must run via `/bin/bash`. In Pi/Codex sessions the user's interactive shell may still be zsh, and snippets may be copied into zsh. Key pitfalls when running or sharing inline commands:

1. **Never use `bc` for float math** — breaks on decimal numbers depending on locale (`Parse error: bad token`). Use `awk` with `LC_ALL=C`:
   ```bash
   calc() { LC_ALL=C awk "BEGIN{printf \"%.6f\", $1}"; }
   ```
   Without `LC_ALL=C`, awk may output `4,000000` instead of `4.000000` — commas in ffmpeg filter values cause `Filter not found` errors.

2. **`$var[idx]` in zsh is array indexing** — `$XD[a1]` becomes empty because zsh tries to index array `XD` with key `a1`. Always use `${XD}` with braces, especially before `[` characters in filter_complex strings.

3. **`$i:a` in zsh is a path modifier** — `$i:a` expands to absolute path of `$i`, not `$i` followed by `:a`. Use `${i}` with braces.

4. **Store values in named variables (`DUR_0`, `DUR_1`), not bash arrays** — zsh arrays are 1-indexed and behave differently. Use `eval` to access: `eval "D=\${DUR_${idx}}"`.

5. **Always invoke the generated script with `/bin/bash script.sh`**, never source it or rely on the shebang in zsh environments.

### Filter label naming
Use simple sequential labels: `[v1]`, `[v2]`, `[a1]`, `[a2]`. Do NOT use compound names like `[v0001]` — easy to get naming inconsistencies between the first pair (hardcoded) and the loop (generated).

### -filter_complex_script is DEPRECATED
Modern ffmpeg deprecates `-filter_complex_script`. Use `$(cat)` to read filter from file instead:
```bash
# ❌ DEPRECATED — will show warning or fail:
ffmpeg -y ... -filter_complex_script "${TMP}/filter.txt" ...

# ✅ CORRECT — read file content inline:
ffmpeg -y ... -filter_complex "$(cat "${TMP}/filter.txt")" ...
```

### Locale breaks float math (CRITICAL)
Some locales (ru_RU, de_DE, etc.) use comma as decimal separator. Without `LC_ALL=C`, awk outputs `3,504000` instead of `3.504000`. When this lands in an ffmpeg filter string like `xfade=offset=3,504000`, ffmpeg interprets the comma as a filter separator and fails with `No such filter: '504000'`.

**Fix:** Always use `LC_ALL=C` in the calc helper:
```bash
calc() { LC_ALL=C awk "BEGIN{printf \"%.6f\", $1}"; }
```

### -t flag placement (CRITICAL)
**Always place `-t` BEFORE `-i`, not after.** This controls INPUT duration.

```bash
# ✅ CORRECT: -t before -i = limits INPUT to 4s, slomo produces 5s output
ffmpeg -ss 3 -t 4 -i input.mov -vf "setpts=1.25*PTS" ...

# ❌ WRONG: -t after -i = limits OUTPUT to 4s, slomo is truncated!
ffmpeg -ss 3 -i input.mov -t 4 -vf "setpts=1.25*PTS" ...
```

When `-t` is after `-i`, it limits output duration. With `setpts=1.25*PTS`, the video is slowed but then cut at the original duration — segments end up shorter than expected, xfade offsets break, and the result is black screen or freezing.

### yuv420p compatibility
Always include `-pix_fmt yuv420p` — without it, some players (Telegram, Instagram) show a black screen or refuse to play the file.

### Slomo audio sync
When applying `setpts=1.25*PTS` for video slowdown, pair it with `atempo=0.8` on the audio stream to keep sync. If slomo audio sounds bad, consider muting clip audio for that segment (`volume=0`) and relying on background music.

### Temp file cleanup
The script generates intermediate segment files (`segment_00.mp4`, etc.). Clean them up at the end with `rm -f segment_*.mp4`, but only after verifying the final output is valid.

### iPhone MOV rotation metadata
iPhone MOVs may contain rotation metadata. Use `-autorotate` (default in modern ffmpeg) or explicitly apply `transpose` if needed. Check with:
```bash
ffprobe -v quiet -show_entries stream_tags=rotate -of default=nw=1 "$clip"
```

### Clips without audio stream (CRITICAL)
Some iPhone clips (timelapse, certain slo-mo modes, screen recordings) have **no audio stream at all**. The `acrossfade` filter requires audio from ALL inputs and will fail with: `Stream specifier ':a' in filtergraph description ... matches no streams`.

**Detection:** During Phase 0 scan, check for audio:
```bash
ffprobe -v quiet -select_streams a -show_entries stream=codec_type -of csv=p=0 "$clip"
# Empty output = no audio stream
```

**Fix:** When extracting a segment from a clip with no audio, generate a silent audio track:
```bash
ffmpeg -y -ss "$SS" -t "$T" -i "$SRC" \
  -f lavfi -t "$T" -i anullsrc=channel_layout=stereo:sample_rate=48000 \
  -vf "$VF" \
  -map 0:v -map 1:a \
  -shortest \
  -r 60000/1001 -video_track_timescale 60000 \
  -c:v libx264 ... -c:a aac -b:a 128k \
  "$SEG"
```

### Audio quality analysis for smart keep/mute decisions
Don't ask the user to decide keep/mute without data. Analyze each clip's audio and present recommendations:

| Metric | How to measure | Interpretation |
|--------|---------------|----------------|
| Mean volume | `ffmpeg -af volumedetect` → `mean_volume` | < -55dB = too quiet, mute |
| Zero-crossing rate | Python: count sign changes per second | > 800Hz = wind/hiss, < 400Hz = nature/ambient |
| Max spike | `max_volume` vs `mean_volume` | Gap > 20dB = sudden noise (clanking, bumps) |

Present a table with recommendations, let user override. Default to muting wind/noise and keeping nature sounds.

### Large files and disk space
iPhone 4K MOVs are large. Ensure enough disk space for intermediate files (roughly 2× total source size). The script can be modified to process segments sequentially and clean up after each crossfade step to reduce peak disk usage.

## Shooting Guide

Tips for filming clips that produce the best reels. Present these to the user when relevant.

### For maximum reel quality:
- **Film 15-20 clips per outing** — enough for 3-5 different reels via batch generation
- **Shoot more close-ups than wide shots** — hands, steam, pouring, textures (bark, stones, water ripples). Close-ups are the foundation of good hooks and payoff shots
- **Record 10-15 seconds of pure ASMR audio** for each action: pouring water, opening teapot lid, crackling fire, crunching leaves. Even if the camera is stationary — the audio is gold
- **One "hero shot" per session** — the single most beautiful moment with the best light, shot in slo-mo
- **Use the same teapot/cup as a visual signature** — viewers start recognizing your content by the props before they see the username
- **Vary the angle** — same action (pouring) from 3 angles gives you 3 different reel segments
- **Shoot at golden hour when possible** — early morning or late afternoon light is dramatically better

### For algorithm success:
- **Film at different locations** — variety prevents content fatigue. Same tea ceremony, different backdrop
- **Capture weather moments** — rain, fog, frost, wind. Weather-specific content gets shared because it's timely ("it's raining today, this is perfect")
- **Include one walking/path shot** — the "journey" segment is essential for Format B reels
- **Avoid shaky footage** — use a mini tripod or rest the phone on something stable for close-ups. Smooth handheld only for walking shots

### Posting strategy (for context, not for the skill to implement):
- Post 5x/week minimum on Instagram Reels + YouTube Shorts
- Best times for nature/calm content: 8-10 PM (evening wind-down) and 7-8 AM (morning commute)
- Use 5-8 targeted hashtags: #outdoortea #forestbrewing #gongfucha #natureASMR #slowliving
- Caption: evocative first line ("The kind of morning you don't want to end"), 1-2 specific details (tea variety, location), under 100 words total
- Never use #fyp #viral #explore — these are meaningless and signal amateur content
