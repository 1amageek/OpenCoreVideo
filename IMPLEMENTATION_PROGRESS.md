# OpenCoreVideo Implementation Progress

## Smoke definition

The first Smoke milestone is complete when a packed pixel buffer:

- owns real writable memory;
- exposes validated dimensions, pixel format, bytes per row, and byte count;
- provides scoped zero-copy read and write access;
- reports invalid dimensions, layout, storage size, and access mode as typed
  errors;
- balances storage lock and unlock operations and recovers after lock failure;
- invokes an external-memory release handler exactly once;
- builds for native Swift, WASM, and Embedded Swift.

An import-only test is not Smoke evidence.

The second Smoke milestone is complete when a planar pixel buffer:

- reports its plane count and each plane's dimensions and row stride;
- retains independent owned or external plane storage leases;
- exposes the original plane address only through scoped `Span` access;
- rejects invalid indexes, layout overflow, insufficient storage, address-range
  overflow, overlapping plane memory, and conflicting access as typed errors;
- invokes each external plane release handler exactly once;
- keeps the first packed-buffer Smoke behavior unchanged;
- builds for native Swift, WASM, and Embedded Swift.

The shared planar lease milestone is complete when:

- one storage lease exposes all planes without per-plane storage owners;
- the generic pixel buffer validates plane count and capacity against its layout;
- all plane pointers remain scoped and preserve the source address;
- read/write exclusion applies across the whole buffer;
- backend access failure releases the pixel buffer's access state;
- one platform owner remains alive until the pixel buffer releases its lease;
- native, WASM, and Embedded builds remain successful.

## Apple API inventory

The following Apple APIs were read with `remark` on 2026-07-24:

| Apple API | Reviewed behavior | Portable contract |
|---|---|---|
| `CVPixelBuffer` | Image buffer backed by main-memory pixel storage | `CVPixelBuffer` protocol |
| `CVPixelBufferCreateWithBytes` | Width, height, four-character format, base address, row bytes, release callback | `CVExternalPixelBufferStorage` plus `CVPackedPixelBuffer` |
| `CVPixelBufferLockBaseAddress` | CPU access requires a lock; read-only flag must match unlock | `CVPixelBufferAccessCoordinator.lock(_:)` |
| `CVPixelBufferUnlockBaseAddress` | Ends CPU access with the matching access mode | `CVPixelBufferAccessCoordinator.unlock(_:)` |
| `CVPixelBufferGetWidth` / `GetHeight` | Returns immutable pixel dimensions | `CVImageBuffer.dimensions` |
| `CVPixelBufferGetBytesPerRow` | Returns row stride in bytes | `CVPixelBuffer.bytesPerRow` |
| `CVPixelBufferLockFlags.readOnly` | Distinguishes read-only CPU access | `CVPixelBufferAccessMode.read` |
| `CVPixelBufferCreateWithPlanarBytes` | Creates a planar buffer over caller-provided plane addresses | Throwing `CVPlanarPixelBuffer` external-memory initializer |
| `CVPixelBufferGetPlaneCount` | Returns zero for packed buffers and the plane count for planar buffers | Generic wrapper with the same name plus `CVPixelBuffer.planeCount` |
| `CVPixelBufferGetWidthOfPlane` / `GetHeightOfPlane` | Returns per-plane dimensions | Generic wrappers plus `dimensionsOfPlane(at:)` |
| `CVPixelBufferGetBytesPerRowOfPlane` | Returns per-plane row stride | Generic wrapper plus `bytesPerRowOfPlane(at:)` |
| `CVPixelBufferGetBaseAddressOfPlane` | Returns a plane pointer while the buffer is locked | Not exposed directly; scoped `withReadBytes(ofPlane:_:)` and `withWriteBytes(ofPlane:_:)` prevent pointer escape |

The portable API intentionally uses protocols and typed errors instead of Core
Foundation references and `CVReturn` status codes. This signature difference is
required for WASM and Embedded Swift and remains subject to Apple conformance
fixtures.

The planar declarations were verified against
`CoreVideo.framework/Headers/CVPixelBuffer.h` and a `CoreVideo` symbol graph from
the installed MacOSX 27.0 SDK. The portable external-memory initializer has one
release callback per independent plane lease rather than Apple's one aggregate
callback. This preserves deterministic ownership without requiring Core
Foundation's descriptor-block ABI.

