# App Store rejection correction — 2026-10-06

Apple rejected version 3.5.5 build 21 under guidelines 2.1(a), 5, and
5.2.5. Build 22 addresses all three findings:

- the standard Settings command and Command-comma now route to the real,
  reusable Settings window;
- customer-facing metadata no longer uses `Mac` or `OpenAI`;
- China mainland is excluded while provider functionality remains available in
  supported storefronts.

Required evidence before resubmission:

1. `mac-gate Scripts/check-mac-app-store.sh` passes.
2. A clean App Store Release build opens Settings from the application menu and
   Command-comma three consecutive times.
3. The archived build is version 3.5.5 (22), signed, sandboxed, and contains no
   inbound network-server entitlement.
4. App Store Connect reads back the corrected metadata and China availability.

## Local evidence

- `mac-gate Scripts/check-mac-app-store.sh`: passed on 2026-10-06; 613 tests
  passed in both the normal and `APP_STORE` suites, followed by a successful
  unsigned Release build and bundle inspection.
- Clean build 3.5.5 (22): Settings opened from Command-comma three consecutive
  times and from the application-menu Settings item. Each activation displayed
  the reusable `NotchAgent — Settings` window.
