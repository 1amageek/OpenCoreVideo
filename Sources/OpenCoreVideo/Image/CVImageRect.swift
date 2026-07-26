public struct CVImageRect: Sendable, Hashable {
    public static let zero = Self(
        x: 0,
        y: 0,
        width: 0,
        height: 0
    )

    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double

    public init(
        x: Double,
        y: Double,
        width: Double,
        height: Double
    ) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}
