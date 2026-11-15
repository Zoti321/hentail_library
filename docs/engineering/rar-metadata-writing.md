# RAR metadata writing feasibility

## Decision

RAR/CBR writing is unavailable in the current build. Retain these Resources unchanged and show an unsupported result. Do not silently convert them to ZIP/CBZ. This resolves the feasibility investigation only; it is not native RAR writing support.

## Evidence

The installed `unrar-ng` dependency is an UnRAR reader. RARLAB distributes UnRAR source and an extraction DLL, not a general-purpose creation SDK. Its [distribution terms](https://www.rarlab.com/license.htm) restrict packaging the proprietary RAR/WinRAR program and reusing UnRAR to recreate the compression algorithm. The [official tools page](https://www.rarlab.com/rar_add.htm) distinguishes those extraction tools from RAR. A separately installed licensed RAR executable could be a desktop integration, but permission to redistribute it cannot be assumed.

The implementation host has no `rar`, `unrar` or `7z` executable on PATH and no standard Windows WinRAR installation. Therefore no actual RAR update experiment has been performed. Existing RAR4/RAR5 fixture reading verifies extraction only. It cannot establish creation/update safety, entry preservation, signature handling or a supported writer.

## Platform findings

- Windows: official WinRAR/RAR can create archives, but this build has no writer installed and bundles none. A user-installed-tool Adapter needs a separate implementation and verification ticket.
- macOS/Linux: official command-line RAR is a possible separately installed dependency; invocation, licensing, package distribution and actual archive-preservation tests remain unverified here.
- Android: the [official RAR application](https://play.google.com/store/apps/details?id=com.rarlab.rar) can create archives. That does not establish an embeddable library or an unattended integration contract for this application.
- iOS: this investigation has not established a supported native RAR writer or permitted distribution route. Do not advertise writing support.

## Conditions for a future Adapter

Establish a permitted distribution/invocation route for each platform. Verify actual RAR4/RAR5 and CBR root ComicInfo creation/update against real fixtures, preserving every page/member byte and natural reading order. Classify solid, multipart, encrypted, signed and damaged archives explicitly. Reuse the Resource metadata embedding transaction/outbox, staging/recovery and observation rules. A tool's absence or unsupported input must remain an honest unsupported/error state, never success.
