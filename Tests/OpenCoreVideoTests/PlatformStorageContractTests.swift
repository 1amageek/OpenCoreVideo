import OpenCoreVideo
import Testing

@Suite("Platform storage contract")
struct PlatformStorageContractTests {
    @Test("Packed platform storage lends bytes and native handle")
    func packedStorage() throws {
        let storage = try PackedPlatformStorageProbe(
            identity: CVPixelBufferStorageIdentity(rawValue: 17),
            byteCount: 8
        )
        defer {
            storage.release()
        }

        var byteAddress: UInt?
        try storage.withWriteAccess { bytes in
            bytes[2] = 29
            byteAddress =
                bytes.withUnsafeMutableBufferPointer { pointer in
                    pointer.baseAddress.map { UInt(bitPattern: $0) }
                }
        }

        let handleAddress = try storage.withNativeHandle { handle in
            handle.address
        }
        #expect(storage.storageIdentity.rawValue == 17)
        #expect(handleAddress == byteAddress)
    }

    @Test("Planar platform storage uses one owner for every plane")
    func planarStorage() throws {
        let storage = try PlanarPlatformStorageProbe(
            identity: CVPixelBufferStorageIdentity(rawValue: 31),
            planeByteCounts: [8, 4]
        )
        defer {
            storage.release()
        }

        let baseAddress = try storage.withNativeHandle { handle in
            handle.address
        }
        var secondPlaneAddress: UInt?
        try storage.withReadBytes(ofPlane: 1) { bytes in
            secondPlaneAddress =
                bytes.withUnsafeBufferPointer { pointer in
                    pointer.baseAddress.map { UInt(bitPattern: $0) }
                }
        }

        #expect(storage.storageIdentity.rawValue == 31)
        #expect(secondPlaneAddress == baseAddress + 8)
    }
}

private struct PlatformHandle {
    let address: UInt
}

private final class PackedPlatformStorageProbe:
    CVPackedPlatformStorageLease
{
    let storageIdentity: CVPixelBufferStorageIdentity
    let byteCount: Int
    let accessCapabilities =
        CVPixelBufferAccessCapabilities.readWrite

    private let address: UInt

    init(
        identity: CVPixelBufferStorageIdentity,
        byteCount: Int
    ) throws(CVPixelBufferError) {
        guard byteCount > 0 else {
            throw .invalidStorageSize(byteCount)
        }
        let pointer = UnsafeMutableRawPointer.allocate(
            byteCount: byteCount,
            alignment: 8
        )
        pointer.initializeMemory(
            as: UInt8.self,
            repeating: 0,
            count: byteCount
        )
        self.storageIdentity = identity
        self.byteCount = byteCount
        self.address = UInt(bitPattern: pointer)
    }

    func release() {
        UnsafeMutableRawPointer(bitPattern: address)?.deallocate()
    }

    func withNativeHandle<Result>(
        _ body: (borrowing PlatformHandle) -> Result
    ) throws(CVPixelBufferError) -> Result {
        body(PlatformHandle(address: address))
    }

    func withReadAccess(
        _ body: (borrowing Span<UInt8>) -> Void
    ) throws(CVPixelBufferError) {
        let pointer = UnsafeMutableRawPointer(bitPattern: address)!
            .assumingMemoryBound(to: UInt8.self)
        body(Span(
            _unsafeStart: UnsafePointer(pointer),
            count: byteCount
        ))
    }

    func withWriteAccess(
        _ body: (inout MutableSpan<UInt8>) -> Void
    ) throws(CVPixelBufferError) {
        let pointer = UnsafeMutableRawPointer(bitPattern: address)!
            .assumingMemoryBound(to: UInt8.self)
        var bytes = MutableSpan(
            _unsafeStart: pointer,
            count: byteCount
        )
        body(&bytes)
    }
}

private final class PlanarPlatformStorageProbe:
    CVPlanarPlatformStorageLease
{
    let storageIdentity: CVPixelBufferStorageIdentity
    let planeCount: Int
    let accessCapabilities =
        CVPixelBufferAccessCapabilities.readWrite

    private let address: UInt
    private let planeByteCounts: [Int]

    init(
        identity: CVPixelBufferStorageIdentity,
        planeByteCounts: [Int]
    ) throws(CVPixelBufferError) {
        guard !planeByteCounts.isEmpty else {
            throw .invalidPlaneCount(0)
        }
        let total = planeByteCounts.reduce(0, +)
        let pointer = UnsafeMutableRawPointer.allocate(
            byteCount: total,
            alignment: 8
        )
        pointer.initializeMemory(
            as: UInt8.self,
            repeating: 0,
            count: total
        )
        self.storageIdentity = identity
        self.planeCount = planeByteCounts.count
        self.address = UInt(bitPattern: pointer)
        self.planeByteCounts = planeByteCounts
    }

    func release() {
        UnsafeMutableRawPointer(bitPattern: address)?.deallocate()
    }

    func byteCount(
        ofPlane index: Int
    ) throws(CVPixelBufferError) -> Int {
        guard planeByteCounts.indices.contains(index) else {
            throw .invalidPlaneIndex(
                index: index,
                planeCount: planeCount
            )
        }
        return planeByteCounts[index]
    }

    func withNativeHandle<Result>(
        _ body: (borrowing PlatformHandle) -> Result
    ) throws(CVPixelBufferError) -> Result {
        body(PlatformHandle(address: address))
    }

    func withReadBytes(
        ofPlane index: Int,
        _ body: (borrowing Span<UInt8>) -> Void
    ) throws(CVPixelBufferError) {
        let byteCount = try byteCount(ofPlane: index)
        let offset = planeByteCounts[..<index].reduce(0, +)
        let pointer = UnsafeMutableRawPointer(bitPattern: address)!
            .advanced(by: offset)
            .assumingMemoryBound(to: UInt8.self)
        body(Span(
            _unsafeStart: UnsafePointer(pointer),
            count: byteCount
        ))
    }

    func withWriteBytes(
        ofPlane index: Int,
        _ body: (inout MutableSpan<UInt8>) -> Void
    ) throws(CVPixelBufferError) {
        let byteCount = try byteCount(ofPlane: index)
        let offset = planeByteCounts[..<index].reduce(0, +)
        let pointer = UnsafeMutableRawPointer(bitPattern: address)!
            .advanced(by: offset)
            .assumingMemoryBound(to: UInt8.self)
        var bytes = MutableSpan(
            _unsafeStart: pointer,
            count: byteCount
        )
        body(&bytes)
    }
}
