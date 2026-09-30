# App Store rejection correction — 2026-09-30

- App: NotchAgent, Apple ID `6817046228`, macOS `3.5.5`.
- Rejected build: `20`; submission `f663ed65-549e-4a0c-a7f5-223257512f2d`.
- Apple issue: guideline 2.4.5, unused `com.apple.security.network.server`.
- Source audit: submitted Desk integration uses USB/serial; no inbound network listener exists in this source tree.
- Correction: remove the entitlement from both XcodeGen and the entitlement plist; retain sandbox, outgoing-network, read-only folder/bookmark, and USB/serial access.
- Regression: `AppStoreDistributionTests.testStoreEntitlementsExcludeUnusedNetworkServerPermission`; release gate rejects the unused server permission.
- Replacement: `3.5.5 (21)`, source `f16f4cabd8a67935d8a490b7ad3626459972fdfc`, based on rejected build source `2ed8cf09252dd2d3c019a1e64ca5941dae7402eb`.
- Canonical gate: `mac-gate Scripts/check-mac-app-store.sh`, PASS. Direct: 611 tests, 9 skipped, zero failures. Store: 611 tests, 11 skipped, zero failures. Skips retain existing opt-in test requirements.
- Archive: `dist/NotchAgentAppStore-3.5.5-21-f16f4ca.xcarchive`; strict deep signature verification passed; universal `x86_64 arm64`.
- Archive binary SHA-256: `b7556efd4d853233e036b7df078f6c87a234fd68f0b1ef03eda07e87f9eb6c41`.
- Distribution package: `dist/app-store-export-f16f4ca-api/NotchAgent.pkg`; SHA-256 `013279259ebdcfb8c41fe9453184df62ca240410b559d1d4164ceecbaccc174b`.
- Exported package expanded and inspected: strict signature validation passed, sandbox enabled, network client enabled, network server absent, build 21 and correct bundle identifier.
- Upload succeeded at 11:18 BRT on 2026-09-30. Apple build ID `668ff995-287a-4d4a-9b9a-df1e7aed6028` subsequently verified as `VALID` and `APP_STORE_ELIGIBLE`.
- Review notes: correction explanation persisted and read back via App Store Connect API.
- Existing Direct checkout and other worktrees preserved. No GitHub push, public source sync, or Direct release was needed for this App Store correction.

## Resubmission verified

- Build 21 selected for macOS 3.5.5 and read back from the version/build relationship.
- Existing rejected review item marked resolved after the corrected build was selected.
- Submission `f663ed65-549e-4a0c-a7f5-223257512f2d` resubmitted on 2026-09-30; API read-back confirms `WAITING_FOR_REVIEW`.
- Version `723c5441-af21-4c59-bc67-a1db93b71a48` confirms `WAITING_FOR_REVIEW`, release type `MANUAL`.
- Apple approval and public App Store availability remain pending.
