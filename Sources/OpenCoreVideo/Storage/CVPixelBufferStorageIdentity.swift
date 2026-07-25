public struct CVPixelBufferStorageIdentity:
    RawRepresentable,
    Sendable,
    Hashable
{
    /// An adapter-provided identity that remains stable for one native owner.
    ///
    /// Integration packages are responsible for avoiding collisions between
    /// simultaneously live owners.
    public let rawValue: UInt64

    public init(rawValue: UInt64) {
        self.rawValue = rawValue
    }
}
