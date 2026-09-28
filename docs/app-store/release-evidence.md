# Mac App Store release evidence

## Local artifact

- Branch: `feat/mac-app-store-sdd`
- Baseline: `84e70e9548129c9f50f8fef2cf5cea3880bc6b2a`
- Version/build: `3.5.5 (14)`
- Bundle ID: `br.com.lfrprojects.notchagent.appstore`
- Canonical gate: `~/.local/bin/mac-gate Scripts/check-mac-app-store.sh`
- Gate result: PASS on 2026-09-28
- Tests: 598 Direct + 598 App Store; zero failures
- Release build: signed archive succeeded
- Bundle inspection: sandbox contract, icon, privacy manifest, no Sparkle,
  launch agent, firmware helper, or external CLI path
- Source commit: `076bbcec8765c8b91533ef8455076f45fb481afe`
- Archive: `dist/NotchAgentAppStore-3.5.5-14-076bbce.xcarchive`
- Binary SHA-256:
  `387f97de8d349bd435fbc52fb1a83e70b276c0c4e77c39c6b0a64c629ed161c9`
- Archive verification: strict deep code-sign validation passed; universal
  `x86_64 arm64`; sandbox entitlements embedded
- App Store package:
  `dist/app-store-export-076bbce/NotchAgent.pkg`
- Package SHA-256:
  `1dfb1a6d9978b4b08b1045749d2bc1c6dc715d377569c77e6268f3b1c7a86671`
- Distribution signing: Cloud Managed Apple Distribution, profile
  `Mac Team Store Provisioning Profile: br.com.lfrprojects.notchagent.appstore`;
  installer certificate expires 2027-09-28

## Pending Apple evidence

- Registered App ID: `6817046228`
- App Store Connect Apple ID: `6817046228`
- Signed archive commit: `076bbcec8765c8b91533ef8455076f45fb481afe`
- Signed archive: verified locally on 2026-09-28
- Distribution certificate/profile: generated and verified
- Upload: build 14 accepted by App Store Connect on 2026-09-28 at 14:30 BRT
- Uploaded build processing status: processing
- Visual acceptance: canonical dark UI and all mascot sprites verified from
  the archived build before upload
- Replacement screenshots: five opaque RGB PNGs at 1440x900 prepared in
  `dist/app-store-screenshots-v14/`; not yet saved in App Store Connect
- TestFlight clean-install result: pending
- App Review submission: requires final owner authorization
- Review result and public App Store URL: pending

Never replace a pending value with a claim unless the exact Apple screen or API
response was observed and the version/build/commit match the archived binary.
