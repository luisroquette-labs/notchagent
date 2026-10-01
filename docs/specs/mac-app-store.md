# NotchAgent for Mac App Store

Status: Draft for implementation
Owner: Luis Roquette
Implementation branch: `feat/mac-app-store-sdd`
Baseline: `84e70e9548129c9f50f8fef2cf5cea3880bc6b2a`

## Objective

Ship a sandboxed Mac App Store edition from the same source tree without
regressing the existing Developer ID distribution. The Store edition must be
useful without executing tools installed elsewhere on the Mac, and every
reduced capability must be visible rather than silently returning stale data.

## Distribution contract

| Capability | Direct edition | App Store edition |
| --- | --- | --- |
| Claude and Codex transcript totals | Automatic home-folder discovery | User-authorized folders with persistent security-scoped bookmarks |
| Codex official quota through `codex app-server` | Available | Unavailable; local transcript quota fallback remains |
| API account portals and outbound APIs | Available | Available through sandbox network-client access |
| Sparkle updates | Available | Removed; updates come from the App Store |
| Desk network and USB mirroring | Available | Available with local-network, client/server, USB, and serial entitlements |
| Desk firmware recovery helper | Available | Disabled until the embedded helper passes sandbox and App Review validation |
| Launch at login | Available with explicit user action | Available with explicit user action |
| Desk crash watchdog | Available | Disabled; no launch agent is bundled in the Store target |

## Requirements

### MAS-001 — Independent Store target

The project must generate a `NotchAgentAppStore` target that shares production
sources with `NotchAgent`, defines `APP_STORE`, uses the same semantic version,
and has a distinct build number and bundle identifier registered for macOS.

**Acceptance**

- Given a clean checkout, when XcodeGen runs, then both application targets are generated.
- Given the Store target, when its signature is inspected, then App Sandbox is enabled.
- Given the Direct target, when it is built, then its existing signing and update behavior is unchanged.

### MAS-002 — Minimum sandbox permissions

The Store target must request only the permissions it uses: outbound and
inbound networking, user-selected read-only files, app-scoped bookmarks, USB,
and serial devices. It must declare local-network and Bonjour usage in its
Info.plist. Temporary exception entitlements are forbidden.

**Acceptance**

- Given the archived Store app, when entitlements are inspected, then every expected entitlement is present and no temporary exception exists.
- Given local-network access is denied, when Desk discovery starts, then the app remains usable and displays a disconnected state.

### MAS-003 — Explicit local-data authorization

The Store edition must let the user authorize Claude Code, Claude Desktop, and
Codex data folders with `NSOpenPanel`. It must persist read-only app-scoped
bookmarks, resolve stale bookmarks, keep access active while providers scan,
and allow each grant to be revoked.

**Acceptance**

- Given no grant, when the Store app starts, then providers report that folder access is required.
- Given a selected parent folder, when the app restarts, then transcript data remains readable without another picker.
- Given a stale, corrupt, or revoked bookmark, when it is resolved, then the grant is cleared and the UI asks for authorization again.
- Given the Direct edition, when it starts, then existing automatic roots remain unchanged.

### MAS-004 — No external executable dependency

The Store edition must not launch `codex`, `gcloud`, Terminal, or any executable
outside its own bundle or container. Codex quota discovery must fall back to
authorized rollout files. CLI onboarding actions must open documentation rather
than spawn a process.

**Acceptance**

- Given `APP_STORE`, when provider composition is created, then no app-server reader is installed.
- Given `APP_STORE`, when API account discovery runs, then no `Process` is launched.
- Given a Store binary scan, then the prohibited executable paths are absent from reachable Store-only behavior.

### MAS-005 — Store-managed updates and helpers

The Store target must not link Sparkle, expose “Check for updates”, bundle the
Desk watchdog launch agent, or offer firmware recovery. The Direct edition must
retain all four behaviors.

**Acceptance**

- Given the Store target, when dependencies and bundle contents are inspected, then Sparkle, the watchdog plist, and Desk firmware helper are absent.
- Given the Store UI, when Settings and the menu are opened, then update and firmware-recovery controls are absent or explicitly unavailable.
- Given the Direct target, when its distribution contract runs, then Sparkle and firmware recovery still pass.

### MAS-006 — Privacy and reviewability

The Store build must make no paid AI request during tests or review. A reviewer
must be able to understand the product without personal credentials through
sample data or deterministic screenshots. App Store privacy answers must match
the code’s actual off-device data flows, including user-configured Resend email.

**Acceptance**

- Given `NOTCHAGENT_DISABLE_PAID_PROBES=1`, when all tests and review flows run, then no paid AI endpoint is invoked.
- Given no connected accounts, when the app opens, then onboarding explains folder authorization and available portal connections.
- Given the privacy inventory, when compared with source calls, then every off-device destination is documented.

### MAS-007 — Versioned validation and evidence

One canonical script must validate Store configuration, compile the Store
target, inspect the product, and emit no credentials. Local tests must run only
through `mac-gate`. The final evidence must identify the exact commit, archive,
App Store Connect build, TestFlight result, and review status.

**Acceptance**

- Given a relevant source change, when the preflight runs, then unit tests and both distribution-contract checks pass.
- Given an uploaded build, when evidence is recorded, then its version/build and commit match the local artifact.

## Design

1. Keep one source tree and use the `APP_STORE` compilation condition only at distribution boundaries.
2. Reuse provider root injection; a single bookmark store supplies authorized Store roots.
3. Keep Direct defaults in `AppPaths`; do not add sandbox branching throughout parsers.
4. Remove unsupported features at composition and packaging boundaries, not with runtime failures.
5. Treat App Store Connect submission as an external publication gate requiring final owner authorization.

## Verification matrix

| Requirement | Automated evidence | Manual evidence |
| --- | --- | --- |
| MAS-001/002 | XcodeGen contract and entitlement assertions | Archive validation |
| MAS-003 | Bookmark-store unit tests | Grant, restart, revoke on a clean macOS user |
| MAS-004/005 | Store-boundary and bundle-content tests | Settings/menu inspection |
| MAS-006 | Paid-probe-disabled test suite and privacy scan | Review onboarding and screenshots |
| MAS-007 | `Scripts/check-mac-app-store.sh` | TestFlight install and launch |

## Rollback

The Store target is additive. If Store validation or review fails, stop Store
distribution and continue shipping the unchanged Direct edition. Never weaken
the Direct release gates or add temporary sandbox exceptions to obtain approval.
