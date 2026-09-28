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
- Uploaded build processing status: processing
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
