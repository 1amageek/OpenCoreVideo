public func CVPixelFormatDescriptionCreateWithPixelFormatType(
    _ pixelFormat: CVPixelFormatType
) -> CVPixelFormatDescription? {
    CVPixelFormatDescription.Registry.shared[pixelFormat]
}

public func CVPixelFormatDescriptionArrayCreateWithAllPixelFormatTypes()
    -> [CVPixelFormatType]
{
    let descriptions =
        CVPixelFormatDescription.Registry.shared.formatDescriptions
    var pixelFormats: [CVPixelFormatType] = []
    pixelFormats.reserveCapacity(descriptions.count)
    for description in descriptions {
        pixelFormats.append(description.pixelFormatType)
    }
    return pixelFormats
}

public func CVPixelFormatDescriptionRegisterDescriptionWithPixelFormatType(
    _ description: CVPixelFormatDescription,
    _ pixelFormat: CVPixelFormatType
) throws(CVPixelFormatDescriptionError) {
    guard description.pixelFormatType == pixelFormat else {
        throw .pixelFormatMismatch(
            description: description.pixelFormatType,
            registration: pixelFormat
        )
    }
    CVPixelFormatDescription.Registry.shared.register(description)
}

public func CVPixelFormatTypeCopyFourCharCodeString(
    _ pixelFormat: CVPixelFormatType
) -> String {
    let rawValue = pixelFormat.rawValue
    let bytes = [
        UInt8(truncatingIfNeeded: rawValue >> 24),
        UInt8(truncatingIfNeeded: rawValue >> 16),
        UInt8(truncatingIfNeeded: rawValue >> 8),
        UInt8(truncatingIfNeeded: rawValue)
    ]
    for byte in bytes where !(0x20 ... 0x7E).contains(byte) {
        return String(rawValue)
    }
    return String(decoding: bytes, as: UTF8.self)
}
