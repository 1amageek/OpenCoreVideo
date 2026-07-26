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
