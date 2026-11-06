# 1. Evidence Register and Project Timeline

This document lists the sources used for the Kidz Store historical documentation,
explains how the chronology (including the year) was determined, and gives a
consolidated timeline. All later documents cite sources using the evidence IDs
(`E01`, `E02`, …) defined here.

- **Prepared:** 2026-11-06
- **Documentation baseline:** branch `integration/kidz-latest-20261106`, commit `78efb02`
- **Method:** read-only inspection of Git history, repository files, preserved
  backups and local operator records. No application code, migration, database or
  configuration was changed to produce this documentation.

---

## 1.1 Status and provenance labels

The labels below are used in every historical document.

**Implementation status** (what happened to a requirement):

| Label | Meaning |
| --- | --- |
| **PLANNED** | A source states the item as an intention, future enhancement or recommendation, and no implementation was found as of 2026-11-06. |
| **IMPLEMENTED** | Code, a migration or a commit shows the item was delivered substantially as stated. |
| **MODIFIED** | The item was delivered differently from how it was stated, or an earlier implementation was later changed, restricted, disabled or replaced. |
| **UNVERIFIED** | The available evidence is not sufficient to confirm or rule out the item. |

**Provenance** (where the text of a requirement comes from):

| Label | Meaning |
| --- | --- |
| **[ORIGINAL]** | Quoted or closely paraphrased from a dated historical source. |
| **[RECONSTRUCTED]** | Derived by this documentation from code, commits or file evidence because no original planning text exists. The supporting evidence is always cited. |
| **[INFERRED]** | A conclusion drawn from indirect evidence such as file-system timestamps. Treat it with more caution than a reconstruction from code. |

---

## 1.2 Evidence register

### GitHub repository `TIME-00/kidz`

| ID | Source | Date (as recorded) | What it establishes |
| --- | --- | --- | --- |
| E01 | GitHub repository metadata (`createdAt`) | 2025-03-10 08:48:19 UTC | When the repository was created. |
| E02 | Commit `2f31b93` "Initial commit" | 2025-03-10 16:48 +08:00 | README contains only `# kidz`. |
| E03 | Commit `4a6fb60` README (Iteration-1 branch) | 2025-03-10 17:36 +08:00 | **The earliest written statement of project intent** (overview, features, tech stack, future enhancements). |
| E04 | Commit `bc245c6` "Upload the initial page" (Iteration-1); merge `7885c6f`, tag `Version_1_(Release_on_11-3-2025)` | 2025-03-10 17:39 / 17:40 +08:00 | Iteration 1 source: 19 Dart files, UI prototype with no backend. |
| E05 | Commits `d2e6572` README, `1871957` "Update the source code and add several pages" (Iteration-2); merge `986c51f`, tag `Version_2_(Release_on_11/3/2025)` | 2025-03-11 01:07–01:11 +08:00 | Iteration 2: Supabase integration and Seller pages. |
| E06 | Commits `9b8a76e` README, `0e1e52c` "Fix bugs and improve UI" (Iteration-3); merge `15c3388`, tag `Version_3_(Release_on_11/3/2025)` | 2025-03-11 01:27–01:29 +08:00 | Iteration 3: persistent cart, shared user state, shipping address. |
| E07 | Commits `fb0a6c4` README, `1cac8e6` "Fix some bugs" (Iteration-4); merge `1fe679e` (original 2025 `main`), tag `Version_4_(Release_on_11/3/2025)` | 2025-03-11 01:44–01:48 +08:00 | Iteration 4: order creation, invoices, account deletion. Last original GitHub commit. |
| E21 | Commit `78efb02` "Restore complete Kidz Flutter app with secure Admin management" on `integration/kidz-latest-20261106` (parent `1fe679e`) | 2026-11-06 15:14 +08:00 | Published application baseline before historical-documentation revisions, the subject of [Current State](../current-state-2026-11-06.md). |

### Preserved backups and analysis documents (local, outside the repository)

