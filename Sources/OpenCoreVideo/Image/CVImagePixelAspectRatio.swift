public struct CVImagePixelAspectRatio: Sendable, Hashable {
    public var horizontalSpacing: Float
    public var verticalSpacing: Float

    public init(
        horizontalSpacing: Float,
        verticalSpacing: Float
    ) {
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }
}
