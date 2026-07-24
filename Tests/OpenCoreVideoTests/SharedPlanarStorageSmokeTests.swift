import OpenCoreVideo
import Synchronization
import Testing

@Suite("Shared planar storage smoke")
struct SharedPlanarStorageSmokeTests {
    private typealias Buffer = CVLeasedPlanarPixelBuffer<
        SharedPlanarLeaseProbe,
        CVBufferAttachments
    >

    @Test("One lease exposes every plane without copying")
    func sharedLeaseIsZeroCopy() throws {
        let layout = try makeBiPlanarLayout()
        let releaseCount = SharedReleaseCounter()
        var lease: SharedPlanarLeaseProbe? = try SharedPlanarLeaseProbe(
            planeByteCounts: [16, 8],
            accessCapabilities: .readWrite,
            releaseCount: releaseCount
        )
        let expectedBaseAddress = try #require(lease?.baseAddress)

        do {
            let buffer = try Buffer(
                layout: layout,
                storageLease: #require(lease)
            )
            lease = nil

            var planeAddress: UInt?
            try buffer.withWriteBytes(ofPlane: 1) { bytes in
                bytes[0] = 31
                bytes[7] = 97
                planeAddress =
                    bytes.withUnsafeMutableBufferPointer { buffer in
                        buffer.baseAddress.map { UInt(bitPattern: $0) }
                    }
            }

            #expect(planeAddress == expectedBaseAddress + 16)
            #expect(releaseCount.value == 0)

            let sourceAddress = try #require(
                UnsafeMutableRawPointer(bitPattern: expectedBaseAddress)
            )
            sourceAddress.storeBytes(
                of: UInt8(53),
                toByteOffset: 4,
                as: UInt8.self
            )
            var observed: UInt8 = 0
            try buffer.withReadBytes(ofPlane: 0) { bytes in
                observed = bytes[4]
            }
            #expect(observed == 53)
        }

