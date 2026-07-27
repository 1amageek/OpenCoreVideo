# OpenCoreVideo

OpenCoreVideo is a pure-Swift implementation target for the Swift-visible Core
Video API on platforms where Apple's Core Video framework is unavailable.

The packed, independent-plane, shared planar lease, and packed-buffer pool
milestones are implemented. They include validated pixel and plane layouts,
owned and external memory, single-owner multi-plane and native-handle storage
contracts, scoped zero-copy access, typed and binary attachments, recyclable
storage with allocation thresholds, balanced access coordination, plane range
and overlap validation, image geometry derived from typed attachments, a
race-safe pixel-format description registry, bounded broadcast pool-availability
notifications with explicit shutdown, and exactly-once external release.
The registry includes 74 RGB, grayscale, floating-point, depth, disparity,
planar YCbCr, block-packed YCbCr, Bayer, and sensel formats with validated
storage semantics. Concrete
platform adapters remain in their platform packages. Apple-compatible
`CVReturn` constants and an exhaustive typed-error mapping are available at ABI
boundaries without replacing typed errors inside the package. The three active
Core Video host-time operations are implemented with a race-safe provider;
Embedded platforms install their monotonic clock before first use, while
missing configuration remains an explicit typed failure.

## Supported production targets

- WebAssembly, including browser-backed and linear-memory buffer implementations
- Embedded Swift, including statically composed DMA and native-buffer providers

Apple-platform builds are used for compatibility and conformance testing. Apps on
Apple platforms should import Apple's `CoreVideo` framework.

## Design

Read [DESIGN.md](DESIGN.md) before adding public API or storage implementations.
Milestone status and test evidence are recorded in
[IMPLEMENTATION_PROGRESS.md](IMPLEMENTATION_PROGRESS.md).
Use [APPLE_API_TRACE.md](APPLE_API_TRACE.md) to distinguish implemented,
partial, adapter-owned, and planned Apple Core Video families.

## Build

```bash
TOOLCHAINS=org.swift.64202607171a xcrun swift build
TOOLCHAINS=org.swift.64202607171a xcrun swift build \
  --swift-sdk swift-6.4.x-DEVELOPMENT-SNAPSHOT-2026-07-17-a_wasm
TOOLCHAINS=org.swift.64202607171a xcrun swift build \
  --swift-sdk swift-6.4.x-DEVELOPMENT-SNAPSHOT-2026-07-17-a_wasm-embedded \
  --target OpenCoreVideo
TOOLCHAINS=org.swift.64202607171a xcrun swift run \
  --swift-sdk swift-6.4.x-DEVELOPMENT-SNAPSHOT-2026-07-17-a_wasm \
  OpenCoreVideoRuntimeSmoke
TOOLCHAINS=org.swift.64202607171a xcrun swift run \
  --swift-sdk swift-6.4.x-DEVELOPMENT-SNAPSHOT-2026-07-17-a_wasm-embedded \
  -Xlinker /absolute/path/to/libswiftUnicodeDataTables.a \
  OpenCoreVideoRuntimeSmoke
```
