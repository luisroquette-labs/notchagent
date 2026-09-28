# Mac App Store release evidence

## Local artifact

- Branch: `feat/mac-app-store-sdd`
- Baseline: `84e70e9548129c9f50f8fef2cf5cea3880bc6b2a`
- Version/build: `3.5.5 (12)`
- Bundle ID: `br.com.lfrprojects.notchagent.appstore`
- Canonical gate: `~/.local/bin/mac-gate Scripts/check-mac-app-store.sh`
- Gate result: PASS on 2026-09-28
- Tests: 596 Direct + 596 App Store; zero failures
- Release build: unsigned validation build succeeded
- Bundle inspection: sandbox contract, icon, privacy manifest, no Sparkle,
  launch agent, firmware helper, or external CLI path

## Pending Apple evidence

- Registered App ID: pending
- App Store Connect Apple ID: pending
- Signed archive commit: pending
- Development-signed archive: created locally on 2026-09-28
- Distribution certificate/profile: blocked — Xcode has no signed-in Apple
  account and the Keychain has no Mac App Distribution or Mac Installer
  Distribution identity
- Uploaded build processing status: pending
- TestFlight clean-install result: pending
- App Review submission: requires final owner authorization
- Review result and public App Store URL: pending

Never replace a pending value with a claim unless the exact Apple screen or API
response was observed and the version/build/commit match the archived binary.
