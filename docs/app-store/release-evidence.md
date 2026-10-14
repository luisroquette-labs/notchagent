# Mac App Store release evidence

## Guided setup update candidate — 3.6.0 (23)

- Current source fix `2ebd6ad`: the Store Claude card leads with local session
  tokens and seven-day local tokens, then links to Claude's official Usage
  settings. It no longer displays the API-equivalent dollar estimate beside
  subscription activity. The link opened `https://claude.ai/settings/usage`
  on the live Mac; Claude's own page showed 5% used for the session and week
  at the time of inspection. The Store app does not claim those percentages
  are derivable from local transcripts.
- Canonical gate: PASS on 2026-10-14, 620 Direct tests (9 opt-in skips), 623
  Store tests (11 opt-in skips), zero failures; Release sandbox build passed.
  Signed universal archive passed strict deep verification. The exported
  package has a valid Apple installer signature and no network-server
  entitlement. It has not been uploaded or submitted to Apple.
- Current archive: `dist/NotchAgentAppStore-3.6.0-23-2ebd6ad.xcarchive`.
  Current package: `dist/app-store-export-2ebd6ad/NotchAgent.pkg`; SHA-256
  `cc51006b80a570645ab2e5e5a6db1f54c3dd053be744ffd1bda336f8033a2854`.
  Current local preview: `~/Applications/NotchAgent 3.6 Preview.app`.
  Visual inspection confirmed the Claude card shows live local session usage,
  seven-day usage, and the official-usage button without a dollar estimate;
  Codex remains visible beside it and Quit is present at the panel bottom.

- Current source fix `5f184e2`: the Store build no longer labels local Claude
  token budgets as subscription quota. A live Mac showed a false 0% weekly
  remainder from 2.34 billion local tokens versus an 8 million token default
  budget. The Store build now shows local usage and explicitly says the
  official Claude quota is unavailable; persisted estimates are sanitized on
  launch. Direct distribution behavior is unchanged. Localized product copy
  and review notes were corrected to match.
- Canonical gate after the quota fix: PASS on 2026-10-14, 619 Direct tests
  (9 opt-in skips), 622 Store tests (11 opt-in skips), zero failures; Release
  build and sandbox bundle inspection passed. The signed archive passed strict
  deep verification and the exported package has a valid Apple installer
  signature. No network-server entitlement is present.
- Previous archive: `dist/NotchAgentAppStore-3.6.0-23-5f184e2.xcarchive`.
  Previous App Store package: `dist/app-store-export-5f184e2/NotchAgent.pkg`;
  SHA-256 `f5250d726079a8eb8cb89b53f5e76220d71cd245df50b095594ec8e478158b30`.
  It supersedes the `9bd28f7` package below and has not been uploaded.
- Earlier local preview: `~/Applications/NotchAgent 3.6 Preview.app` from the
  development-signed `5f184e2` archive. After the user authorized `.claude`
  and `.codex`, Settings confirmed 130 Claude Code session files and 300 Codex
  session files. The compact notch announced “Claude Code: cota oficial
  indisponível” while continuing to show Codex's weekly quota. Settings no
  longer exposes arbitrary Claude token budgets and explains the limitation.

- Source fix `9bd28f7`: Settings now refreshes its folder inspection when
  guided setup changes the saved authorization. The earlier candidate showed
  stale “Acesso necessário” in Settings after the Codex folder had been
  authorized; the wizard had already confirmed session data. A regression
  contract test covers the notification subscription.
- Canonical gate after the fix: PASS on 2026-10-14, 618 Direct tests and 620
  App Store tests, zero failures; unsigned Release build and sandbox checks
  passed. Signed archive passed strict deep verification; the exported package
  has a valid Apple installer signature and the app is universal `x86_64 arm64`.
- Previous archive: `dist/NotchAgentAppStore-3.6.0-23-9bd28f7.xcarchive`.
  Previous App Store package: `dist/app-store-export-9bd28f7/NotchAgent.pkg`;
  SHA-256 `1328e0619d9dd5751767254c2c97b7a77a6258aee2deaea2d6abff7bcb96c3f6`.
  It supersedes the `ddd071d` package below and has not been uploaded.
