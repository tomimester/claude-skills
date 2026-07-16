# Appify — App Store submission checklist (reference)

The exact path walked for Mászóedzés v1.0 (submitted 2026-07-15). Drive the
user through it one step at a time — they click, you prepare every text and
asset and verify each gate before moving on.

## A. Hard prerequisites (build these, don't wait for review to ask)

- **Apple Developer Program** ($99/yr) — enrolled once for Adattenger Kft. /
  team `5U7C73B2V9`.
- **Sign in with Apple** if any other social login exists (guideline 4.8).
  Console: App ID + Service ID + Key (.p8, downloadable ONCE — store outside
  the repo, chmod 600, back up off-server). Client secret = ES256 JWT,
  expires ~6 months → copy `scripts/renew-apple-secret.sh` + monthly cron +
  failure alert email from the reference repo.
- **In-app account deletion** (guideline 5.1.1(v)) — a visible "Profil
  törlése" with confirm, wired to a real server delete. Verify by deleting a
  throwaway account through the app.
- **Public legal pages** on the project domain, reachable WITHOUT login:
  - `/adatvedelem` — Hungarian GDPR-standard privacy policy: controller
    block (cégjegyzékszám + court), per-purpose table (kezelt adatok / cél /
    jogalap with GDPR 6. cikk points / időtartam), adatfeldolgozók with
    addresses + policy links, session-cookie statement, érintetti jogok
    (GDPR 15–21. cikk), NAIH block (1055 Budapest, Falk Miksa utca 9-11.),
    kiskorúak, module for changes.
  - `/aszf` — ÁSZF: Szolgáltató block, fogalmak, szerződés létrejötte (Ptk.
    2013. évi V., Ekertv. 2001. évi CVIII.), díjmentesség (or IAP terms!),
    felelősség-korlátozás, panaszkezelés (30 nap) + Budapesti Békéltető
    Testület, irányadó jog.
  - `/tamogatas` — support page with the support email.
  - Copy from maszoedzes (`src/app/{adatvedelem,aszf,tamogatas}/page.tsx`,
    operator constants in `src/lib/legal.ts`) and adapt. Link all three from
    the app (Profil footer) and the site.
- `ITSAppUsesNonExemptEncryption=false`.

## B. TestFlight round

1. Codemagic build on `main` (see ci-codemagic.md).
2. On-device test the STANDALONE build (not Expo Go): every login provider
   (email magic link ONLY misbehaves in standalone builds), a full core
   flow offline (airplane mode), account deletion.
3. **THE mandatory test, every login provider, before ever submitting**:
   reset the device to zero and retry. Sign out → Settings → Safari →
   Advanced → Website Data → delete the site's entry → Settings → [name] →
   Sign-In & Security → Sign in with Apple → the app → Stop Using Apple ID
   → relaunch → sign in again. This is the ONLY test that reproduces what
   an App Review device does (no prior engagement with your site). A test
   on your own already-signed-in device proves nothing about first-time
   login — see the WebKit cookie-gesture trap in architecture.md, which
   passes every normal test and fails 100% of the time for App Review.
4. Fix → push (server-side auth fixes need no rebuild) → retest step 3
   until clean. Only then start the listing.
5. **If a ratings/review prompt was built (see architecture.md § Ratings &
   reviews), test it as ITS OWN checklist item, separately from the rest —
   it does not fail the obvious way (the app still opens fine), so it's the
   one thing that's easy to silently never verify.** It also doesn't test
   like the rest of the on-device pass: it isn't something you check "does
   it work" on immediately after install — the whole point is it should NOT
   fire right after launch. Verify instead: (a) walk to the actual milestone
   the trigger is gated on (e.g. finish N sessions) and confirm the call
   fires there (log/breakpoint), not before; (b) confirm it does NOT fire on
   first app open or right after an induced error; (c) expect the visible
   system sheet to stop appearing after a few manual retries on the same
   device/Apple ID — that's Apple's 3x/365-day cap, not a bug, don't chase it.

## C. App Store Connect listing (per-field)

- **Name** ≤30, **Subtitle** ≤30, **Promotional Text** ≤170, **Description**
  ≤4000, **Keywords** ≤100 chars INCLUDING commas/spaces (drop spaces after
  commas if tight; don't repeat words already in name/subtitle — Apple
  indexes those automatically).
- **Category**: pick primary + secondary. **Age rating**: questionnaire,
  all-no → 4+.
- **URLs**: Support = `/tamogatas`, Marketing = site root; Privacy Policy
  URL goes on the App Privacy page = `/adatvedelem`.
- **Copyright**: `<year> Adattenger Kft.` — no © needed.
- **Routing App Coverage File**: leave empty (nav apps only).
- **Screenshots**: the accepted sizes ASC actually enforces (2026):
  1284×2778 or 1242×2688 (6.5/6.7-class portrait). Owner's iPhone 13 mini
  shoots 1080×2340 — SAME aspect ratio to within 0.1%, so resize (not crop)
  to 1284×2778 with "maintain aspect ratio" OFF (iloveimg.com/resize-image
  works on-phone; sharp is on the server if files are on disk). 4–5 shots;
  the first one carries search results — lead with the most information-rich
  screen. Take them from the TestFlight build with realistic data.

## D. App Privacy nutrition label

Two-phase UI: first CHECK the data types and save; then each type appears as
a "Set Up <type>" card where the three questions live.

For a Mászóedzés-shaped app the types are: Contact Info → Email Address,
Name; Identifiers → User ID; User Content → Other User Content; (+ Health &
Fitness → Fitness if it's a training log). For each:
- Use: **App Functionality**; add **Analytics** for the types a first-party
  admin dashboard analyzes (user counts, feature usage). First-party
  analytics is NOT "tracking".
- Linked to identity: **Yes**. Tracking: **No**.
Skip: avatar URL, server IP logs (infrastructure, not SDK collection).
Then **Publish** the label.

## E. App Review Information + final gates

- **Sign-in required**: for password-less apps (Apple/Google/email-link
  only) leave the credential fields empty and explain in **Notes** (English)
  that the reviewer should use Sign in with Apple; include a 3-line "how to
  test the core flow" and the account-deletion location. (Template: the
  Mászóedzés reviewer note in memory `maszoedzes-appstore-listing`.)
- Contact info: name, phone, email.
- **Content Rights** (App Information page): "No — does not contain
  third-party content" (user-entered + first-party content only). REQUIRED —
  submission blocks without it.
- **Pricing**: pick Free (tier 0). REQUIRED — submission blocks without it.
- **Version release**: "Manually release this version" for a first launch.
- Attach the tested build → **Add for Review → Submit**.

## F. After submission

- Review typically ~24–48h; statuses arrive by email.
- Rejection playbook: read the Resolution Center message, fix or reply —
  common first-app items: reviewer sign-in trouble (prevented by the note),
  guideline 4.2 minimum functionality (prevented by real native UI — never
  a webview wrapper), 2.1 info requests (just answer), privacy-label
  mismatch (align label with the policy).
- Post-approval: manual release when ready; then bump marketing version for
  the next cycle per the numbering convention.