## Zero-copy budget

| Path | Allowed copies | Evidence |
|---|---:|---|
| Owned storage write then read | 0 | Both scopes borrow the owned allocation |
| External storage write then read | 0 | Both scopes expose the original base address |
| Pixel buffer to Core Media | 0 | Core Media retains the buffer (`any CVPixelBuffer` outside Embedded; a generic buffer in Embedded) and borrows `Span` |
| Owned planar plane access | 0 | Each scope borrows its plane allocation |
| External planar plane access | 0 | Each scope exposes the original caller-provided plane address |
| Shared planar lease access | 0 | Every plane scope borrows from one retained platform owner |
| Planar metadata construction | Small metadata only | Layout values and storage references may be stored in arrays; plane bytes are never materialized |
| Attachment lookup | Not a pixel-byte path | Typed metadata is stored independently |
| Attachment snapshot / mutation | Small metadata only | Entry arrays use COW snapshots and generation-checked replacement; pixel and binary payload owners are retained, not copied |

`withReadBytes` and `withWriteBytes` are the normal pixel-data boundaries. They
must not materialize `Array`, `Data`, or another storage object. `Span` and
`MutableSpan` prevent the borrowed byte view from escaping its owner lease.

No copy operation is implemented in the Smoke milestone. A future format
conversion or persistent byte export must use an explicitly copy-named API and
document why ownership cannot be retained across that boundary.

Binary attachment values use `CVBinaryAttachment`. It retains the original byte
owner, lends a `Span` in a scoped callback, and is shared by attachment
propagation. No `[UInt8]` materialization occurs.

The public concurrency marker requires `Sendable`, and `CVStateLock` uses
`Synchronization.Mutex` on native Swift, WASM, and Embedded Swift. Generic
concrete buffer and storage composition still avoids existential dispatch on
Embedded.

## Required implementation

- [x] Pixel dimensions with positive-value validation
- [x] Four-character pixel format value
- [x] Packed layout with overflow and row-stride validation
- [x] Typed buffer, access, and platform-storage errors
- [x] Storage extension protocol
- [x] Owned in-memory storage
- [x] External-memory storage with exactly-once release
- [x] Scoped `Span` / `MutableSpan` access
- [x] Read/write capability enforcement
- [x] Balanced access coordination and recovery after lock failure
- [x] Typed attachment storage
- [x] Attachment propagation modes and Apple-shaped operations
- [x] Attachment replacement and propagation differential test
- [x] `CVImageBuffer` and `CVPixelBuffer` protocols
- [x] Packed pixel-buffer implementation
- [x] Planar layout and per-plane access
- [x] Apple-named generic plane metadata wrappers
- [x] Owned and external per-plane storage leases
- [x] Address overflow and overlap validation
- [x] Buffer-wide access conflict enforcement
- [x] Single-owner `CVPlanarStorageLease` contract
- [x] Generic `CVLeasedPlanarPixelBuffer`
- [x] Shared-lease plane count and capacity validation
- [x] Backend failure access-state recovery
- [x] Single shared-owner lifetime verification
- [x] Behavior Smoke tests
- [x] Buffer pools, storage reuse, allocation thresholds, and flush behavior
- [x] Broader Apple Core Video conformance fixtures
- [x] Generic packed and planar platform storage integration contracts
- [x] Zero-copy binary attachment storage
- [x] Recursive array and dictionary attachment values
- [x] Embedded downstream attachment-witness linkage
- [x] Regular-WASM attachment state runtime verification
- [x] Concurrent attachment update verification

## Progress

| Stage | Status |
|---|---|
| API inventory for Smoke declarations | Complete |
| Packed layout and format contracts | Complete |
| Reference memory storage | Complete |
| Image and pixel-buffer contracts | Complete |
| Attachment storage | Complete |
| Attachment propagation | Complete |
| Apple attachment differential fixture | Complete |
| Native behavior Smoke | Complete |
| WASM build | Complete |
| Embedded Swift build | Complete |
| Planar behavior Smoke | Complete |
| Shared planar lease Smoke | Complete |
| Packed pixel buffer pool | Complete |
| Pool threshold and flush behavior | Complete |
| Platform native-storage contract | Complete |
| Zero-copy binary attachment | Complete |
| Packed, planar, and pool Apple differential fixtures | Complete |
| Embedded cross-module generic construction | Complete |
| Regular-WASM attachment runtime | Complete in debug and release configurations |