        #expect(releaseCount.value == 1)
    }

    @Test("Layout and lease metadata must agree")
    func storageValidation() throws {
        let layout = try makeBiPlanarLayout()

        let missingPlane = try SharedPlanarLeaseProbe(
            planeByteCounts: [16]
        )
        #expect(throws: CVPixelBufferError.planeCountMismatch(
            expected: 2,
            actual: 1
        )) {
            _ = try Buffer(
                layout: layout,
                storageLease: missingPlane
            )
        }

        let undersizedPlane = try SharedPlanarLeaseProbe(
            planeByteCounts: [16, 4]
        )
        #expect(throws: CVPixelBufferError.planeStorageTooSmall(
            plane: 1,
            required: 8,
            actual: 4
        )) {
            _ = try Buffer(
                layout: layout,
                storageLease: undersizedPlane
            )
        }

        let validLease = try SharedPlanarLeaseProbe(
            planeByteCounts: [16, 8]
        )
        let buffer = try Buffer(
            layout: layout,
            storageLease: validLease
        )
        #expect(buffer.isPlanar)
        #expect(buffer.planeCount == 2)
        #expect(buffer.byteCount == 24)
        #expect(try buffer.dimensionsOfPlane(at: 1).width == 2)
        #expect(try buffer.bytesPerRowOfPlane(at: 1) == 4)
        #expect(throws: CVPixelBufferError.invalidPlaneIndex(
            index: -1,
            planeCount: 2
        )) {
            try buffer.withReadBytes(ofPlane: -1) { _ in }
        }
        #expect(throws: CVPixelBufferError.invalidPlaneIndex(
            index: 2,
            planeCount: 2
        )) {
            try buffer.withWriteBytes(ofPlane: 2) { _ in }
        }
        #expect(throws: CVPixelBufferError.planarBufferRequiresPlaneAccess) {
            try buffer.withReadBytes { _ in }
        }
    }

    @Test("Access is buffer-wide and recovers after backend failure")
    func accessExclusionAndRecovery() throws {
        let lease = try SharedPlanarLeaseProbe(
            planeByteCounts: [16, 8]
        )
        let buffer = try Buffer(
            layout: makeBiPlanarLayout(),
            storageLease: lease
        )

        try buffer.withReadBytes(ofPlane: 0) { _ in
            #expect(throws: CVPixelBufferError.accessConflict(.write)) {
                try buffer.withWriteBytes(ofPlane: 1) { _ in }
            }
        }

        lease.failNextAccess(.read, code: 42)
        #expect(throws: CVPixelBufferError.platformAccessFailure(code: 42)) {
            try buffer.withReadBytes(ofPlane: 1) { _ in }
        }

        try buffer.withWriteBytes(ofPlane: 1) { bytes in
            bytes[0] = 7
        }
        #expect(lease.events == [
            .lock(.read, plane: 0),
            .unlock(.read, plane: 0),
            .lock(.write, plane: 1),
            .unlock(.write, plane: 1),
        ])
    }

    @Test("Read-only shared storage rejects writes")
    func readOnlyStorage() throws {
        let lease = try SharedPlanarLeaseProbe(
            planeByteCounts: [16, 8],
            accessCapabilities: [.read]
        )
        let buffer = try Buffer(
            layout: makeBiPlanarLayout(),
            storageLease: lease
        )

        #expect(throws: CVPixelBufferError.unsupportedAccess(.write)) {
            try buffer.withWriteBytes(ofPlane: 0) { _ in }
        }
        try buffer.withReadBytes(ofPlane: 1) { _ in }
    }

    private func makeBiPlanarLayout()
        throws -> CVPlanarPixelBufferLayout
    {
        let imageDimensions = try CVPixelDimensions(width: 4, height: 4)
        let luma = try CVPixelBufferPlaneLayout(
            dimensions: imageDimensions,
            bytesPerElement: 1,
            bytesPerRow: 4
        )
        let chroma = try CVPixelBufferPlaneLayout(
            dimensions: CVPixelDimensions(width: 2, height: 2),
            bytesPerElement: 2,
            bytesPerRow: 4
        )
        return try CVPlanarPixelBufferLayout(
            dimensions: imageDimensions,
            pixelFormat: .yCbCr420BiPlanarVideoRange,
            planes: [luma, chroma]
        )
    }
}

private enum SharedAccessEvent: Sendable, Equatable {
    case lock(CVPixelBufferAccessMode, plane: Int)
    case unlock(CVPixelBufferAccessMode, plane: Int)
}

private final class SharedReleaseCounter: Sendable {
    private let count = Mutex(0)

    var value: Int {
        count.withLock { count in
            count
        }
    }

    func increment() {
        count.withLock { count in
            count += 1
        }
    }
}

private final class SharedPlanarLeaseProbe: CVPlanarStorageLease {
    private struct Plane: Sendable {
        let offset: Int
        let byteCount: Int
    }

    private struct State: Sendable {
        var readerCount = 0
        var isWriting = false
        var failure: (mode: CVPixelBufferAccessMode, code: Int32)?
        var events: [SharedAccessEvent] = []
    }

    let planeCount: Int
    let accessCapabilities: CVPixelBufferAccessCapabilities
    let baseAddress: UInt

    private let planes: [Plane]
    private let releaseCount: SharedReleaseCounter
    private let state = Mutex(State())

    var events: [SharedAccessEvent] {
        state.withLock { state in
            state.events
        }
    }

    init(
        planeByteCounts: [Int],
        accessCapabilities: CVPixelBufferAccessCapabilities = .readWrite,
        releaseCount: SharedReleaseCounter = SharedReleaseCounter()
    ) throws(CVPixelBufferError) {
        guard !planeByteCounts.isEmpty else {
            throw .invalidPlaneCount(0)
        }
        guard !accessCapabilities.isEmpty else {
            throw .unsupportedAccess(.read)
        }

        var offset = 0
        var planes: [Plane] = []
        planes.reserveCapacity(planeByteCounts.count)
        for byteCount in planeByteCounts {
            guard byteCount > 0 else {
                throw .invalidStorageSize(byteCount)
            }
            let end = offset.addingReportingOverflow(byteCount)
            guard !end.overflow else {
                throw .layoutOverflow
            }
            planes.append(Plane(offset: offset, byteCount: byteCount))
            offset = end.partialValue
        }

        let baseAddress = UnsafeMutableRawPointer.allocate(
            byteCount: offset,
            alignment: 8
        )
        baseAddress.initializeMemory(
            as: UInt8.self,
            repeating: 0,
            count: offset
        )

        self.planeCount = planes.count
        self.accessCapabilities = accessCapabilities
        self.baseAddress = UInt(bitPattern: baseAddress)
        self.planes = planes
        self.releaseCount = releaseCount
    }

