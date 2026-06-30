# Weton Harian (Daily) & Wuku Mingguan (Weekly) Insight Endpoint Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the Javanese astrology (Weton and Wuku) calculations in `src/weton.ts` and integrate them into the `POST /api/weton/daily` endpoint in `src/router.ts`, along with complete Vitest coverage.

**Architecture:** Use the existing JDN-based Weton/Wuku formula in `src/weton.ts` and write integration logic in `src/router.ts`.

**Tech Stack:** Cloudflare Workers, TypeScript, Vitest.

## Global Constraints
- Backend must be written in type-safe TypeScript.
- No new external dependencies.

---

### Task 1: Update Router Endpoint for Weton Harian
Implement the `POST /api/weton/daily` endpoint handler in `src/router.ts`.

**Files:**
- Modify: `aestral-backend/src/router.ts`

**Interfaces:**
- Consumes: `birthDate`, `targetDate`
- Produces: `POST /api/weton/daily` endpoint

- [ ] **Step 1: Edit router.ts to import getWetonInsight and route the weton daily requests**
- [ ] **Step 2: Add handleWetonDaily function with correct auth/payload check**

---

### Task 2: Write Unit & Integration Tests
Write tests in `test/weton.test.ts` to verify the weton calculation engine and router integration.

**Files:**
- Create: `aestral-backend/test/weton.test.ts`

- [ ] **Step 1: Create test/weton.test.ts containing JDN, Saptawara, Pancawara, Wuku, and API integration tests**
- [ ] **Step 2: Run all tests using `npx vitest run` to verify they pass**
- [ ] **Step 3: Commit files with the required commit message**