- Updated local preview at `~/Applications/NotchAgent 3.6 Preview.app` from
  the development-signed archive. After the user authorized `~/.codex`, the
  guided setup confirmed 298 Codex session files. The updated preview then
  displayed 299 session files with verified usage in Settings and showed
  Codex quota data in the notch panel. Claude Code access remains ungranted.

- Source commit: `ddd071d93335dff4050d6aadcc9c40e0b9ce3a57` (visible Quit action and review metadata); prior
  distribution-version fix: `bfd21773385d4549030bcece0609f264604b3e6a`.
- Canonical gate: PASS again on 2026-10-14; 618 Direct tests (9 opt-in skips),
  620 App Store tests (11 opt-in skips), zero failures; Release build and
  sandbox bundle inspection passed.
- Distribution contract: PASS again; the Direct `3.5.5` appcast remains aligned with
  `VERSION`, while `APP_STORE_VERSION` independently selects `3.6.0`.
- Full NotchAgent Desk gate on `bfd2177`: PASS with an isolated ESP32 `3.3.8` toolchain and
  pinned libraries; firmware packaging, 618 Swift tests, Sparkle contract, and
  public-source audit passed without changing the user's Arduino installation.
- Archive: `dist/NotchAgentAppStore-3.6.0-23-ddd071d.xcarchive`; signed,
  strict deep verification passed, universal `x86_64 arm64`.
- Exported App Store package: `dist/app-store-export-ddd071d/NotchAgent.pkg`;
  SHA-256 `64d9e595ba2619b586f56d64e2a86a83ce4b9b8789029746a75e6029275c189e`.
- Exported app: Apple Distribution signature verified; version `3.6.0 (23)`,
  sandbox and read-only user-selected folder access embedded; no inbound
  network-server entitlement. Binary SHA-256:
  `8066e922f7bf55a92aca19a6d0a86632b25d8a58f70b91ac8d8191e376457400`.
- Local smoke test: copied the development-signed archive app to
  `~/Applications/NotchAgent 3.6 Preview.app`. Closed running Store `3.5.5`,
  launched preview `3.6.0 (23)`, observed guided setup in Portuguese, English,
  and Spanish; Codex Connect opened the home folder with `.codex` visible and
  an explicit authorization prompt. No folder access was granted during this
  test. Quit button appeared in the expanded notch panel and terminated the
  preview process; relaunched it and reopened guided setup from Settings.
- App info privacy-policy URL read back from App Store Connect API on
  2026-10-14: `https://notchagent.app/privacy`; marketing, support and privacy
  URLs returned HTTP 200.
- App Store Connect read-back on 2026-10-14: macOS `3.5.5 (22)` is
  `READY_FOR_SALE` and build 22 is `VALID`. Draft version `3.6.0` is
  `PREPARE_FOR_SUBMISSION` with manual release and no selected build.
  Version ID: `ebf1e59b-6377-4130-902e-a64abc8d86c0`.
- The draft's PT-BR description and What's New text describe the guided setup;
  both were read back through the API. On 2026-10-14, What's New and reviewer
  notes were updated to describe the Quit control and 3.6.0 setup, replacing
  stale reviewer notes that referred to build 22; both were read back exactly.
  EN-US and Spanish copy remains drafted in `metadata.md` for later localization.
- The draft inherited the four current `APP_DESKTOP` screenshots; all four
  assets are `COMPLETE`. App availability read-back shows Brazil and the USA
  enabled, China mainland disabled, and 175 territories configured.
- The developer-signed app passed the first-launch/Settings smoke test. An
  App Store installed-build smoke test and App Store Connect data-collection
  label read-back remain before submission.

The App Store submission is a separate publication step requiring the owner's
final authorization.

## Local artifact

