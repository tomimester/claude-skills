# Appify — Codemagic CI → TestFlight (reference)

The working pipeline lives in `github.com:tomimester/maszoedzes` →
`codemagic.yaml` (workflow `ios-rn-testflight`). Copy it and change the
app-specific values. Push to `main` = build, sign, upload to TestFlight.

## Why Codemagic (decision, 2026-07-11)

Whole pipeline in one repo YAML, driven from the server with no local Xcode
or Mac; first-class Expo/RN support; free tier (500 macOS min/month) covers a
small app. Xcode Cloud was rejected: workflow editing requires Xcode on a
Mac, and it's Apple-only.

## Shared vs per-app setup

SHARED across all of Tomi's apps (already exists, do NOT recreate):
- Codemagic account connected to the GitHub org/user.
- App Store Connect API key (App Manager role) — Codemagic integration name
  `maszoedzes_asc` (see memory `maszoedzes-ios-ci`); reusable for any app in
  team `5U7C73B2V9`.
- The persistent `CERTIFICATE_PRIVATE_KEY` in Codemagic secure group
  `signing` (Apple allows max 2 distribution certs — REUSE this one).

PER APP you need:
- Bundle id registered (App IDs) + app created in App Store Connect (note
  the ASC numeric app id).
- A Codemagic "application" pointing at the repo + the copied workflow.
- Capabilities on the App ID if used (e.g. Associated Domains for Universal
  Links / auth hand-off).

## The signing gotchas (each cost real debugging time)

1. Fresh setup has no cert/profile → `app-store-connect fetch-signing-files
   <bundle-id> --type IOS_APP_STORE --create`.
2. Ephemeral build VMs lose the cert's private key → generate once, store as
   `CERTIFICATE_PRIVATE_KEY` env var in a secure group, feed it to
   `keychain add-certificates`.
3. Stale provisioning profile after adding a capability → `--delete-stale-profiles`.
4. "Missing Compliance" prompt blocks TestFlight → `ITSAppUsesNonExemptEncryption=false`
   in the app config (Expo: `ios.infoPlist`).
5. Upload-only: `submit_to_testflight: false` until TestFlight test info is
   filled (external beta review needs it).

## Build numbering (owner's convention)

- Marketing version stays `1.0` until public launch; bump to 1.1 after.
- Build number = ASC latest TestFlight build + 1, derived in the workflow:
  `app-store-connect get-latest-testflight-build-number <ASC_APP_ID>` + 1
  (with a floor). Never hardcode; parallel version trains in TestFlight are
  confusing (a stray train can just be expired in ASC).

## Expo specifics in the workflow

- `npx expo prebuild --platform ios` generates the Xcode project on the VM
  (project/scheme name = sanitized app name — check what it sanitizes to).
- Then standard: pod install, `xcode-project use-profiles`, xcodebuild
  archive via `xcode-project build-ipa`, `app-store-connect publish`.

## Ops notes

- Every push to `main` triggers a build — harmless for web-only commits, but
  remember it consumes free minutes; expire junk builds in ASC.
- Name workflows unambiguously in the `name:` field (the owner once ran an
  old workflow because the names looked alike).
- No Codemagic API token on the server by default; with one, the agent can
  trigger/monitor builds itself instead of asking the owner to click.
