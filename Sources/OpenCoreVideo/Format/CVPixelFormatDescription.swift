public struct CVPixelFormatDescription: Sendable, Equatable {
    public struct Compatibility: OptionSet, Sendable, Hashable {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let cgBitmapContext = Self(rawValue: 1 << 0)
        public static let cgImage = Self(rawValue: 1 << 1)
        public static let ioSurfaceCoreAnimation = Self(rawValue: 1 << 2)
        public static let metalTexture = Self(rawValue: 1 << 3)
    }

    public struct Components: OptionSet, Sendable, Hashable {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let alpha = Self(rawValue: 1 << 0)
        public static let grayscale = Self(rawValue: 1 << 1)
        public static let rgb = Self(rawValue: 1 << 2)
        public static let yCbCr = Self(rawValue: 1 << 3)
        public static let senselArray = Self(rawValue: 1 << 4)
    }

    public enum ComponentRange: Sendable, Hashable {
        case full
        case video
        case wide
    }

    public struct Dimensions: Sendable, Hashable {
        public var horizontal: Int
        public var vertical: Int

        public init(horizontal: Int, vertical: Int) {
            self.horizontal = horizontal
            self.vertical = vertical
        }
    }

    public struct PixelLayout: Sendable, Equatable {
        public var blockSize: CVImageSize
        public var bitsPerBlock: Int
        public var bitsPerComponent: Int?
        public var blockAlignment: Dimensions
        public var subsampling: Dimensions
        public var blackBlock: [UInt8]?
        public var compatibility: Compatibility

        public init(
            blockSize: CVImageSize = CVImageSize(width: 1, height: 1),
            bitsPerBlock: Int,
            bitsPerComponent: Int? = nil,
            blockAlignment: Dimensions = Dimensions(
                horizontal: 1,
                vertical: 1
            ),
            subsampling: Dimensions = Dimensions(
                horizontal: 1,
                vertical: 1
            ),
            blackBlock: [UInt8]? = nil,
            compatibility: Compatibility = []
        ) throws(CVPixelFormatDescriptionError) {
            guard blockSize.width > 0, blockSize.height > 0 else {
                throw .invalidBlockSize(blockSize)
            }
            guard bitsPerBlock > 0 else {
                throw .invalidBitsPerBlock(bitsPerBlock)
            }
            if let bitsPerComponent, bitsPerComponent <= 0 {
                throw .invalidBitsPerComponent(bitsPerComponent)
            }
            guard blockAlignment.horizontal > 0,
                  blockAlignment.vertical > 0 else {
                throw .invalidBlockAlignment(blockAlignment)
            }
            guard subsampling.horizontal > 0,
                  subsampling.vertical > 0 else {
                throw .invalidSubsampling(subsampling)
            }
            self.blockSize = blockSize
            self.bitsPerBlock = bitsPerBlock
            self.bitsPerComponent = bitsPerComponent
            self.blockAlignment = blockAlignment
            self.subsampling = subsampling
            self.blackBlock = blackBlock
            self.compatibility = compatibility
        }

        internal init(
            validatedBlockSize blockSize: CVImageSize,
            bitsPerBlock: Int,
            bitsPerComponent: Int?,
            blockAlignment: Dimensions,
            subsampling: Dimensions,
            blackBlock: [UInt8]?,
            compatibility: Compatibility
        ) {
            self.blockSize = blockSize
            self.bitsPerBlock = bitsPerBlock
            self.bitsPerComponent = bitsPerComponent
            self.blockAlignment = blockAlignment
            self.subsampling = subsampling
            self.blackBlock = blackBlock
            self.compatibility = compatibility
        }
    }

    public enum PlaneConfiguration: Sendable, Equatable {
        case nonPlanar(PixelLayout)
        case planar([PixelLayout])
    }

    public var pixelFormatType: CVPixelFormatType
    public var name: String
    public var components: Components
    public var componentRange: ComponentRange?
    public var planeConfiguration: PlaneConfiguration

    public init(
        pixelFormatType: CVPixelFormatType,
        name: String,
        components: Components,
        componentRange: ComponentRange? = nil,
        planeConfiguration: PlaneConfiguration
    ) throws(CVPixelFormatDescriptionError) {
        guard pixelFormatType.rawValue != 0 else {
            throw .invalidPixelFormat(pixelFormatType.rawValue)
        }
        guard !name.isEmpty else {
            throw .invalidName
        }
        guard !components.isEmpty else {
            throw .emptyComponents
        }
        if case .planar(let planes) = planeConfiguration,
           planes.isEmpty {
            throw .invalidPlaneCount(planes.count)
        }
        self.pixelFormatType = pixelFormatType
        self.name = name
        self.components = components
        self.componentRange = componentRange
        self.planeConfiguration = planeConfiguration
    }

    internal init(
        validatedPixelFormatType pixelFormatType: CVPixelFormatType,
        name: String,
        components: Components,
        componentRange: ComponentRange?,
        planeConfiguration: PlaneConfiguration
    ) {
        self.pixelFormatType = pixelFormatType
        self.name = name
        self.components = components
        self.componentRange = componentRange
        self.planeConfiguration = planeConfiguration
    }
}
