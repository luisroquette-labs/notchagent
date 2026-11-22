# ADR 0001: Resolve assets in both app and SwiftPM bundles

## Context

The installed app and a direct SwiftPM run package assets differently. Looking only in `Bundle.main` made mascots fall back to procedural placeholders during `swift run` and `swift test`.

## Decision

`AssetBundle` searches the app bundle first, then the SwiftPM module bundle when available. It tries both the requested path and basename because packaging can flatten a resource directory. For SwiftPM's copied `Resources/Mascots` directory, it also tries the nested `Resources/` path.

## Consequences

The same asset lookup works for the installed app and direct development runs. New packaging layouts need a focused resource lookup test before another fallback path is added.