| ID | Source | Date (as recorded) | What it establishes |
| --- | --- | --- | --- |
| E08 | `Backups/kidz_legacy_2025-11-21.7z`, legacy `kidz` Flutter project (35 Dart files, assets, platform folders). Only its `lib/`, `pubspec.yaml`, `README.md` and assets were extracted, read-only, to a temporary folder for comparison. | Archive named 2025-11-21. Source file modification times are 2025-03-24 to 2025-03-27. | Development continued after the GitHub v4 release; this expansion is absent from the original 2025 GitHub history. This is where Guest, Seller Dashboard, Sales Reports and Admin first appear. |
| E09 | File-system timestamps of the `kidz_store` scaffold (`.metadata`, `README.md`, `analysis_options.yaml`, `pubspec.lock`) | 2025-11-21 | [INFERRED] The `kidz_store` Flutter project was created about 2025-11-21 and the legacy `lib/` was copied into it. |
| E10 | `KIDZ_PROJECT_DOCUMENTATION.md` (the `kidz_store` analysis). Its footer reads "Document generated on 2026-06-17". | 2026-06-17. First committed in `5ead0d7` on 2026-07-27. | The assessment of the `kidz_store` codebase, including its §12 "Weaknesses" (with severity markers) and §13 "Improvement Recommendations". |
| E11 | `Backups/KIDZ_legacy_app_documentation_2026-06-18.md`, with SHA-256 `7e3262…4a0f` matching its `.sha256.txt` record | 2026-06-18. Preserved 2026-07-28. | The assessment of the legacy `kidz` folder: §13 "Weaknesses" and §14 "Improvement Recommendations". |
| E25 | `Backups/kidz_store_42c5181_2026-07-28.7z` | 2026-07-28 | Backup snapshot of local commit `42c5181`. Listed only. |

### Local Git history of `kidz_store` (July 2026; not on GitHub)

| ID | Commit | Date | Subject |
| --- | --- | --- | --- |
| E12 | `5ead0d7` | 2026-07-27 01:43 +08:00 | chore: capture pre-recovery kidz_store baseline |
| E13 | `4c4b82b` | 2026-07-27 02:11 +08:00 | fix: restore kidz assets and Android branding |
| E14 | `077eca7` | 2026-07-27 14:16 +08:00 | fix: correct image fallback semantics and app branding |
| E15 | `4285622` | 2026-07-27 17:06 +08:00 | feat: reconstruct Supabase backend for Kidz |
| E16 | `b4494f9` | 2026-07-27 22:28 +08:00 | fix: validate and harden Kidz Android emulator flows |
| E17 | `42c5181` | 2026-07-28 03:30 +08:00 | fix: complete Kidz Android emulator validation |

These commits exist only in the local `kidz_store` repository. Their content is
included as a source snapshot in integration commit `78efb02` (E21). This was not
a Git squash or an unrelated-history merge; its sole parent is original GitHub `main` at `1fe679e`. The July commits
themselves were not pushed.

### November 2026 Admin restoration

| ID | Source | What it establishes |
| --- | --- | --- |
| E18 | `ADMIN_PHASES.md`, `ADMIN_VERIFICATION.md` | Phase 1: Auth-only login, server-controlled Admin role, read-only Admin access, operator tool. Verified locally on 2026-11-06. |
| E19 | `ADMIN_PHASE2.md`, `ADMIN_PHASE2_VERIFICATION.md` | Phase 2: original Admin management actions restored through scoped RPCs. Verified locally on 2026-11-06. |
| E20 | `supabase/migrations/20261106030934_admin_read_access.sql`, `supabase/migrations/20261106034711_admin_management.sql` | The database changes for Phases 1 and 2. |
| E22 | Local operator records `KidzBackups/<project-ref>/20261106T053729Z/` (not in the repository). Only the non-private summary files were read: `migration-gate.json`, `hosted-migration-result.json`, `recovery-proof.json`, `local-migration-rehearsal.json`. | A verified backup and an isolated restore rehearsal were completed, and then both Admin migrations were pushed to the hosted project on 2026-11-06. The database dump and the `*.private.*` files were **not** opened. |
| E23 | Local operator terminal session log (not in the repository; reported by the documentation author, not reopened in this review) | On 2026-11-06, a debug APK was built and installed on an Android emulator. The app reported a successful Supabase connection, and the Admin operator tool was run. |
| E24 | `flutter test --no-pub` on a separate clone of `78efb02`; independently rerun during this review in `kidz_docs` | 2026-11-06: **137 tests, all passed**. |
| E26 | Independent read-only Supabase Management API and SQL catalog/aggregate inspection, 2026-11-06 | All three migration versions are applied; Admin read policies use `kidz_private.is_admin()`. One hosted Auth account currently has the server-controlled Admin role. No identities or passwords were read into this documentation, and no hosted mutation was made. |
| E27 | Independent isolated PGlite reproduction, 2026-11-06; exact three migration files plus the existing synthetic Auth/Storage bootstrap | **CONFIRMED BUG:** a Seller whose product is in a Buyer-owned order receives zero order/report rows, and its status update affects zero rows. Buyer ownership isolation and verified Admin reads pass. This blocks the final `main` merge. |
| E28 | Independent in-memory scan of 110 historical GitHub Dart blobs and safe project checks, 2026-11-06 | One distinct legacy JWT key, with `role = anon`; no privileged key literal found. The legacy project differs from the current project, is not among accessible projects, and its hostname does not resolve. No historical key was sent in a request. Deletion and revocation remain unverified. |
| E29 | Local Seller order/report fix on the integration branch, 2026-11-06; `20261106094017_seller_order_access.sql`, `seller_orders.dart`, Seller/report regression tests | Verified locally: 149 Flutter tests; 20 Seller + 29 existing Admin PGlite scenarios; fresh Supabase pgTAP 116 assertions and real HTTP 47 checks. Purchase snapshots and scoped RPCs restore visibility/reports; shared mixed-order status remains Admin-managed. Hosted migration remains unapplied and final merge requires approval/verification. |

