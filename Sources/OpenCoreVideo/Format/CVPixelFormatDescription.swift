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
        public static let generic = Self(rawValue: 1 << 5)
    }

    public enum ComponentRange: Sendable, Hashable {
        case full
        case video
        case wide
    }

    public struct Dimensions: Sendable, Hashable {
        public let horizontal: Int
        public let vertical: Int

        public init(horizontal: Int, vertical: Int) {
            self.horizontal = horizontal
            self.vertical = vertical
        }
    }

    public struct PixelLayout: Sendable, Equatable {
        public let blockSize: CVImageSize
        public let bitsPerBlock: Int
        public let bitsPerComponent: Int?
        public let blockAlignment: Dimensions
        public let subsampling: Dimensions
        public let blackBlock: [UInt8]?
        public let compatibility: Compatibility

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
            guard bitsPerBlock.isMultiple(of: 8) else {
                throw .bitsPerBlockNotByteAligned(bitsPerBlock)
            }
            if let bitsPerComponent, bitsPerComponent <= 0 {
                throw .invalidBitsPerComponent(bitsPerComponent)
            }
            if let bitsPerComponent, bitsPerComponent > bitsPerBlock {
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
            if let blackBlock {
                let expectedByteCount = bitsPerBlock / 8
                guard blackBlock.count == expectedByteCount else {
                    throw .invalidBlackBlockByteCount(
                        expected: expectedByteCount,
                        actual: blackBlock.count
                    )
                }
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

    public let pixelFormatType: CVPixelFormatType
    public let name: String
    public let components: Components
    public let componentRange: ComponentRange?
    public let componentSubsampling: Dimensions?
    public let planeConfiguration: PlaneConfiguration

    public init(
        pixelFormatType: CVPixelFormatType,
        name: String,
        components: Components,
        componentRange: ComponentRange? = nil,
        componentSubsampling: Dimensions? = nil,
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
        if let componentSubsampling {
            guard componentSubsampling.horizontal > 0,
                  componentSubsampling.vertical > 0 else {
                throw .invalidSubsampling(componentSubsampling)
            }
        }
        if case .planar(let planes) = planeConfiguration,
           planes.isEmpty {
            throw .invalidPlaneCount(planes.count)
        }
        self.pixelFormatType = pixelFormatType
        self.name = name
        self.components = components
        self.componentRange = componentRange
        self.componentSubsampling = componentSubsampling
        self.planeConfiguration = planeConfiguration
    }

    internal init(
        validatedPixelFormatType pixelFormatType: CVPixelFormatType,
        name: String,
        components: Components,
        componentRange: ComponentRange?,
        componentSubsampling: Dimensions? = nil,
        planeConfiguration: PlaneConfiguration
    ) {
        self.pixelFormatType = pixelFormatType
        self.name = name
        self.components = components
        self.componentRange = componentRange
        self.componentSubsampling = componentSubsampling
        self.planeConfiguration = planeConfiguration
    }
}