- Branch: `feat/mac-app-store-sdd`
- Baseline: `84e70e9548129c9f50f8fef2cf5cea3880bc6b2a`
- Version/build: `3.5.5 (15)`
- Bundle ID: `br.com.lfrprojects.notchagent.appstore`
- Canonical gate: `~/.local/bin/mac-gate Scripts/check-mac-app-store.sh`
- Gate result: PASS on 2026-09-28
- Tests: 598 Direct + 598 App Store; zero failures
- Release build: signed archive succeeded
- Bundle inspection: sandbox contract, icon, privacy manifest, no Sparkle,
  launch agent, firmware helper, or external CLI path
- Source commit: `2bd26ddcd0c488b135f9b7ee9ee6aee14cf1679a`
- Archive: `dist/NotchAgentAppStore-3.5.5-15-2bd26dd.xcarchive`
- Binary SHA-256:
  `68c40a6e725bc15e659d5591304abadfe98cda903fff2558e67035e2f269ca47`
- Archive verification: strict deep code-sign validation passed; universal
  `x86_64 arm64`; sandbox entitlements embedded
- App Store package:
  `dist/app-store-export-2bd26dd/NotchAgent.pkg`
- Package SHA-256:
  `77aa046ff37cfad596ec5facde8df62de9a3b7fda6c3fa6c878f3c048d69c574`
- Distribution signing: Cloud Managed Apple Distribution, profile
  `Mac Team Store Provisioning Profile: br.com.lfrprojects.notchagent.appstore`;
  installer certificate expires 2027-09-28

## Pending Apple evidence

- Registered App ID: `6817046228`
- App Store Connect Apple ID: `6817046228`
- Signed archive commit: `2bd26ddcd0c488b135f9b7ee9ee6aee14cf1679a`
- Signed archive: verified locally on 2026-09-28
- Distribution certificate/profile: generated and verified
- Upload: build 15 accepted by App Store Connect on 2026-09-28 at 15:18 BRT
- Uploaded build processing status: ready to submit; confirmed in App Store
  Connect at 15:19 BRT
- Export compliance: `ITSAppUsesNonExemptEncryption=false` embedded and
  verified in the archived app
- Visual acceptance: canonical dark UI and all mascot sprites verified from
  the archived build before upload
- Replacement screenshots: five opaque RGB PNGs at 1440x900 from
  `dist/app-store-screenshots-v14/` uploaded and visible in App Store Connect
- TestFlight clean-install result: pending
- App Review submission: requires final owner authorization
- Review result and public App Store URL: pending

Never replace a pending value with a claim unless the exact Apple screen or API
response was observed and the version/build/commit match the archived binary.

## Presentation-polished candidate

- Version/build: `3.5.5 (16)`
- Source commit: `f975bfe3c03f9dbf13e2734249ff11d1b24badd5`
- Canonical gate: PASS on 2026-09-28; 598 Direct + 598 App Store tests,
  zero failures; Store bundle inspection passed
- Archive: `dist/NotchAgentAppStore-3.5.5-16-f975bfe.xcarchive`
- App Store package: `dist/app-store-export-f975bfe/NotchAgent.pkg`
- Binary SHA-256:
  `cbcfe114de83a1100ecaf46534d16f06423011a570a6fa3a4ef640ea61fd63ac`
- Package SHA-256:
  `6f83cc8b4711c9378c071017ab5f16aa0d8283736d8fe073c67cd2ea0b268c6d`
- Archive verification: strict deep code-sign validation passed; universal
  `x86_64 arm64`; `ITSAppUsesNonExemptEncryption=false`
- Upload: succeeded on 2026-09-28 at 15:57 BRT; App Store Connect API
  confirmed build 16 as `VALID` and `APP_STORE_ELIGIBLE`
- Presentation: distinctive pixel-agent icon, conversion-focused PT-BR/EN
  metadata, and five 2880x1800 screenshots prepared locally
- App Store Connect version: build 16 selected for macOS 3.5.5; release remains
  manual and state remains `PREPARE_FOR_SUBMISSION`
- PT-BR product page: subtitle, promotional text, description, and keywords
  persisted through the App Store Connect API
