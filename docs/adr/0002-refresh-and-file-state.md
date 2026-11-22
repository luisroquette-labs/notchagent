# ADR 0002: Refresh only when macOS can provide valid data

## Context

The scheduler owns provider polling and persistence. During dark wake, Keychain reads fail because macOS cannot present UI; a recorded app log attributed 156 of 169 Keychain failures to this state. Immediately after a real wake, SecurityAgent can still reject access while the system settles. URL resource metadata can also be cached for an instance while a transcript grows.

## Decision

Skip ordinary refresh ticks between sleep and wake notifications. Schedule the wake-triggered refresh three seconds after wake. Keep refresh ownership in one scheduler. Read transcript modification time and size through `FileManager.attributesOfItem` when calculating `FileStamp`.

## Consequences

The app avoids predictable authorization failures during sleep and sees current transcript metadata. The delay does not currently block a periodic tick that fires within three seconds after wake; [issue #6](https://github.com/luisroquette-labs/notchagent-personal/issues/6) tracks this race. Changes to the sleep gate or file stamp path require tests against real macOS behavior.
