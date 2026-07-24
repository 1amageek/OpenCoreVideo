# OpenCoreVideo Design

## Status

This document is the normative design for the package. The package has completed
the **packed, independent-plane, and shared planar lease Smoke stages**.
Validated layouts, owned and external storage, scoped zero-copy CPU access,
typed attachments, range and overlap validation, and exactly-once external
release are implemented. Pools and Apple runtime conformance fixtures remain
pending.

## Apple API review

The initial responsibility split was derived from Apple's public documentation,
read with `remark` on 2026-07-24:

- [Core Video](https://developer.apple.com/documentation/corevideo)
- [CVBuffer](https://developer.apple.com/documentation/corevideo/cvbuffer)
- [CVImageBuffer](https://developer.apple.com/documentation/corevideo/cvimagebuffer)
- [CVPixelBuffer](https://developer.apple.com/documentation/corevideo/cvpixelbuffer)
- [CVPixelBufferPool](https://developer.apple.com/documentation/corevideo/cvpixelbufferpool)
- [CVPixelBufferLockFlags](https://developer.apple.com/documentation/corevideo/cvpixelbufferlockflags)

Apple models a pixel buffer as an image-buffer reference with dimensions, pixel
format, optional planes, attachments, and explicit lock/unlock access. The
storage and lifetime contract belongs here; capture and media timing do not.

The planar API surface was checked on 2026-07-24 against the installed Mac SDK:

- `/Applications/Xcode-beta.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX27.0.sdk/System/Library/Frameworks/CoreVideo.framework/Headers/CVPixelBuffer.h`
- the `CoreVideo` symbol graph produced from that SDK with
  `swift-symbolgraph-extract`;
- `CVPixelBufferCreateWithPlanarBytes`,
  `CVPixelBufferGetPlaneCount`, `CVPixelBufferGetWidthOfPlane`,
  `CVPixelBufferGetHeightOfPlane`, `CVPixelBufferGetBytesPerRowOfPlane`, and
  `CVPixelBufferGetBaseAddressOfPlane`.

The local SDK, rather than recalled signatures, is the compatibility baseline.

## Responsibility

OpenCoreVideo owns:

- image-buffer identity and lifetime;
- pixel dimensions and format identifiers;
- packed and planar memory layout;
- attachments associated with an image buffer;
- explicit CPU access synchronization;
- buffer pools and allocation thresholds;
- storage leases that may represent host memory, shared memory, DMA memory,
  browser video frames, GPU resources, or opaque native handles;
- zero-copy handoff contracts between media producers and consumers.

OpenCoreVideo does not own:

- media timestamps, durations, or sample ordering;
- capture-device discovery or configuration;
- capture graph routing;
- codecs or file containers;
- image recognition, inference, or Manas signal interpretation;
- platform-specific camera APIs.

## Dependency direction

```text
OpenCoreVideo
    └── Swift standard library only

OpenCoreMedia ───────► OpenCoreVideo
OpenAVFoundation ───► OpenCoreVideo
Platform storage ───► OpenCoreVideo storage extension contract
```

OpenCoreVideo must never import OpenCoreMedia or OpenAVFoundation.

## API layers

### Apple-compatible surface

The public compatibility layer will implement the Swift-visible equivalents of:

1. `CVBuffer` and attachment operations;
2. `CVImageBuffer`;
3. `CVPixelBuffer`;
4. pixel-format identifiers and descriptions;
5. base-address and plane access;
6. `CVPixelBufferPool`;
7. creation and release-callback operations.

Apple-named declarations are added only after their Swift signatures have an API
inventory entry and their semantics have a conformance test plan.

Core Foundation and Objective-C types unavailable on WASM or Embedded Swift are
represented by pure-Swift equivalents. Every unavoidable signature difference is
recorded before release; compatibility is never inferred from a matching name.

### Storage extension contract

Concrete memory systems are supplied through a storage contract rather than
subclasses or camera checks. The contract is semantic and must support:

- stable storage identity;
- immutable dimensions, pixel format, and plane layout for a lease;
- explicit readable and writable access capabilities;
- scoped access to a packed buffer or an individual plane;
- optional opaque native handles without exposing their type in the compatibility
  API;
- exactly-once release of externally owned memory;
- attachment storage independent of pixel bytes;
- a typed failure when an access mode is unavailable.

The first storage contracts are:

- `CVPixelBufferStorage` for byte ownership and scoped access;
- `CVPlanarStorageLease` for one platform owner exposing multiple planes;
- `CVPixelBufferAccessCoordinator` for matching backend lock and unlock calls;
- `CVPackedPixelBuffer<Storage, Attachments>` for validated packed image buffers.
- `CVPlanarPixelBuffer<Storage, Attachments>` for validated per-plane storage
  leases and buffer-wide access exclusion.
- `CVLeasedPlanarPixelBuffer<StorageLease, Attachments>` for a single shared
  storage lease with buffer-wide access exclusion.

Concrete buffer and storage types are generic. This keeps Embedded Swift on
static dispatch while preserving protocol-based extension points.

### Planar compatibility surface

The normal planar sequence deliberately follows Core Video:

1. determine whether a buffer is planar and obtain its plane count;
2. inspect each plane's width, height, and row stride;
3. establish scoped read or write access;
4. borrow the selected plane's original base address only inside that scope.

`CVPixelBufferGetPlaneCount`, `CVPixelBufferGetWidthOfPlane`,
`CVPixelBufferGetHeightOfPlane`, and `CVPixelBufferGetBytesPerRowOfPlane` are
provided as generic top-level wrappers. Instance properties and methods provide
the same information for protocol-oriented code.

Unavoidable differences from Apple's C and Core Foundation ABI are explicit:

- creation uses typed throwing initializers and generic storage leases instead of
  an allocator, `CVReturn`, `CFDictionary`, and an out parameter;
- invalid plane indexes are typed errors instead of zero or null results;
- `CVPixelBufferGetBaseAddressOfPlane` is not reproduced because a returned
  pointer could escape its lock and owner lifetime; `withReadBytes(ofPlane:_:)`
  and `withWriteBytes(ofPlane:_:)` are the safe canonical equivalents;
- external planes use independent leases, and the portable release handler is
  invoked once per plane with its index, address, and byte count; Apple's
  `CVPixelBufferReleasePlanarBytesCallback` is one aggregate callback;
- `CVPlanarStorageLease` is the portable integration point for Apple's aggregate
  planar owner, DMA-BUF, `NvBufSurface`, and similar single-owner resources. It
  exposes planes through scoped borrows without requiring a storage array or
  per-plane owner wrapper. Concrete platform adapters remain outside this
  package.

### Shared platform planar storage

```text
One platform owner
    │ retained once
    ▼
CVPlanarStorageLease
    ├── scoped plane 0 borrow
    ├── scoped plane 1 borrow
    └── scoped plane n borrow
             │
             ▼
CVLeasedPlanarPixelBuffer
```

The storage lease reports a stable plane count, per-plane byte capacity, and
buffer-wide access capabilities. It must keep its platform owner alive until the
lease is released, balance every successful backend lock with an unlock, and
lend a plane pointer only for the duration of the supplied closure.

`CVLeasedPlanarPixelBuffer` validates the lease against
`CVPlanarPixelBufferLayout` and enforces read/write exclusion across all planes.
It releases its own access state even when the backend rejects an access. The
lease owns platform lock behavior and the buffer owns layout and cross-plane
coordination; neither duplicates the other's responsibility.

## Ownership and zero-copy contract

```text
Storage owner
    │ retains
    ▼
Pixel-buffer lease
    │ lends within a scoped closure
    ├── packed byte view
    ├── plane 0 view
    ├── plane 1 view
    └── opaque native handle
```

Invariants:

1. A pixel buffer owns or retains exactly one storage lease.
2. Borrowed byte and plane views never escape the access scope.
3. A native handle never outlives its storage lease.
4. Lock and unlock operations are balanced, including failure paths.
5. Read-only access cannot become writable through a cast.
6. External release handlers execute exactly once.
7. A format conversion is an explicit operation and may allocate; ordinary
   routing does not convert or copy.
8. No API silently materializes a large `Array` or `Data` value.
9. A planar buffer copies only its small layout and lease-reference arrays; it
   never copies plane bytes.
10. External plane address ranges must not overflow or overlap.
11. A shared planar buffer retains one storage lease and does not construct a
    storage array or per-plane owner wrappers.
12. Shared-lease access capabilities and plane capacities are immutable for the
    lifetime of the buffer.

Short synchronous access state is protected through `CVStateLock`. Native Swift
and WASM use `Mutex`; no `await` occurs while holding it. Embedded Swift has no
`Mutex` in its standard-library profile, so its implementation is explicitly
owner-isolated and non-`Sendable`. Embedded composition uses generic concrete
types and must not share a buffer concurrently.

The lock protects only lease state. Backend access coordination and the caller's
pixel-byte closure execute after the state lock is released.

## Platform model

| Platform | Intended storage implementations | Shared API behavior |
|---|---|---|
| Browser WASM | `VideoFrame`, WebGPU texture, WASM linear memory | Same buffer, plane, attachment, and pool contracts |
| Non-browser WASM | WASM linear memory or host-provided imports | Unsupported native access returns a typed failure |
| Embedded Swift | statically allocated memory, DMA buffers, vendor handles | Deterministic lifetime; no dynamic runtime requirement |
| Linux/Jetson driver | `NvBufSurface`, DMA-BUF, V4L2 `mmap`, CUDA interop | Exposed only through storage contracts |
| Apple test host | pure-Swift reference storage | Used for conformance comparison, not production |

JavaScriptKit, WebGPU, CUDA, libargus, V4L2, and vendor SDKs must live in separate
integration targets or packages.

## Error contract

Unsupported access, invalid plane indexes, incompatible layouts, exhausted pools,
allocation threshold violations, and ownership violations are typed failures.
They must not return empty storage, zero dimensions, or a placeholder handle as a
successful value.

Apple-compatible status-code APIs translate internal typed failures at the API
boundary without discarding the underlying category used by tests and diagnostics.

## Implementation sequence

1. [Complete] Record the initial Apple API inventory and signature sources.
2. [Complete] Implement pixel-format identifiers and immutable packed layout.
3. [Complete] Implement owned and external in-memory storage leases.
4. [Complete] Implement typed attachment and lifetime behavior.
5. [Complete] Implement `CVImageBuffer` and `CVPixelBuffer` access semantics.
6. [Complete] Implement packed and planar behavior fixtures.
7. [Complete] Implement the single-owner shared planar storage contract.
8. [Pending] Implement pool allocation and thresholds.
9. [Pending] Add browser, replay, and embedded storage integrations as separate
   modules.
10. [Pending] Add external conformance tests against Apple Core Video.

Each stage requires native conformance tests plus WASM and Embedded builds. A
stage is not complete from declaration presence or module import tests alone.
