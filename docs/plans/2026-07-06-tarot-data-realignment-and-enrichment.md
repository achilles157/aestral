# Design & Implementation Plan: Tarot Data Realignment and Enrichment

This document details the design for resolving the Cups/Wands suit swap bug in the Tarot dataset, realigning the three source JSON files, and enriching the missing fields (archetypes, elemental info, mythical context, and numerology) using the external Gemini API.

## 1. Problem Statement: Cups & Wands Suit Swap Mismatch

Our audit of the source JSON files revealed a critical mismatch between `tarot-eng.json`, `tarot-id.json`, and `tarot-images.json`:

* **`tarot-eng.json` suit sequence:** Major Arcana (0-21), Wands (22-35), Cups (36-49), Swords (50-63), Pentacles (64-77).
* **`tarot-id.json` suit sequence:** Major Arcana (0-21), Cups (22-35), Wands (36-49), Swords (50-63), Pentacles (64-77).
* **`tarot-images.json` suit sequence:** Major Arcana (0-21), Cups (22-35), Swords (36-49), Wands (50-63), Pentacles (64-77).

Because previous attempts merged them line-by-line using index matching:
* Card 22 had **Ace of Wands** (English) merged with **Ace Piala** (Indonesian Cups).
* Card 36 had **Ace of Cups** (English) merged with **Ace Tongkat** (Indonesian Wands).

This corrupted the database for the entire Wands and Cups suites.

---

## 2. Proposed Mappings for Realignment

To build a correct dataset, we align all source fields to standard indices mapped by the backend code in `tarot.ts`:
* `0-21`: Major Arcana (Neutral)
* `22-35`: Cups (Water)
* `36-49`: Wands (Fire)
* `50-63`: Swords (Air/Metal)
* `64-77`: Pentacles (Earth)

We will use the following index mapping to merge the three files:

| Target ID Range | Suit | `tarot-eng.json` Source Index | `tarot-id.json` Source Index | `tarot-images.json` Source Index |
| :--- | :--- | :--- | :--- | :--- |
| **0 - 21** | Major Arcana | `id` (0-21) | `id` (0-21) | `id` (0-21) |
| **22 - 35** | Cups | `36 + k` | `22 + k` | `22 + k` |
| **36 - 49** | Wands | `22 + k` | `36 + k` | `50 + k` |
| **50 - 63** | Swords | `50 + k` | `50 + k` | `36 + k` |
| **64 - 77** | Pentacles | `64 + k` | `64 + k` | `64 + k` |

*(where $k$ is the offset from 0 to 13 within the suit)*

---

## 3. Data Enrichment Plan

### A. Automatic Mappings
1. **`elemental_en` & `elemental_id` for Ace to 10 cards:**
   - Cups (22-31): `Water` / `Air`
   - Wands (36-45): `Fire` / `Api`
   - Swords (50-59): `Air` / `Udara`
   - Pentacles (64-73): `Earth` / `Tanah`
2. **`numerology_en` & `numerology_id` for Court Cards:**
   - Page (Cards 32, 46, 60, 74): `11 (Page; new perspectives, messages, apprenticeship)` / `11 (Page; perspektif baru, pesan, pembelajaran)`
   - Knight (Cards 33, 47, 61, 75): `12 (Knight; action, movement, quest)` / `12 (Knight; aksi, pergerakan, pencarian)`
   - Queen (Cards 34, 48, 62, 76): `13 (Queen; mastery, inner power, maturity)` / `13 (Queen; penguasaan, kekuatan batin, kematangan)`
   - King (Cards 35, 49, 63, 77): `14 (King; authority, leadership, responsibility)` / `14 (King; otoritas, kepemimpinan, tanggung jawab)`

### B. Gemini API Enrichment for Minor Arcana (56 Cards)
We will generate the following fields:
* `archetype_en`: Archetypal theme of the card in English.
* `archetype_id`: Archetypal theme of the card in Indonesian.
* `mythical_en`: Mythological, spiritual, or symbolic story references in English.
* `mythical_id`: Mythological, spiritual, or symbolic story references in Indonesian.

We will write a python script (`scratch/enrich_tarot.py`) that:
1. Iterates over cards 22 to 77.
2. Calls Gemini API (`gemini-2.5-flash`) using the `GOOGLE_API_KEY` from `.env`.
3. Requests data in a clean JSON format:
   ```json
   {
     "archetype_en": "...",
     "archetype_id": "...",
     "mythical_en": "...",
     "mythical_id": "..."
   }
   ```
4. Saves the results incrementally to avoid rate limits or loss of progress.

---

## 4. Verification Plan

* **Automated verification script:** Check that all cards from 0-77 are populated, have valid non-empty fields, and that the names are aligned (e.g. Card 22 is Ace of Cups/Ace Piala, Card 36 is Ace of Wands/Ace Tongkat).
* **Manual verification:** Inspect selected cards (e.g., boundaries of Cups, Wands, Swords) to ensure that the descriptions and titles match.