---

## 1.3 Determining the chronology and the year

The sources come from two separate Git histories and several undated or
self-dated documents. The chronology was established as follows.

1. **Original development was in early 2025.** The GitHub repository was created
   on 2025-03-10 (E01). All four iterations were committed and merged between
   2025-03-10 16:48 and 2025-03-11 01:48 (+08:00), a span of about nine hours
   (E02–E07). The tag names give the release date as `11/3/2025` and
   `11-3-2025`. Read in day/month order, these match the 11 March 2025 commit
   timestamps. The tags are lightweight and carry no tagger date of their own.
2. **The GitHub timestamps record when the snapshots were uploaded, not how long
   each iteration took to build.** Four complete iterations within nine hours
   suggests the snapshots may have been prepared beforehand, but does not prove
   when development began. The legacy archive contains project folders with
   timestamps from February 2025 (for example, `android/app/src` is dated
   2025-02-26) (E08). Those may reflect scaffold creation or copied timestamps;
   they do not independently establish the start of application development.
   The actual start date and iteration durations remain **UNVERIFIED**.
3. **Development continued locally after release.** The legacy `kidz` source
   files carry modification times from 2025-03-24 to 2025-03-27. They include
   11 Dart files absent from the original 2025 GitHub snapshots, among them every Admin screen and
   the Seller Dashboard (E08). This expansion is absent from the original 2025 GitHub history; its later source
    state is included in the November 2026 integration snapshot.
4. **The `kidz_store` project dates from November 2025 [INFERRED].** Its scaffold
   files and `pubspec.lock` are dated 2025-11-21, the same date as the legacy
   archive's name (E08, E09). The `kidz_store` `lib/` matches the legacy `lib/`
   except for package-name imports (`package:kidz/` → `package:kidz_store/`) and
   minor lint-style edits in four other files. Assets were not copied: the
   [June 2026 assessment](../../KIDZ_PROJECT_DOCUMENTATION.md) (E10) records that
   `assets/` was missing.
5. **The improvement recommendations were written in June 2026.** The two
   assessment documents are dated 2026-06-17 (E10) and 2026-06-18 (E11).
6. **The "July improvement" work is July 2026.** The `kidz_store` local Git
   history starts on 2026-07-27, and all improvement commits fall between
   2026-07-27 01:43 and 2026-07-28 03:30 (E12–E17). A backup was taken on
   2026-07-28. No source shows any Kidz activity in July 2025: GitHub has no
   commits between 2025-03-11 and 2026-11-06, and no legacy source file is
   dated later than March 2025.
7. **No document titled "Initial Plan" or "Improvement Plan" was found.** The
   searches covered the repository, both Git histories, the `Backups` folder,
   the legacy archive listing and named preserved assessment documents. The initial
   documentation author also reported a wider filename search; that user-profile
   search was not repeated by this independent review. The Initial Plan and the July
   Improvement Plan are therefore **[RECONSTRUCTED]** from the closest evidenced
   sources: the README files (E03–E07) for the initial plan, and the June 2026
   recommendations together with the July 2026 commits (E10–E17) for the
   improvement plan.
8. **The Admin restoration and the current state date from 6 November 2026.**
   The Phase 1 and Phase 2 migrations carry 2026-11-06 version prefixes (E20).
   The verification records are dated 2026-11-06 (E18, E19). The integration
   commit was made on 2026-11-06 at 15:14 +08:00 (E21).

All commit timestamps carry a +08:00 offset. Times in this documentation are
given in that offset unless marked UTC.

---

## 1.4 Consolidated timeline

