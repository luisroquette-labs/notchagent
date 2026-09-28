# Mac App Store release evidence

## Local artifact

- Branch: `feat/mac-app-store-sdd`
- Baseline: `84e70e9548129c9f50f8fef2cf5cea3880bc6b2a`
- Version/build: `3.5.5 (12)`
- Bundle ID: `br.com.lfrprojects.notchagent.appstore`
- Canonical gate: `~/.local/bin/mac-gate Scripts/check-mac-app-store.sh`
- Gate result: PASS on 2026-09-28
- Tests: 596 Direct + 596 App Store; zero failures
- Release build: development-signed archive succeeded
- Bundle inspection: sandbox contract, icon, privacy manifest, no Sparkle,
  launch agent, firmware helper, or external CLI path
- Source commit: `4f059024b3b065bc724692225517a98766b4ff73`
- Archive: `dist/NotchAgentAppStore-3.5.5-12-4f059024b3b0.xcarchive`
- Binary SHA-256:
  `2751b5c62d3f5c2926477f548c1749bc5054f7baad3f30116f08f92b2ae280e2`
- Archive verification: strict deep code-sign validation passed; universal
  `x86_64 arm64`; sandbox entitlements embedded

## Pending Apple evidence

- Registered App ID: pending
- App Store Connect Apple ID: pending
- Signed archive commit: `4f059024b3b065bc724692225517a98766b4ff73`
- Development-signed archive: verified locally on 2026-09-28
- Distribution certificate/profile: blocked — Xcode has no signed-in Apple
  account and the Keychain has no Mac App Distribution or Mac Installer
  Distribution identity
- Uploaded build processing status: pending
- TestFlight clean-install result: pending
- App Review submission: requires final owner authorization
- Review result and public App Store URL: pending

Never replace a pending value with a claim unless the exact Apple screen or API
response was observed and the version/build/commit match the archived binary.