    deinit {
        if let address = UnsafeMutableRawPointer(bitPattern: baseAddress) {
            address.deallocate()
        }
        releaseCount.increment()
    }

    func byteCount(
        ofPlane index: Int
    ) throws(CVPixelBufferError) -> Int {
        try plane(at: index).byteCount
    }

    func withReadBytes(
        ofPlane index: Int,
        _ body: (borrowing Span<UInt8>) -> Void
    ) throws(CVPixelBufferError) {
        let plane = try plane(at: index)
        try acquire(.read, plane: index)
        defer {
            finish(.read, plane: index)
        }

        guard
            let address = UnsafeMutableRawPointer(bitPattern: baseAddress)?
                .advanced(by: plane.offset)
        else {
            throw CVPixelBufferError.storageReleased
        }
        let bytes = address.assumingMemoryBound(to: UInt8.self)
        body(Span(
            _unsafeStart: UnsafePointer(bytes),
            count: plane.byteCount
        ))
    }

    func withWriteBytes(
        ofPlane index: Int,
        _ body: (inout MutableSpan<UInt8>) -> Void
    ) throws(CVPixelBufferError) {
        let plane = try plane(at: index)
        try acquire(.write, plane: index)
        defer {
            finish(.write, plane: index)
        }

        guard
            let address = UnsafeMutableRawPointer(bitPattern: baseAddress)?
                .advanced(by: plane.offset)
        else {
            throw CVPixelBufferError.storageReleased
        }
        let bytes = address.assumingMemoryBound(to: UInt8.self)
        var span = MutableSpan(
            _unsafeStart: bytes,
            count: plane.byteCount
        )
        body(&span)
    }

    func failNextAccess(
        _ mode: CVPixelBufferAccessMode,
        code: Int32
    ) {
        state.withLock { state in
            state.failure = (mode, code)
        }
    }

    private func plane(
        at index: Int
    ) throws(CVPixelBufferError) -> Plane {
        guard planes.indices.contains(index) else {
            throw .invalidPlaneIndex(
                index: index,
                planeCount: planes.count
            )
        }
        return planes[index]
    }

    private func acquire(
        _ mode: CVPixelBufferAccessMode,
        plane: Int
    ) throws(CVPixelBufferError) {
        try state.withLock { state throws(CVPixelBufferError) in
            if let failure = state.failure, failure.mode == mode {
                state.failure = nil
                throw .platformAccessFailure(code: failure.code)
            }

            switch mode {
            case .read:
                guard accessCapabilities.contains(.read) else {
                    throw .unsupportedAccess(.read)
                }
                guard !state.isWriting else {
                    throw .accessConflict(.read)
                }
                state.readerCount += 1
            case .write:
                guard accessCapabilities.contains(.write) else {
                    throw .unsupportedAccess(.write)
                }
                guard !state.isWriting, state.readerCount == 0 else {
                    throw .accessConflict(.write)
                }
                state.isWriting = true
            }
            state.events.append(.lock(mode, plane: plane))
        }
    }

    private func finish(
        _ mode: CVPixelBufferAccessMode,
        plane: Int
    ) {
        state.withLock { state in
            switch mode {
            case .read:
                precondition(state.readerCount > 0)
                state.readerCount -= 1
            case .write:
                precondition(state.isWriting)
                state.isWriting = false
            }
            state.events.append(.unlock(mode, plane: plane))
        }
    }
}
