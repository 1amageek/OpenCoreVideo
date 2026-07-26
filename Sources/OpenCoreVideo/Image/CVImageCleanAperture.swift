public struct CVImageCleanAperture: Sendable, Hashable {
    public var width: Float
    public var height: Float
    public var horizontalOffset: Float
    public var verticalOffset: Float

    public init(
        width: Float,
        height: Float,
        horizontalOffset: Float,
        verticalOffset: Float
    ) {
        self.width = width
        self.height = height
        self.horizontalOffset = horizontalOffset
        self.verticalOffset = verticalOffset
    }
}
