# Apple Core Video API Trace

## Baseline

- Review date: 2026-07-27
- SDK: macOS 27.0 from the active Xcode beta
- Documentation: Apple Developer Documentation read with `remark`
- Local evidence: `CoreVideo.framework/Headers`, the SDK symbol graph, package
  source, and behavior tests

Statuses mean:

- **Implemented**: a real production path and behavior tests exist.
- **Partial**: a useful subset exists and every callable limitation is explicit.
- **Planned**: the Apple family has been identified but is not implemented.
- **Adapter**: the semantic contract belongs here, while native API imports
  belong in another package.
- **Omitted**: the SDK family is deprecated and is intentionally not added.

## Responsibility trace

| Apple family | Header evidence | Open implementation | Status | Required evidence |
|---|---|---|---|---|
| `CVBuffer` attachments | `CVBuffer.h` | `CVBuffer`, `CVAttachmentMode`, typed and zero-copy binary attachment storage and propagation operations | Implemented | Portable behavior and Apple differential tests |
| `CVImageBuffer` | `CVImageBuffer.h` | Encoded size, clean rect, display size, pixel aspect, and origin over attachment-bearing buffers | Implemented | Portable behavior and Apple geometry differential tests |
| `CVPixelBuffer` packed storage | `CVPixelBuffer.h` | Owned/external leases, layout validation, scoped read/write access | Implemented | Address identity, release, and failure tests |
| `CVPixelBuffer` planar storage | `CVPixelBuffer.h` | Independent-plane and single-owner planar leases | Implemented | Plane identity, overlap, lifetime, and lock tests |
| Pixel format descriptions | `CVPixelFormatDescription.h` | Race-safe registry plus 74 RGB, component, depth/disparity, planar YCbCr, block-packed YCbCr, Bayer, and sensel descriptions | Partial | Palette-dependent indexed formats and compressed-codec capability contracts |
| Pixel buffer pools | `CVPixelBufferPool.h` | Generic pool, allocation/reuse/flush, bounded broadcast availability streams, subscriber termination, and shutdown | Implemented | Portable behavior and Apple threshold differential tests |
| IOSurface-backed buffers | `CVPixelBufferIOSurface.h` | `CVPackedPlatformStorageLease` / `CVPlanarPlatformStorageLease` boundary | Adapter | Apple adapter conformance |
| Metal buffers and textures | `CVMetalBuffer*.h`, `CVMetalTexture*.h` | Stable identity and scoped native-handle lease contract | Adapter | Cache lifetime and zero-copy projection tests |
| Host time | `CVHostTime.h` | `CVHostClock`, a freeze-on-first-use `CVHostClockProvider`, and the three non-deprecated `CVGet*Host*` operations | Implemented | Native contract tests plus regular and Embedded WASM runtime tests |
| Display link | `CVDisplayLink.h` | No declaration | Omitted | The entire header is deprecated as of macOS 15; deprecated APIs are outside the package contract |
| OpenGL families | `CVOpenGL*.h` | No declaration | Adapter | Separate legacy adapter decision |
| Result codes | `CVReturn.h` | Complete constant range plus exhaustive `CVPixelBufferError` translation at the ABI boundary | Implemented | Constant and category-mapping behavior tests |

## Current compatibility boundary

The portable package owns buffer semantics and never imports Metal, OpenGL,
IOSurface, or a camera SDK. A platform package may retain those native owners and
lend their storage through the same scoped lease contract.

The attachment implementation copies only the small key-entry map during a
filtered snapshot or propagation operation. It does not access or copy pixel
storage. Binary values retain a `CVBinaryAttachment` owner and lend its original
bytes through `Span`; propagation retains that same owner.

The portable pool replaces Core Foundation attribute dictionaries, allocator
arguments, out parameters, and `CVReturn` with typed configuration, generic
allocators, returned buffers, and `CVPixelBufferError`.
The portable availability stream preserves the free-buffer notification
semantics without Foundation; an Apple NotificationCenter bridge and
status-code translation belong to an ABI adapter.

The portable host-time operations use a process-relative nanosecond timebase on
native and regular WASM. Generic Embedded deployments install a platform
`CVHostClock` before first use because the pinned Swift 6.4 Embedded standard
library does not provide `ContinuousClock`. Missing configuration is a typed
`CVHostClockError`; the Apple-compatible nonthrowing operations enforce that
precondition instead of returning a fabricated time.