| Date | Event | Evidence | Status |
| --- | --- | --- | --- |
| Feb 2025 (earliest timestamps) | Legacy `kidz` Flutter project folders exist locally. | E08 | [INFERRED] |
| 2025-03-10 | GitHub repository `TIME-00/kidz` created. Initial commit. | E01, E02 | Verified |
| 2025-03-10 | **Iteration 1 / Version 1:** README states the project intent. A static UI prototype is uploaded. | E03, E04 | Verified |
| 2025-03-11 | **Iteration 2 / Version 2:** Supabase Auth, products, Seller registration, product add/edit with image upload. | E05 | Verified |
| 2025-03-11 | **Iteration 3 / Version 3:** persistent cart, `UserProvider`, saved shipping address, UI fixes. | E06 | Verified |
| 2025-03-11 | **Iteration 4 / Version 4:** order creation at checkout, invoice page, account-deletion flow. Merged to `main`. | E07 | Verified |
| 2025-03-24 to 03-27 | Post-release local expansion (not published in 2025): Guest mode, Seller Dashboard, Sales Reports, Admin Dashboard and four management screens, saved banking cards, new order-status vocabulary. | E08 | Dates [INFERRED] from file times |
| 2025-11-21 | `kidz_store` project scaffolded from the legacy source (package renamed). Legacy project archived. | E08, E09 | [INFERRED] |
| 2026-06-17 | Technical assessment of `kidz_store` written, including weaknesses and improvement recommendations. | E10 | Verified (self-dated) |
| 2026-06-18 | Technical assessment of the legacy `kidz` folder written, including improvement recommendations. | E11 | Verified (self-dated, checksum recorded) |
| 2026-07-27 | Pre-recovery baseline committed (includes the 2026-06-17 assessment). | E12 | Verified |
| 2026-07-27 | Assets restored and Android branding fixed. Image-fallback semantics corrected. | E13, E14 | Verified |
| 2026-07-27 | Supabase backend reconstructed as a versioned migration with RLS. Credentials moved to `--dart-define`. | E15 | Verified |
| 2026-07-27 to 07-28 | Android emulator validation and hardening: INTERNET permission, session restoration, rating type fix, signup layout and upsert, display-name fallback, account deletion disabled. | E16, E17 | Verified |
| 2026-07-28 | Backup of commit `42c5181` and preservation of the legacy assessment document. | E11, E25 | Verified |
| 2026-07-28 to 2026-11-05 | No commits or dated project documents found. | — | Gap |
| 2026-11-06 | **Admin Phase 1:** Auth-only login, `app_metadata.role = "admin"`, three Admin SELECT policies, operator tool. | E18, E20 | Verified (local tests) |
| 2026-11-06 | **Admin Phase 2:** user deletion, product deletion and order-status update restored through scoped RPCs, with an audit table and retained order history. | E19, E20 | Verified (local and isolated full-stack tests) |
| 2026-11-06 (~13:37–13:54) | Hosted database backed up and restore-rehearsed. Both Admin migrations pushed to the hosted project. | E22, E26 | Backup timing from operator records; applied migration history independently confirmed read-only |
| 2026-11-06 | Debug APK installed on an Android emulator against the configured backend. Admin operator tool run. | E23 | Operator log only |
| 2026-11-06 15:14 | Integration commit `78efb02` published on `integration/kidz-latest-20261106`. Not merged to `main`. | E21 | Verified |

---

## 1.5 Register of information that could not be verified

| # | Item | Why it cannot be verified |
| --- | --- | --- |
| U-01 | An original Initial Project Plan document | Not found. Only the README files (E03–E07) record the original intentions. |
| U-02 | An original document titled "Improvement Plan" dated July (any year) | Not found. The nearest sources are the June 2026 recommendations (E10, E11) and the July 2026 commits. |
| U-03 | Problem statement, academic context, assessment criteria and the team or author roles of the original project | No source records them. E10 and E11 describe the project as a student or coursework project, but that is the assessment's interpretation, not an original statement. |
| U-04 | The actual development dates and duration of each 2025 iteration | GitHub timestamps record a nine-hour upload sequence. Earlier work is shown only by file-system times. |
| U-05 | Exact dates of the post-release expansion and of the `kidz_store` scaffold | Based on file-system modification times only (E08, E09). |
| U-06 | The original 2025 Supabase schema, RLS configuration and data | The 2025 backend was a different Supabase project from the current one, and its schema was never versioned. The July 2026 migration was "derived directly from the Supabase calls in lib/". |
| U-07 | Whether the 2025 Supabase project was deleted and whether its legacy `anon` key was revoked | E28 verifies classification as a public client key, a different project, and an unresolvable legacy hostname. The project is not in the accessible-project list. Those observations do not prove deletion or key revocation. No active privileged credential was identified; the value is never reproduced. |
| U-08 | Complete original hosted post-migration verification records | The private original records were not reopened. Current migration history, order policies, Admin guard definition and role presence are independently verified read-only (E26); this is not a hosted mutation or end-to-end management test. |
| U-09 | Manual end-to-end Admin, Buyer and Seller flows on Android against the hosted backend after the 2026-11-06 migration | The operator log shows installation, connection and sign-out events only. No test record exists. |
| U-10 | Who wrote the June 2026 assessments, and the decisions made between June and July 2026 | Both documents describe themselves as "auto-generated technical documentation". No decision record exists. |
| U-11 | Any Android release distribution (for example, Google Play) | The release build type uses the debug signing configuration, and no store or distribution evidence exists. |
