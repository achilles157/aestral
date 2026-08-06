---
name: context-guardian
description: >
  Monitors context window usage and prevents REQUEST_BODY_INVALID (400) errors
  caused by oversized conversation context. Activates automatically on every
  turn when a long or complex coding session is in progress. Provides proactive
  warnings when context is getting large, auto-saves a checkpoint file so
  progress is never lost, guides the user on how to continue in a fresh session,
  and helps break large tasks into safe session-sized chunks upfront.
  Trigger whenever: a session involves reading multiple files, long code edits,
  multi-step refactors, the user mentions "lanjutkan", "continue", context errors,
  400 errors, or REQUEST_BODY_INVALID.
---

# Context Guardian

## Why this skill exists

ZCode uses a model with a finite context window. When a conversation grows too
large, the API rejects the request with:

```
[400]: {"message":"Improperly formed request.","reason":"REQUEST_BODY_INVALID"}
```

This happens **before** the displayed token counter hits the limit — the actual
payload includes metadata, tool call history, and system prompts that are not
always visible. A session showing "50K / 200K used" can still hit the error
because the real serialised body is much larger.

Once the error hits, even typing "continue" fails — the request body is already
too big to send. The only fix is a fresh session.

This skill prevents that by acting early.

---

## 0 — Always-On Monitoring (Most Important)

**At the start of EVERY turn during an active coding/editing session**, quickly
assess session health BEFORE doing any work:**

- Count how many files you've read this session (scan conversation history)
- Count how many large edits/writes you've made
- Count approximate back-and-forth turns
- Check if any yellow/red zone criteria are met

If yellow zone → mention it briefly at the END of your response.
If red zone → STOP and checkpoint FIRST, then proceed.

This is not triggered by keywords — you actively check on every turn when working
on code. Treat it like a pre-flight check.

---

## 1 — Proactive Warning System

The real risk is **HTTP request body size**, not token count. Tool call outputs
(file reads, bash outputs, subagent returns) are serialized into the request body
as raw text — a 1000-line file read ≈ 40KB, and 10 such reads = 400KB+ before
counting system prompt, skills, and tool schemas.

Context window size (even 1 million tokens) does NOT prevent REQUEST_BODY_INVALID
— that error is an HTTP payload size limit on the server side, independent of the
model's context window.

**Primary signals to track** (these drive payload size):
- Number of large file reads (>200 lines) — most impactful
- Number of Bash calls with long outputs
- Number of subagent (Agent tool) calls — their returns can be very large
- Total back-and-forth turns

### Yellow zone (caution)
Trigger when **any two** of the following are true:
- More than 15 files have been read in full this session
- More than 6 large files (>200 lines) have been read
- More than 8 multi-step tool call sequences have completed
- The conversation has more than ~30 back-and-forth turns
- More than 3 subagent (Agent tool) calls have returned

**Action:** Add a brief note at the end of your response:
```
⚠️ Context check: payload session mulai besar. Pertimbangkan commit progress
dan mulai session baru jika ada task berikutnya.
```

### Red zone (critical)
Trigger when **any one** of the following is true:
- More than 25 files have been read in full this session
- More than 10 large files (>200 lines) have been read
- More than 15 multi-step tool call sequences have completed
- The conversation has more than ~50 back-and-forth turns
- More than 5 subagent (Agent tool) calls have returned

**Action:** Warn prominently before doing any more work:
```
🔴 Payload kritis: risiko tinggi hit REQUEST_BODY_INVALID. Saya akan simpan
checkpoint dulu sebelum lanjut. Setelah ini sebaiknya mulai session baru.
```
Then immediately run the checkpoint procedure (Section 2).

---

## 2 — Auto-Checkpoint Procedure

When entering the red zone, or when the user asks to checkpoint, write a
progress file before doing anything else.

### Checkpoint file location
```
<project_root>/.zcode/session-checkpoint.md
```
If `.zcode/` does not exist, create it.

### Checkpoint file format

