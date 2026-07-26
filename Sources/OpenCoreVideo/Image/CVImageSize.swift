public struct CVImageSize: Sendable, Hashable {
    public static let zero = Self(width: 0, height: 0)

    public var width: Int
    public var height: Int

    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }
}
