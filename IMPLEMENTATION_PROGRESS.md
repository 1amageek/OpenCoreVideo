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

`withReadBytes` and `withWriteBytes` are the normal pixel-data boundaries. They
must not materialize `Array`, `Data`, or another storage object. `Span` and
`MutableSpan` prevent the borrowed byte view from escaping its owner lease.

No copy operation is implemented in the Smoke milestone. A future format
conversion or persistent byte export must use an explicitly copy-named API and
document why ownership cannot be retained across that boundary.

Binary attachment values are intentionally deferred instead of being represented
as `[UInt8]`. Their future contract must retain or borrow a byte-storage lease so
large metadata cannot acquire implicit copy-on-write materialization on the
capture path.

On native Swift and WASM, the public concurrency marker requires `Sendable` and
`CVStateLock` uses `Mutex`. Embedded Swift lacks `Mutex` and existential
dispatch, so it uses owner-isolated state and generic concrete buffer/storage
composition. Embedded buffers are intentionally not `Sendable` and must remain
inside one owner.

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
- [ ] Buffer pools and allocation thresholds
- [ ] Broader Apple Core Video conformance fixtures
- [ ] Platform storage integrations
- [ ] Zero-copy binary attachment storage

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

## Test evidence

Verified on 2026-07-24:

| Verification | Evidence |
|---|---|
| Native behavior | `xcodebuild test` passed 21 tests in 5 suites |
| WASM | `swift build --swift-sdk swift-6.3.1-RELEASE_wasm --target OpenCoreVideo` passed |
| Embedded Swift | `swift build --swift-sdk swift-6.3.1-RELEASE_wasm-embedded --target OpenCoreVideo` passed |

The behavior suite verifies:

- owned packed storage metadata, byte round-trip, and stable storage identity;
- typed failures for invalid dimensions and row layout;
- typed failure for unsupported write access;
- identical external base addresses in read and write scopes;
- lock/unlock ordering and recovery after backend lock failure;
- exactly-once external release.
- attachment set, lookup, and removal independent of pixel bytes.
- attachment mode replacement, filtered snapshots, batch mutation, and removal;
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

## Not implemented

Buffer pools, concrete aggregate Core Foundation adapters, native handles,
format conversion, browser video frames, DMA-BUF/NvBufSurface implementations,
V4L2 mappings, CUDA interoperability, and Apple status-code wrappers remain
outside the completed Smoke milestones. Their common single-owner planar
contract is implemented. Unsupported capabilities must continue to fail
explicitly; no placeholder buffer or silent copy is provided.
