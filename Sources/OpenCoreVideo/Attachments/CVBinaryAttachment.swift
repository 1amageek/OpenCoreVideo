/// A retained, zero-copy binary attachment.
///
/// The caller transfers ownership only after initialization succeeds. Borrowed
/// bytes cannot escape `withReadBytes`, and the release handler runs exactly
/// once when the last attachment reference is released.
public final class CVBinaryAttachment:
    CVPlatformConcurrencyContract,
    Equatable
{
    public let byteCount: Int

    private let storage: CVExternalPixelBufferStorage?

    /// Creates an empty binary attachment without allocating storage.
    public init() {
        storage = nil
        byteCount = 0
    }

    public init(
        baseAddress: UnsafeMutableRawPointer,
        byteCount: Int,
        releaseHandler:
            @escaping @Sendable (UnsafeMutableRawPointer, Int) -> Void
    ) throws(CVPixelBufferError) {
        self.storage = try CVExternalPixelBufferStorage(
            baseAddress: baseAddress,
            byteCount: byteCount,
            accessCapabilities: [.read],
            releaseHandler: releaseHandler
        )
        self.byteCount = byteCount
    }

    public func withReadBytes(
        _ body: (borrowing Span<UInt8>) -> Void
    ) throws(CVPixelBufferError) {
        guard let storage else {
            var sentinel: UInt8 = 0
            withUnsafePointer(to: &sentinel) { pointer in
                body(Span(_unsafeStart: pointer, count: 0))
            }
            return
        }
        try storage.withReadAccess(body)
    }

    public static func == (
        lhs: CVBinaryAttachment,
        rhs: CVBinaryAttachment
    ) -> Bool {
        lhs === rhs
    }
}