- Screenshot set: exactly five `APP_DESKTOP` assets, all `COMPLETE`, ordered
  `01-custos-e-decisoes.png` through `05-antecipe-limites.png`
- Submission: not added for review; reviewer contact details are complete
- Safety: a rejected desktop capture containing another app was deleted before
  use or upload; the approved set contains only NotchAgent UI

## Final merged candidate

- Version/build: `3.5.5 (19)`
- Source commit: `06224497775cb5f477559127b8191c37701b88b5`
- Canonical gate: PASS on 2026-09-28; 610 Direct + 610 App Store tests,
  zero failures; Store bundle inspection passed
- Archive: `dist/NotchAgentAppStore-3.5.5-19-0622449.xcarchive`
- App Store package: `dist/app-store-export-0622449/NotchAgent.pkg`
- Binary SHA-256:
  `d8e49ac5a8ec24578bbecc4d64d1480405a337f420c082fe408a709b94e02dea`
- Package SHA-256:
  `610b7714c74a6a9bcd3a3bf9c6988604a1512e3c9796ff6fc16eb495ab3d702e`
- Archive verification: strict deep code-sign validation passed; universal
  `x86_64 arm64`; sandbox entitlements and
  `ITSAppUsesNonExemptEncryption=false` embedded
- App Store defaults: weather disabled until user opt-in; paid Anthropic probe,
  Resend email delivery, and Sparkle absent from the Store edition
- Privacy/support links: `https://notchagent.app/privacy` and
  `https://notchagent.app/support`, both live with HTTP 200
- Screenshots: four current dark-UI, opaque sRGB PNGs at 2880x1800 in
  `dist/app-store-screenshots-v17/`; obsolete no-data/probe screens excluded
- App Store Connect: reviewer contact, metadata, Developer Tools/Productivity
  categories, third-party content declaration, and all-zero age questionnaire
  persisted through the API
- Commercial setup: free price persisted with USA base territory; all 175
  current storefront territories enabled, including future territories
- Upload: succeeded on 2026-09-28 at 18:21 BRT; App Store Connect API
  confirmed build 19 as `VALID` and `APP_STORE_ELIGIBLE`
- App Store Connect version: build 19 selected for macOS 3.5.5; release remains
  manual and state remains `PREPARE_FOR_SUBMISSION`
- Screenshot replacement: pending final authorization to remove the five
  obsolete assets before uploading the four current dark-UI images
- Submission: not added for review; final owner authorization remains required

## App icon correction

- Version/build: `3.5.5 (20)`
- Source commit: `2ed8cf09252dd2d3c019a1e64ca5941dae7402eb`
- Audit gap: the Store target relied only on a legacy `AppIcon.icns`; the gate
  did not require the asset-catalog path Apple documents for App Store icons
- Fix: the Store target now compiles all 10 macOS icon variants from
  `Resources/Assets.xcassets/AppIcon.appiconset`, including 1024x1024
- Regression gate: requires the source icon set, compiled `Assets.car`, and
  `CFBundleIconName=AppIcon`
- Canonical gate: PASS on 2026-09-28; 610 Direct + 610 App Store tests, zero
  failures; Store bundle inspection passed
- Archive: `dist/NotchAgentAppStore-3.5.5-20-2ed8cf0.xcarchive`
- App Store package: `dist/app-store-export-2ed8cf0/NotchAgent.pkg`
- Binary SHA-256:
  `22c42c0c3193f6b345aaa4b982df15e0cb0e2f704738c8d50d790ddc81e179ba`
- Package SHA-256:
  `399c39957e8b03d124aa18892c970763c85b58ef731d1cd941b643284ad04bee`
- Archive verification: strict deep code-sign validation passed; universal
  `x86_64 arm64`; compiled catalog contains all sizes through 1024x1024
- Upload: succeeded on 2026-09-28 at 19:20 BRT
- App Store Connect: build 20 is `VALID`, `APP_STORE_ELIGIBLE`, exposes an
  Apple-hosted icon asset, and is selected for macOS 3.5.5
- Release state: `PREPARE_FOR_SUBMISSION`, manual release; not submitted for
  review
