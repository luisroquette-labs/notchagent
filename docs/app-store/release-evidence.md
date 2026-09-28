# Mac App Store release evidence

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

- Version/build: `3.5.5 (18)`
- Source commit: `edd4cb304d9c971e12cff18c39b2afd2d9690b4e`
- Canonical gate: PASS on 2026-09-28; 610 Direct + 610 App Store tests,
  zero failures; Store bundle inspection passed
- Archive: `dist/NotchAgentAppStore-3.5.5-18-edd4cb3.xcarchive`
- App Store package: `dist/app-store-export-edd4cb3/NotchAgent.pkg`
- Binary SHA-256:
  `e696a1f9c91b0720f8861dfe95ae706eaa12b7071f4f90483a4208124b724020`
- Package SHA-256:
  `8fbbf951d4abc92bf68a4c3682831f247488ffe841d57643ac44e8545fb54a66`
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
- Upload: succeeded on 2026-09-28 at 17:59 BRT; App Store Connect API
  confirmed build 18 as `VALID` and `APP_STORE_ELIGIBLE`
- App Store Connect version: build 18 selected for macOS 3.5.5; release remains
  manual and state remains `PREPARE_FOR_SUBMISSION`
- Screenshot replacement: pending final authorization to remove the five
  obsolete assets before uploading the four current dark-UI images
- Submission: not added for review; final owner authorization remains required