```markdown
# Session Checkpoint
**Session ID:** <current session id if known, otherwise "unknown">
**Saved at:** <ISO timestamp>
**Project:** <project root path>

## Task Summary
<1–3 sentence description of what was being worked on>

## Completed Steps
- [ done step 1 ]
- [ done step 2 ]
- ...

## In Progress
- <what was being worked on when checkpoint was saved>

## Remaining Steps
- <step not yet done>
- <step not yet done>
- ...

## Key Files Modified
| File | Status | Notes |
|------|--------|-------|
| path/to/file.dart | ✅ done | brief note |
| path/to/other.dart | 🔄 in progress | what remains |
| path/to/pending.dart | ⏳ pending | what needs doing |

## How to Continue
Open a new ZCode session in this project and say:

> Lanjutkan task dari checkpoint. Baca `.zcode/session-checkpoint.md` untuk
> konteks, lalu lanjutkan dari bagian "In Progress".

## Uncommitted Changes
Run `git diff --stat` to see what has changed but not been committed.
Consider committing before closing this session.
```

After writing the checkpoint, tell the user:
```
✅ Checkpoint disimpan ke .zcode/session-checkpoint.md
Anda bisa mulai session baru dan ketik:
"Lanjutkan dari checkpoint di .zcode/session-checkpoint.md"
```

---

## 3 — Continuing in a Fresh Session

When the user starts a new session and references a checkpoint or prior session,
do this in order:

1. Read `.zcode/session-checkpoint.md` if it exists.
2. Run `git diff --stat` to see actual file state.
3. Read only the specific files listed under "In Progress" — not all modified files.
4. Resume from exactly where the checkpoint says, skipping already-completed steps.

Do **not** re-read files that are already marked ✅ in the checkpoint unless
the task explicitly requires it. Re-reading completed files wastes context.

---

## 4 — Breaking Large Tasks into Sessions

When the user describes a task that will clearly touch many files (refactor,
architecture change, feature spanning 5+ files), proactively suggest a session
plan before starting.

### Session sizing rules
- One session should touch at most **6–8 files** in full
- One session should contain at most **3–4 major edit operations**
- If a task needs more, split it

### How to present the plan

```
Task ini cukup besar. Saya sarankan pecah jadi beberapa session:

**Session 1:** [scope — e.g., buat model + provider baru]
**Session 2:** [scope — e.g., update screens A, B, C]
**Session 3:** [scope — e.g., update screens D, E + analyze]

Mulai dari Session 1 sekarang?
```

Ask the user to confirm before starting. After each session completes, write
a checkpoint and remind the user to start a fresh session for the next chunk.

---

## 5 — Session Health Summary (on request)

If the user asks "berapa sisa context?" or "session masih aman?", respond with
a quick health check:

```
📊 Session Health Check
─────────────────────
Files read this session : ~X
Large files (>200 lines): ~X
Tool call sequences     : ~X
Conversation turns      : ~X

Status: 🟢 Aman / 🟡 Hati-hati / 🔴 Kritis

Rekomendasi: [one line advice]
```

Estimate these numbers from what you can observe in the current conversation.
Be honest when uncertain — say "~" before estimates.

---

## 6 — Why "continue" Doesn't Work After the Error

Explain this clearly if the user asks:

The error `REQUEST_BODY_INVALID` means the HTTP request body sent to the API
was malformed or too large. When you type "continue", ZCode tries to send the
**entire conversation history** again as part of the new request. If the history
is what caused the error, sending it again just reproduces the same error.

The only way out is a **new session** — which starts with an empty conversation
and reads only what it needs from the checkpoint file and git state.

---

## 7 — Why the Token Counter is Misleading

The context usage indicator in ZCode (e.g., "50K / 200K") shows **text tokens
only**. The actual HTTP request body is much larger because it includes:

- Full tool call history (every Read, Edit, Bash call + their full outputs)
- System prompt and skill contents loaded this session
- Metadata and formatting overhead per message
- Any large file contents that were read in full

A session showing 50K text tokens can easily have a 300K+ actual payload.
This is why the error hits "unexpectedly early."

**Rule of thumb:** treat the visible token counter as measuring only ~30–40%
of the real payload. If the counter shows 40% used, the real payload may
already be 80–90% of the limit.

This is why counting file reads and tool sequences (Section 1) is more
reliable than watching the token counter.

---

## Important notes

- Checkpoint files are **not** sensitive — they contain task descriptions and
  file paths, not code or secrets. Safe to commit if desired.
- The `.zcode/` directory should be in `.gitignore` if checkpoints should stay
  local. Check before committing.
- These are estimates, not exact token counts. When in doubt, checkpoint early.
