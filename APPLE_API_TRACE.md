# Apple Core Video API Trace

## Baseline

- Review date: 2026-07-25
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

## Responsibility trace

| Apple family | Header evidence | Open implementation | Status | Required evidence |
|---|---|---|---|---|
| `CVBuffer` attachments | `CVBuffer.h` | `CVBuffer`, `CVAttachmentMode`, typed and zero-copy binary attachment storage and propagation operations | Implemented | Portable behavior and Apple differential tests |
| `CVImageBuffer` | `CVImageBuffer.h` | Dimensions and attachment-bearing image-buffer protocol | Partial | Image metadata and clean-aperture conformance |
| `CVPixelBuffer` packed storage | `CVPixelBuffer.h` | Owned/external leases, layout validation, scoped read/write access | Implemented | Address identity, release, and failure tests |
| `CVPixelBuffer` planar storage | `CVPixelBuffer.h` | Independent-plane and single-owner planar leases | Implemented | Plane identity, overlap, lifetime, and lock tests |
| Pixel format descriptions | `CVPixelFormatDescription.h` | Four-character identifiers and selected camera formats | Partial | Registry and format-description behavior |
| Pixel buffer pools | `CVPixelBufferPool.h` | Generic `CVPixelBufferPool`, allocator, pooled storage, threshold and flush operations | Partial | Allocation-threshold/reuse Apple differential and portable flush tests |
| IOSurface-backed buffers | `CVPixelBufferIOSurface.h` | `CVPackedPlatformStorageLease` / `CVPlanarPlatformStorageLease` boundary | Adapter | Apple adapter conformance |
| Metal buffers and textures | `CVMetalBuffer*.h`, `CVMetalTexture*.h` | Stable identity and scoped native-handle lease contract | Adapter | Cache lifetime and zero-copy projection tests |
| Display timing | `CVDisplayLink.h`, `CVHostTime.h` | No declaration | Planned | Injected-clock and callback-order tests |
| OpenGL families | `CVOpenGL*.h` | No declaration | Adapter | Separate legacy adapter decision |
| Result codes | `CVReturn.h` | Typed `CVPixelBufferError` categories | Partial | Status translation at compatibility boundaries |

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
allocators, returned buffers, and `CVPixelBufferError`. Apple free-buffer
notifications and status-code translation belong to an ABI adapter.
