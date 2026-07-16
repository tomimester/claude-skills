---
name: appify
description: Turn one of Tomi's existing web projects (Next.js webapp, WordPress educational/content site, or other) into a native iOS app on the App Store, using the proven Mászóedzés architecture — React Native/Expo app, JSON API + one-time-code auth hand-off, offline outbox, Codemagic → TestFlight CI, and the full App Store submission pipeline. Use when the user says "appify", "make an iOS app from this", "turn this site into an app", or "App Store version of this project".
---

# Appify — web project → iOS App Store app

Battle-tested pipeline extracted from the **Mászóedzés** project
(`github.com:tomimester/maszoedzes` — the reference implementation; read its
code when in doubt). Work through the phases in order; each phase ends with
something verifiable. Read the reference docs in `references/` as you reach
the phase that needs them — not all upfront.

## Phase 0 — Assess & decide (do this with the user)

Classify the source project and confirm the approach before writing code:

| Source project | Approach |
| --- | --- |
| Interactive webapp with user accounts (any stack) | **Full native RN/Expo app** + JSON API on the existing backend (the Mászóedzés path) |
| WordPress educational/content site | **Native RN app consuming the WP REST API** (`/wp-json/wp/v2/...` — posts, pages, media come free). Native chrome: tab bar, article list/reader, search, saved/offline articles. Auth only if the site has member accounts |
| Site with paid content/courses | Same as above, but STOP and discuss Apple IAP rules first (guideline 3.1 — digital content sold in-app must use In-App Purchase; "reader" apps may view but not sell) |

**Never ship a plain WebView wrapper to the App Store** — Apple rejects them
(guideline 4.2 minimum functionality). The Capacitor hosted-shell pattern is
fine as an internal stopgap, never as the store submission.

Decisions to confirm with the user up front: app name, bundle id
(`hu.<domain>.app` pattern), which login providers (fewer = less work; note
guideline 4.8: offering Google login forces adding Sign in with Apple),
offline scope for v1, and whether the web UI or the new native UI is the
design etalon going forward (Mászóedzés lesson: pick ONE, put it in the
project handoff file).

## Phase 1 — Backend: JSON API + token auth

Only what the app needs; the existing site stays untouched for web users.
Read `references/architecture.md` for the full patterns. Highlights:

- `/api/v1/*` JSON endpoints; ALL write logic in one shared module the web
  code also calls ("type once" — never fork business logic per client).
- Bearer-token auth. For session/cookie-based sites, use the **one-time-code
  hand-off** (mint single-use code after web login → app redeems it for a
  token). For WordPress: read-only content needs no auth; member login needs
  a token plugin (e.g. JWT) — same hand-off idea applies.
- Writes accept client UUIDs + timestamps and are idempotent (offline replay).
- Account deletion endpoint (`DELETE /api/v1/me`) — Apple REQUIRES in-app
  account deletion for any app with accounts. Build it early, not at
  submission time.

## Phase 2 — Native app scaffold

- `native/` subdirectory in the existing repo (own package.json). ⚠️ Multiple
  npm projects in one repo: ALWAYS `cd` explicitly before npm/npx and use
  `git -C` — cwd drift once corrupted the web package.json.
- Expo + expo-router + TypeScript. **Pin the Expo SDK to the version the App
  Store Expo Go app runs** (dev loop = owner scans QR in Expo Go; a newer SDK
  breaks that). Do not upgrade mid-project.
- `shared/` directory for logic both clients need (domain constants,
  formatting, stats). Metro needs `watchFolders` + a resolver alias +
  `"onDemandFilesystem": false` in app.json experiments for imports outside
  the project root.
- Dev loop: `cd native && npx expo start --tunnel` → owner tests on-device
  live. Verify every change with `npx tsc --noEmit` AND
  `npx expo export --platform ios` (bundle check). There is no simulator on
  the server — these two + Expo Go ARE the test setup.

## Phase 3 — Auth in the app

Read `references/architecture.md` § Auth. The three flows and their traps:

- OAuth (Google/Apple): in-app auth session → web login → hand-off route
  307s to the app scheme with the code. Apple's form_post drops SameSite=Lax
  cookies — the OAuth callback cookie needs SameSite=None.
- **NEVER auto-navigate into the OAuth provider from script** (e.g. a
  `useEffect` that auto-submits/redirects to "save the user a tap"). WebKit
  blocks cookie storage for a site with no prior first-party engagement
  unless the navigation was a real user tap — a script-initiated one doesn't
  count even though it "looks" top-level. This passes every test on your own
  device (which already has a session) and fails 100% of the time for App
  Review (always a fresh device) — it's exactly what got Mászóedzés
  rejected under guideline 2.1(a) on the first submission. Render one real
  tap target instead. Full story + fix in `references/architecture.md`.
