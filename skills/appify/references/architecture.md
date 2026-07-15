# Appify — native app architecture (reference)

Extracted from `github.com:tomimester/maszoedzes`. File paths below refer to
that repo — open them for working code.

## Repo layout

```
<project repo>/
  (existing site: Next.js app, or the WP theme/plugin dir, etc.)
  shared/            # canonical domain logic used by BOTH clients
  native/            # the Expo app (own package.json!)
    app.json
    metro.config.js  # resolver alias for @shared + watchFolders
    src/app/         # expo-router routes
    src/components/
    src/lib/         # api.ts, auth.tsx, store.ts (offline), theme.tsx
```

- `shared/` holds pure TS: constants, enums, formatters, stats math, API
  types. Web imports via thin re-export stubs (so old import paths keep
  working); native imports via `@shared` alias.
- Metro: `watchFolders: [repoRoot]`, custom `resolveRequest` for the alias,
  and `"onDemandFilesystem": false` in app.json `experiments` — without the
  last one, imports outside the project root fail in Expo Go.

## Expo app conventions

- expo-router, TypeScript strict. Tabs in `src/app/(tabs)/_layout.tsx`;
  full-screen flows as `presentation: "fullScreenModal"` stack screens
  (Hevy-style slide-up for "active session"-type screens).
- Theme: one `theme.tsx` with light/dark palettes + semantic tokens
  (background/surface/fill/hairline/brand/muted/faint…) and a
  Világos/Sötét/Rendszer preference. NEVER hardcode colors in screens.
- Reusable pieces worth copying from maszoedzes: `OptionSheet` (bottom-sheet
  picker), `ScreenHeader` (fixed 52px bar, 22px title), `FeedbackTab`
  (right-edge tab → one-tap email to support inbox via the server),
  `WeeklyChart` (y-axis + range picker, client-side bucketing).
- `ITSAppUsesNonExemptEncryption: false` in `ios.infoPlist`.
- Icons/splash: `expo-splash-screen` plugin; reuse brand assets.

## API layer (`native/src/lib/api.ts`)

- One `api<T>(path, {method, body})` helper: `Authorization: Bearer <token>`
  header, JSON body, typed errors (`ApiError` with status).
- Token in `expo-secure-store`, memory-cached.
- Server: `/api/v1/*` route handlers on the existing backend. Auth helper
  (`apiUser(req)`) resolves the bearer token to a user. All write logic in
  one shared server module (maszoedzes: `src/lib/mutations.ts`) called by
  BOTH the web UI (server actions/forms) and the API routes.
- WordPress variant: content reads come free from `/wp-json/wp/v2/posts`,
  `/pages`, `/media` (public, no auth). Custom functionality = a small
  plugin exposing extra REST routes. Keep the same client-side `api.ts`
  shape.

## Auth: the one-time-code hand-off

Problem: OAuth completes in the system browser / in-app auth session, whose
cookie jar the app can't read.

Flow (maszoedzes files: `src/app/api/native/handoff/route.ts`,
`src/lib/native-auth.ts`, `src/app/api/v1/auth/redeem/route.ts`,
`native/src/lib/auth.tsx`, `native/src/app/auth.tsx`):

1. App opens `https://<site>/login?native=1&start=<provider>&to=<app scheme url>`
   in `WebBrowser.openAuthSessionAsync`.
2. Web login completes; server redirects to the hand-off route, which mints a
   **single-use code (256-bit, ~2 min TTL)** bound to the fresh session and
   307s to the whitelisted app scheme with `?code=`.
3. App exchanges the code at `/api/v1/auth/redeem` → long-lived bearer token
   → Keychain.

Traps (all hit in production, all solved in the reference code):
- **Apple OAuth**: form_post response drops SameSite=Lax cookies → the
  Auth.js callbackUrl cookie must be SameSite=None.
- **Email magic link**: the emailed link opens in PLAIN Safari, not the auth
  session. Two consequences: (a) a silent 307 to a custom scheme shows
  "cannot open page" — the hand-off must render a tap-to-open page
  (`?page=1` variant) instead; (b) the deep link back into the app is
  handled by expo-router as NAVIGATION — there must be an `app/auth.tsx`
  route that reads `?code=`, redeems, and `router.replace`s into the app.
  Without it: "Unmatched Route" and login silently fails. Also: dismiss the
  lingering auth session (`WebBrowser.dismissAuthSession()`) after redeem,
  and serialize redemption (a ref) so the auth-session result and the deep
  link don't double-spend the single-use code.
- **Only reproducible in a standalone build** — Expo Go behaves differently.
  Always retest all login paths on TestFlight.
- Cold start: validate stored token via `GET /me`; on 401 clear it.
- Sign-out must also wipe the local cache/outbox (it belongs to the user).

## Offline outbox (`native/src/lib/store.ts`)

- Reads: server-truth when reachable, cached JSON otherwise; every
  successful fetch refreshes the cache.
- Writes: optimistic local cache update + append to a persisted outbox;
  `flush()` replays in order. Idempotency: client generates UUIDs and
  timestamps; server upserts with conflict-ignore on the client id.
- **`flush()` must be ONE shared awaitable promise.** A "skip if already
  running" flag races: caller B returns before caller A's flush lands, and
  fresh records "vanish" until the next sync (symptom in maszoedzes: new
  sessions disappearing, finish needing two taps).
- 404-after-offline-start: the server may not know a locally-created record
  yet — reads must fall back to the local cache by id.

## Feedback loop feature (optional but cheap)

Server module sends email via the project's transactional provider (Brevo:
`POST https://api.brevo.com/v3/smtp/email`, sender locked to the project's
verified address, Reply-To = the user). One shared core + a web server
action + `POST /api/v1/feedback`. Client: right-edge "Visszajelzés" tab.
Brevo gotcha: the server's IP must be added to Brevo Authorised IPs.