## Test evidence

Verified on 2026-07-25:

| Verification | Evidence |
|---|---|
| Native behavior | `xcodebuild test` with the Swift 6.4 snapshot `SWIFT_EXEC` passed 39 tests in 9 suites |
| Thread Sanitizer | The same 39-test native suite passed with `-enableThreadSanitizer YES` |
| Swift 6.4 snapshot compile | `swift build --build-tests` passed |
| WASM | Swift 6.4 snapshot build with `swift-6.4.x-DEVELOPMENT-SNAPSHOT-2026-07-17-a_wasm` passed |
| Embedded Swift | Swift 6.4 snapshot build with `swift-6.4.x-DEVELOPMENT-SNAPSHOT-2026-07-17-a_wasm-embedded` passed |
| Embedded downstream runtime | OpenCoreMedia constructed `CVPackedPixelBuffer` through the public constrained initializer, linked the OpenCoreVideo attachment witness, and completed its WASI Smoke executable |
| Regular-WASM attachment runtime | `OpenCoreVideoRuntimeSmoke` completed attachment init, set, lookup, replacement, batch set, filtered dictionary materialization, single removal, and remove-all |
| Embedded-WASM attachment runtime | The same executable completed with the Embedded SDK and explicit `libswiftUnicodeDataTables.a` linkage |

Debug and release runtime Smokes pass on regular WASM and Embedded WASM. The
pinned regular-WASI optimizer miscompiles allocation of the exact public
attachment dictionary specialization. The library confines
`@_optimize(none)` to its private dictionary-materialization helper, and the
Smoke confines it to input-fixture construction; attachment search, mutation,
and pixel paths remain optimized. This is separate from the fixed `_Cell` and
`Dictionary.Iterator` traps inside the prior OpenCoreVideo implementation.

The behavior suite verifies:

- owned packed storage metadata, byte round-trip, and stable storage identity;
- typed failures for invalid dimensions and row layout;
- typed failure for unsupported write access;
- identical external base addresses in read and write scopes;
- lock/unlock ordering and recovery after backend lock failure;
- exactly-once external release.
- attachment set, lookup, and removal independent of pixel bytes.
- attachment mode replacement, filtered snapshots, batch mutation, and removal;
- concurrent distinct-key mutation without lost updates;
- propagation of only `shouldPropagate` metadata without touching pixel bytes;
- attachment replacement and propagation parity with Apple Core Video;
- owned planar layout, metadata wrappers, stable address, and byte round-trip;
- external planar address identity and exactly-once release for every plane;
- layout multiplication overflow and oversized-plane rejection;
- insufficient plane storage and invalid plane-index rejection;
- external address range overflow and overlap rejection;
- buffer-wide read/write conflicts across different planes;
- packed `CVPixelBufferGetPlaneCount` compatibility returning zero.
- shared planar planes borrowing different offsets from one allocation;
- one lease retained by the pixel buffer and released exactly once;
- shared-lease plane count and capacity validation;
- buffer-wide access exclusion and recovery after backend access failure;
- read-only shared storage rejecting writes before backend access.
- packed-pool storage reuse without byte copies or attachment reuse;
- allocation threshold parity with Apple, including reuse at the threshold;
- allocation reservation rollback and undersized-storage rejection;
- age flush honoring minimum count and excess flush overriding it;
- packed and planar platform storage identities and scoped native handles;
- zero-copy binary attachment address identity, propagation, and exactly-once
  release;
- packed dimensions, format, stride, and scoped mutation parity with Apple;
- bi-planar plane count, dimensions, and row-stride parity with Apple.

## Not implemented

Concrete aggregate Core Foundation adapters, format conversion, browser video
frames, DMA-BUF/NvBufSurface implementations, V4L2 mappings, CUDA
interoperability, Apple free-buffer notifications, and Apple status-code
wrappers remain integration- or ABI-layer work. Their common packed, planar,
native-handle, pool-allocation, and binary-attachment contracts are complete.
Unsupported capabilities must continue to fail explicitly; no placeholder
buffer or silent copy is provided.
