public struct CVImageFloatSize: Sendable, Hashable {
    public static let zero = Self(width: 0, height: 0)

    public var width: Double
    public var height: Double

    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }
}
