# OpenCoreVideo Design

## Status

This document is the normative design for the package. The package has completed
the **packed, independent-plane, and shared planar lease Smoke stages**.
Validated layouts, owned and external storage, scoped zero-copy CPU access,
typed and binary attachments, range and overlap validation, exactly-once
external release, recyclable packed-buffer pools, and Apple runtime
conformance fixtures are implemented. Clean-aperture, display-size, pixel-aspect,
and origin geometry plus the Swift 6.4 pixel-format description registry are
also implemented. The non-deprecated Core Video host-time operations use a
fixed, race-safe clock provider. Platform-native concrete adapters remain in
their integration packages.

## Apple API review

The initial responsibility split was derived from Apple's public documentation,
read with `remark` on 2026-07-24:

- [Core Video](https://developer.apple.com/documentation/corevideo)
- [CVBuffer](https://developer.apple.com/documentation/corevideo/cvbuffer)
- [CVImageBuffer](https://developer.apple.com/documentation/corevideo/cvimagebuffer)
- [CVPixelBuffer](https://developer.apple.com/documentation/corevideo/cvpixelbuffer)
- [CVPixelBufferPool](https://developer.apple.com/documentation/corevideo/cvpixelbufferpool)
- [CVPixelBufferLockFlags](https://developer.apple.com/documentation/corevideo/cvpixelbufferlockflags)
- [kCVPixelBufferPoolAllocationThresholdKey](https://developer.apple.com/documentation/corevideo/kcvpixelbufferpoolallocationthresholdkey)
- [kCVPixelBufferPoolMinimumBufferCountKey](https://developer.apple.com/documentation/corevideo/kcvpixelbufferpoolminimumbuffercountkey)
- [kCVPixelBufferPoolMaximumBufferAgeKey](https://developer.apple.com/documentation/corevideo/kcvpixelbufferpoolmaximumbufferagekey)
- [CVPixelBufferPoolFlush](https://developer.apple.com/documentation/corevideo/cvpixelbufferpoolflush(_:_:))
- [CVGetCurrentHostTime](https://developer.apple.com/documentation/corevideo/cvgetcurrenthosttime())
- [CVGetHostClockFrequency](https://developer.apple.com/documentation/corevideo/cvgethostclockfrequency())
- [CVGetHostClockMinimumTimeDelta](https://developer.apple.com/documentation/corevideo/cvgethostclockminimumtimedelta())

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

The pool API surface was rechecked on 2026-07-25 against
`CVPixelBufferPool.h` and the documentation above. In particular, an allocation
threshold prevents only new allocations and does not prevent an already
allocated buffer from being recycled.
`CVPixelBufferPoolFlushFlags.RawValue` follows `CVOptionFlags` as `UInt64`.

The Swift 6.4 image-geometry and pixel-format description surfaces were
rechecked on 2026-07-27 against the MacOSX 27.0 symbol graph,
`CVImageBuffer.h`, `CVPixelBuffer.h`, `CVPixelFormatDescription.h`, and Apple
runtime differential fixtures.

The three active `CVHostTime.h` operations were reviewed with `remark` on
2026-07-27. `CVDisplayLink.h` was also checked in the installed SDK; the entire
family is deprecated as of macOS 15 and is intentionally omitted.

## Responsibility

OpenCoreVideo owns:

- image-buffer identity and lifetime;
- pixel dimensions and format identifiers;
- packed and planar memory layout;
- attachments associated with an image buffer;
- explicit CPU access synchronization;
- buffer pools and allocation thresholds;
- a monotonic host-time source and its frequency contract;
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
7. creation and release-callback operations;
8. non-deprecated host-time operations.

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
- `CVNativePixelBufferStorage` for stable platform storage identity and scoped
  access to an adapter-defined native handle.
- `CVPackedPlatformStorageLease` and `CVPlanarPlatformStorageLease` for
  platform-backed packed and single-owner planar resources.

Concrete buffer and storage types are generic. This keeps Embedded Swift on
static dispatch while preserving protocol-based extension points.

`CVBufferAttachments` is the public concrete attachment type used by the
default packed and planar buffer initializers. It exports its interface so an
Embedded downstream module can specialize those generic buffers while linking
the `CVBufferAttachmentStorage` witness from OpenCoreVideo. This is a metadata
linkage requirement only; attachment values and pixel storage retain their
existing owners and are not materialized or copied.

The attachment owner stores an ordered array of key/value entries inside a
nominal `State` protected by `CVStateLock`. Reads take a copy-on-write snapshot
under the lock and search or materialize the public dictionary after releasing
it. Mutations build a replacement array outside the lock, then commit it only
when the captured generation still matches; a concurrent mutation causes a
retry. Consequently, allocation, property-list construction, and public
dictionary materialization do not execute while the mutex is held.

This internal representation also avoids two Swift 6.4 snapshot regular-WASI
runtime defects observed with the exact
`swift-6.4.x-DEVELOPMENT-SNAPSHOT-2026-07-17-a` baseline: storing
`Dictionary<CVAttachmentKey, CVBufferAttachment>` directly in
`Mutex` traps while initializing `_Cell`, and that dictionary's iterator traps
while advancing. Batch input therefore uses index traversal, and public
snapshots use `Dictionary(uniqueKeysWithValues:)`. These workarounds do not
change the Apple-shaped dictionary API. The exact pinned optimizer also
miscompiles allocation of this public dictionary specialization. Only the
private metadata-materialization helper is compiled with
`@_optimize(none)`; attachment search, mutation, and all pixel-data paths remain
optimized. The runtime Smoke input constructor uses the same narrow boundary
because that allocation otherwise traps before the library call begins.

### Image geometry

`CVImageBufferGetEncodedSize`, `CVImageBufferGetCleanRect`,
`CVImageBufferGetDisplaySize`, and `CVImageBufferIsFlipped` derive their values
from immutable dimensions, origin position, and typed attachments. Clean
aperture is centered in encoded coordinates before applying horizontal and
vertical offsets. Pixel aspect ratio adjusts the clean width, and explicit
display dimensions take precedence.

The shared target cannot expose CoreGraphics `CGSize` or `CGRect` without
violating its standard-library-only contract. `CVImageSize`,
`CVImageFloatSize`, and `CVImageRect` are the portable returned values. Unlike
Apple's nonthrowing C getters, attachment-dependent getters throw
`CVPixelBufferError` for malformed or impossible metadata instead of silently
returning invented geometry.

### Pixel-format descriptions

`CVPixelFormatDescription` models components, component range, compatibility,
packed or planar configuration, block size, bit depth, subsampling, and black
values without Foundation or CoreGraphics. `Registry` stores immutable
descriptions behind `CVStateLock`, replaces registrations atomically by format
identifier, and returns coherent snapshots. Known standard formats are checked
against buffer layouts so their FourCC and memory layout cannot disagree.

The current built-in inventory covers 44 byte-aligned formats: common packed
RGB and grayscale layouts, integer and floating-point component layouts,
depth/disparity scalars, 8/10/16-bit bi-planar YCbCr at 4:2:0, 4:2:2, and
4:4:4, and alpha-bearing bi/tri-planar layouts. Odd-dimension subsampling and
stored component widths are validated against the concrete plane layout.
Indexed, fractional block-packed, Bayer/sensel, and compressed Apple formats
require a separate block-layout or codec contract and remain tracked in
`APPLE_API_TRACE.md`; custom formats can be validated and registered without
placeholder descriptions.

### Pixel buffer pools

```text
CVPixelBufferPoolAllocator
          │ allocates only on cache miss
          ▼
CVPixelBufferPoolCore
    ├── checked-out storage ──► CVPooledPixelBufferStorage
    └── available storage ◄──── buffer release
                                 └──► availability subscribers
```

`CVPixelBufferPool` caches storage leases, not pixel-buffer objects. Each
checkout constructs a new attachment-free buffer and each released wrapper
returns its storage to the pool. This prevents attachments from leaking between
frames while retaining the large pixel allocation without copying.

Allocation count reservations occur under `CVStateLock`; allocation itself
occurs after the lock is released. A failed or undersized allocation rolls the
reservation back. Per-request thresholds reject only a required new allocation;
an available lease is reused first. Age-based flush uses an injected
nanosecond timestamp source, and `excessBuffers` removes every unused lease
regardless of minimum count or age. The timestamp callback, allocator, release,
and byte-access callbacks never execute while the pool mutex is held.
The owned allocator creates a fresh access coordinator for each newly allocated
storage lease so backend lock state is never shared accidentally across buffers.

Passing an allocation threshold enables portable free-buffer notifications.
Each subscriber receives a bounded `AsyncStream` whose newest availability
event replaces an unconsumed duplicate; a stalled subscriber therefore cannot
grow memory without bound. Storage is committed to the available cache before
continuations are copied under `CVStateLock`, and `yield` executes after both
pool and subscriber locks are released. `shutdown()` rejects new checkouts,
releases cached storage, and finishes every subscriber. It is idempotent and is
also invoked when the pool is destroyed.

The pure-Swift configuration replaces Apple's Core Foundation dictionaries,
allocator argument, out parameter, and status code with typed values, a returned
buffer, and `CVPixelBufferError`. Unlike Apple's implicit one-second default
age, the portable default does not age cached buffers because the shared target
does not bind pool policy to the global host clock. Age eviction becomes active
only when the caller supplies both `maximumBufferAgeNanoseconds` and a
monotonic timestamp provider.

### Host time

```text
Platform monotonic clock
          │ install before first use on Embedded
          ▼
CVHostClockProvider.system
          │ Mutex<State>
          ├── configurable(clock?)
          └── active(clock) ──► CVGetCurrentHostTime
                                CVGetHostClockFrequency
                                CVGetHostClockMinimumTimeDelta
```

`CVHostClockProvider` protects one state representation with
`Synchronization.Mutex` on native, regular WASM, and Embedded Swift. The first
successful read freezes the provider, so the tick source, frequency, and
minimum delta cannot be replaced independently while clients are converting
time. Installation after activation and reading before configuration are typed
failures. Clock callbacks execute after the mutex is released.

Native and regular WASM use `ContinuousClock` and expose process-relative
nanosecond ticks with a frequency of `1_000_000_000` and a minimum represented
delta of one tick. This timebase supports elapsed-time conversion but is not
claimed to share Apple's Core Audio host-time epoch. The pinned Swift 6.4
Embedded module marks `ContinuousClock` unavailable, so a board or platform
package must install its monotonic `CVHostClock` before first use. The
Apple-compatible nonthrowing functions enforce missing configuration as a
precondition rather than silently returning zero.

| Target | Storage type | Isolation | Read entry point | Mutation entry point | Shutdown / owner release |
|---|---|---|---|---|---|
| Native | `Mutex<CVHostClockProvider.State>` | `Mutex` | `current()` | `install(_:)` before activation | Process-lifetime system provider retains the active clock |
| Regular WASM | `Mutex<CVHostClockProvider.State>` | `Mutex` | `current()` | `install(_:)` before activation | Process-lifetime system provider retains the active clock |
| Embedded WASM | `Mutex<CVHostClockProvider.State>` | `Mutex` | `current()` | Required `install(_:)` before activation | Process-lifetime system provider retains the injected clock |

The target difference is only the availability of a default clock. Storage,
isolation, `Sendable` conformance, and lifecycle transitions are identical.

### Binary attachments

`CVBinaryAttachment` retains caller-provided byte storage and exposes it only
through a scoped `Span`. Attachment lookup and propagation copy the small map
entry and retain the same binary owner; they never materialize `[UInt8]` or
duplicate the payload. Binary equality is storage identity equality, avoiding a
hidden byte scan on the capture path.

`CVAttachmentValue.array` and `.dictionary` preserve recursive Core Foundation
property-list metadata at platform bridge boundaries. Containers own their
small metadata structure; pixel payloads and binary attachment payloads remain
separate owner-backed values.

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
13. Pool checkout and return never copy or clear pixel bytes implicitly.
14. Allocation-threshold accounting includes checked-out and cached storage and
    rolls back every failed reservation.
15. Binary attachment propagation retains the original owner and does not copy
    its bytes.
16. Platform native handles are lent only inside the adapter's scoped callback.

Short synchronous access state is protected through `CVStateLock`, which uses
`Synchronization.Mutex` on native Swift, WASM, and Embedded Swift. No `await`,
allocator, timestamp provider, backend callback, byte-access closure, or release
handler executes while the mutex is held.

### Shared-state review matrix

| Logical state | Native | WASM | Embedded | Read / mutation entry points | Release |
|---|---|---|---|---|---|
| Buffer attachments | `CVStateLock` / `Mutex<State>` | `CVStateLock` / `Mutex<State>` | `CVStateLock` / `Mutex<State>` | COW snapshot under lock; search/materialize outside; generation-checked replacement under lock | attachment owner |
| External pixel or binary storage | `CVStateLock` / `Mutex<State>` | `CVStateLock` / `Mutex<State>` | `CVStateLock` / `Mutex<State>` | reserve access under lock; byte closure and release handler outside | storage lease, exactly once |
| Pixel-buffer pool | `CVStateLock` / `Mutex<State>` | `CVStateLock` / `Mutex<State>` | `CVStateLock` / `Mutex<State>` | reserve and commit metadata under lock; allocation, stream yield/finish, and callbacks outside | pool, checked-out storage, or explicit shutdown |
| Pixel-format registry | `CVStateLock` / `Mutex<State>` | `CVStateLock` / `Mutex<State>` | `CVStateLock` / `Mutex<State>` | snapshot or atomic replacement under lock; description construction outside | registry |

Recursive attachment containers are immutable values with Swift copy-on-write
backing on every target. An empty `CVBinaryAttachment` has no external storage
owner and lends only a zero-length scoped view; it does not introduce mutable
shared state or a target-specific synchronization branch.

Public concrete types used as generic arguments by Embedded downstream modules
must preserve their conformance metadata in the defining module. A downstream
module must not recreate storage or erase the generic boundary merely to satisfy
linkage.

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
`CVReturnForPixelBufferError` is the only shared status translation boundary;
the implementation remains exhaustive over `CVPixelBufferError` so adding a
new failure category requires an explicit ABI decision.

## Implementation sequence

1. [Complete] Record the initial Apple API inventory and signature sources.
2. [Complete] Implement pixel-format identifiers and immutable packed layout.
3. [Complete] Implement owned and external in-memory storage leases.
4. [Complete] Implement typed attachment and lifetime behavior.
   Attachment modes, filtered copies, batch mutation, and propagation are
   covered by portable behavior tests and an Apple differential fixture.
5. [Complete] Implement `CVImageBuffer` and `CVPixelBuffer` access semantics.
6. [Complete] Implement packed and planar behavior fixtures.
7. [Complete] Implement the single-owner shared planar storage contract.
8. [Complete] Implement pool allocation, recycling, thresholds, and flush
   behavior.
9. [Complete] Define generic packed and planar native-storage integration
   contracts. Browser, replay, embedded, and Jetson concrete adapters remain in
   separate modules.
10. [Complete] Add external conformance tests against Apple Core Video for
    attachments, packed metadata and access, planar metadata, and pool
    allocation-threshold behavior.
11. [Complete] Implement retained zero-copy binary attachment storage.
12. [Complete] Implement image geometry and Apple differential behavior.
13. [Complete] Implement the race-safe format registry and 44 byte-aligned
    standard format descriptions. Block-packed, indexed, Bayer/sensel, and
    compressed format families remain explicitly tracked.
14. [Complete] Implement bounded broadcast free-buffer notifications,
    subscriber termination, idempotent shutdown, and post-shutdown failure.
15. [Complete] Implement the complete `CVReturn` constant range and exhaustive
    pixel-buffer error-to-status translation.
16. [Complete] Implement the active host-time operations with a fixed provider,
    explicit Embedded injection, and regular/Embedded WASM runtime checks.
    Deprecated `CVDisplayLink` declarations are intentionally omitted.

Each stage requires native conformance tests plus WASM and Embedded builds. A
stage is not complete from declaration presence or module import tests alone.