- **Email magic link: the link opens OUTSIDE the auth session** (Mail →
  Safari). The deep link back (`scheme://auth?code=…`) is treated by
  expo-router as NAVIGATION — you MUST have an `app/auth.tsx` route that
  redeems the code, or users land on "Unmatched Route". Also dismiss the
  lingering auth session and guard against double-redeem of the single-use
  code. This bug only reproduces in a standalone build, not Expo Go — test
  it on TestFlight before believing it works.
- Store the token in expo-secure-store; validate on cold start via `/me`.

## Phase 4 — Offline (if in scope)

Cache-first reads + a persisted outbox for writes. THE gotcha: `flush()`
must be a single shared awaitable promise — a skip-if-running boolean flag
creates a race where new records "vanish" until a second sync.

## Phase 5 — CI: Codemagic → TestFlight

Read `references/ci-codemagic.md`. One `codemagic.yaml` in the repo; push to
main builds, signs and uploads to TestFlight. All the signing traps are
solved in the reference file — reuse, don't rediscover. The Codemagic
account, the App Store Connect API key, and the Apple team are SHARED across
Tomi's apps; per-app you only need a new bundle id + ASC app entry.

## Phase 6 — App Store prerequisites (code/content work)

Read `references/appstore-checklist.md`. Build these while CI is being set up:

- Public (no-login) **privacy policy**, **support page**, and **ÁSZF** pages
  on the project's domain — Hungarian GDPR-standard structure; copy the
  Mászóedzés pages (`/adatvedelem`, `/tamogatas`, `/aszf`) and adapt. The
  operator is Adattenger Kft. — full block in `src/lib/legal.ts` there.
- In-app links to those pages + in-app account deletion.
- `ITSAppUsesNonExemptEncryption=false` in app config (skips compliance
  prompts).
- If Sign in with Apple is used: the ES256 client secret expires ~6 months —
  set up the renewal script + cron from the reference repo
  (`scripts/renew-apple-secret.sh`).

## Phase 6.5 — Ratings & reviews (recommended, not submission-blocking)

Ratings/reviews influence App Store search ranking and conversion — worth
building, but it's a growth feature, not an Apple requirement. Don't let it
block Phase 7; do it whenever the project has an obvious "positive moment" to
hang it on. Full detail in `references/architecture.md` § Ratings & reviews.

- Use Apple's SYSTEM prompt (`expo-store-review`'s `requestReview()`, which
  wraps `SKStoreReviewController`), never a custom "Rate us?" dialog that
  deep-links straight to the App Store as the primary ask.
- Trigger it after a POSITIVE moment — task completed, a milestone reached
  (Nth session/lesson/article/purchase), a key feature used successfully.
  NEVER on first launch, NEVER right after an error, crash, or support flow.
- The OS decides whether to actually show it (capped at 3x per app per 365
  days per user) — the app has no signal either way. Don't build UI that
  assumes it always appears.
- Hand the owner an explicit ongoing task: monitor and reply to reviews in
  App Store Connect → Ratings and Reviews. This doesn't end at ship — say so.
- **Testing this needs its own checklist item, called out separately from
  the rest of on-device testing** — see `references/appstore-checklist.md`
  § B, because it doesn't fail the obvious way (the app still opens fine)
  and the OS-level throttling makes naive "does the popup show" testing
  misleading after the first couple of tries.

## Phase 7 — Submission (console work, drive the user step-by-step)

Follow `references/appstore-checklist.md` § Submission exactly — it encodes
the real submission we did, including every field, the privacy nutrition
label answers, screenshot dimensions (and how to resize from any iPhone),
reviewer sign-in notes for password-less apps, Content Rights, and pricing.
Drive the user one step at a time; they do the console clicks, you verify
and prepare every text/asset.

## Working agreements (apply throughout)

- iOS-first: build/approve UX on native, then mirror to any web client in
  the same session — never leave a client silently behind.
- Commit + push at meaningful working checkpoints without asking.
- After every server change: build, restart, then curl-verify the LIVE site
  (a replaced build dir under a running server = broken chunks until
  restart).
- Verify with throwaway users/data on the live system, then clean up —
  ideally through the app's own deletion path, which tests it for free.
- Keep a per-project `AGENT_ONBOARDING.md` (the `handoff` skill) from day 1.
