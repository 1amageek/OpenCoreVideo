# OpenCoreVideo

OpenCoreVideo is a pure-Swift implementation target for the Swift-visible Core
Video API on platforms where Apple's Core Video framework is unavailable.

The packed, independent-plane, and shared planar lease Smoke milestones are
implemented. They include validated pixel and plane layouts, owned and external
memory, a single-owner multi-plane storage contract, scoped zero-copy access,
typed attachments, balanced access coordination, plane range and overlap
validation, and exactly-once external release. Pools, concrete platform
adapters, and Apple runtime conformance fixtures remain pending.

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
swift build
swiftly run swift build --swift-sdk swift-6.3.1-RELEASE_wasm
swiftly run swift build --swift-sdk swift-6.3.1-RELEASE_wasm-embedded
```
