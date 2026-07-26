public func CVImageBufferGetEncodedSize<Buffer: CVImageBuffer>(
    _ imageBuffer: borrowing Buffer
) -> CVImageSize {
    CVImageSize(
        width: imageBuffer.dimensions.width,
        height: imageBuffer.dimensions.height
    )
}

public func CVImageBufferGetCleanRect<Buffer: CVImageBuffer>(
    _ imageBuffer: borrowing Buffer
) throws(CVPixelBufferError) -> CVImageRect {
    let encodedWidth = Double(imageBuffer.dimensions.width)
    let encodedHeight = Double(imageBuffer.dimensions.height)
    guard let attachment = imageBuffer.attachments.attachment(
        for: kCVImageBufferCleanApertureKey
    ) else {
        return CVImageRect(
            x: 0,
            y: 0,
            width: encodedWidth,
            height: encodedHeight
        )
    }

    guard case .dictionary(let values) = attachment.value,
          let width = floatingPointValue(
            values[kCVImageBufferCleanApertureWidthKey]
          ),
          let height = floatingPointValue(
            values[kCVImageBufferCleanApertureHeightKey]
          ),
          let horizontalOffset = floatingPointValue(
            values[kCVImageBufferCleanApertureHorizontalOffsetKey]
          ),
          let verticalOffset = floatingPointValue(
            values[kCVImageBufferCleanApertureVerticalOffsetKey]
          ) else {
        throw .malformedImageBufferAttachment(
            kCVImageBufferCleanApertureKey
        )
    }

    let x = (encodedWidth - width) / 2 + horizontalOffset
    let y = (encodedHeight - height) / 2 - verticalOffset
    guard width > 0,
          height > 0,
          x >= 0,
          y >= 0,
          x + width <= encodedWidth,
          y + height <= encodedHeight else {
        throw .invalidCleanAperture
    }
    return CVImageRect(
        x: x,
        y: y,
        width: width,
        height: height
    )
}

public func CVImageBufferGetDisplaySize<Buffer: CVImageBuffer>(
    _ imageBuffer: borrowing Buffer
) throws(CVPixelBufferError) -> CVImageFloatSize {
    if let attachment = imageBuffer.attachments.attachment(
        for: kCVImageBufferDisplayDimensionsKey
    ) {
        guard case .dictionary(let values) = attachment.value,
              let width = floatingPointValue(
                values[kCVImageBufferDisplayWidthKey]
              ),
              let height = floatingPointValue(
                values[kCVImageBufferDisplayHeightKey]
              ) else {
            throw .malformedImageBufferAttachment(
                kCVImageBufferDisplayDimensionsKey
            )
        }
        guard width > 0, height > 0 else {
            throw .invalidDisplaySize(width: width, height: height)
        }
        return CVImageFloatSize(width: width, height: height)
    }

    let cleanRect = try CVImageBufferGetCleanRect(imageBuffer)
    guard let attachment = imageBuffer.attachments.attachment(
        for: kCVImageBufferPixelAspectRatioKey
    ) else {
        return CVImageFloatSize(
            width: cleanRect.width,
            height: cleanRect.height
        )
    }
    guard case .dictionary(let values) = attachment.value,
          let horizontalSpacing = floatingPointValue(
            values[kCVImageBufferPixelAspectRatioHorizontalSpacingKey]
          ),
          let verticalSpacing = floatingPointValue(
            values[kCVImageBufferPixelAspectRatioVerticalSpacingKey]
          ) else {
        throw .malformedImageBufferAttachment(
            kCVImageBufferPixelAspectRatioKey
        )
    }
    guard horizontalSpacing > 0, verticalSpacing > 0 else {
        throw .invalidPixelAspectRatio(
            horizontalSpacing: horizontalSpacing,
            verticalSpacing: verticalSpacing
        )
    }
    return CVImageFloatSize(
        width: cleanRect.width * horizontalSpacing / verticalSpacing,
        height: cleanRect.height
    )
}

public func CVImageBufferIsFlipped<Buffer: CVImageBuffer>(
    _ imageBuffer: borrowing Buffer
) -> Bool {
    imageBuffer.originPosition == .topLeft
}

public func CVImageBufferSetCleanAperture<Buffer: CVImageBuffer>(
    _ imageBuffer: borrowing Buffer,
    _ aperture: CVImageCleanAperture?,
    _ mode: CVAttachmentMode = .shouldPropagate
) throws(CVPixelBufferError) {
    guard let aperture else {
        imageBuffer.attachments.removeAttachment(
            for: kCVImageBufferCleanApertureKey
        )
        return
    }
    guard aperture.width > 0, aperture.height > 0 else {
        throw .invalidCleanAperture
    }
    imageBuffer.attachments.setAttachment(
        CVBufferAttachment(
            value: .dictionary([
                kCVImageBufferCleanApertureWidthKey:
                    .floatingPoint(Double(aperture.width)),
                kCVImageBufferCleanApertureHeightKey:
                    .floatingPoint(Double(aperture.height)),
                kCVImageBufferCleanApertureHorizontalOffsetKey:
                    .floatingPoint(Double(aperture.horizontalOffset)),
                kCVImageBufferCleanApertureVerticalOffsetKey:
                    .floatingPoint(Double(aperture.verticalOffset))
            ]),
            mode: mode
        ),
        for: kCVImageBufferCleanApertureKey
    )
}

public func CVImageBufferSetPixelAspectRatio<Buffer: CVImageBuffer>(
    _ imageBuffer: borrowing Buffer,
    _ ratio: CVImagePixelAspectRatio?,
    _ mode: CVAttachmentMode = .shouldPropagate
) throws(CVPixelBufferError) {
    guard let ratio else {
        imageBuffer.attachments.removeAttachment(
            for: kCVImageBufferPixelAspectRatioKey
        )
        return
    }
    guard ratio.horizontalSpacing > 0, ratio.verticalSpacing > 0 else {
        throw .invalidPixelAspectRatio(
            horizontalSpacing: Double(ratio.horizontalSpacing),
            verticalSpacing: Double(ratio.verticalSpacing)
        )
    }
    imageBuffer.attachments.setAttachment(
        CVBufferAttachment(
            value: .dictionary([
                kCVImageBufferPixelAspectRatioHorizontalSpacingKey:
                    .floatingPoint(Double(ratio.horizontalSpacing)),
                kCVImageBufferPixelAspectRatioVerticalSpacingKey:
                    .floatingPoint(Double(ratio.verticalSpacing))
            ]),
            mode: mode
        ),
        for: kCVImageBufferPixelAspectRatioKey
    )
}

public func CVImageBufferSetDisplaySize<Buffer: CVImageBuffer>(
    _ imageBuffer: borrowing Buffer,
    _ size: CVImageFloatSize?,
    _ mode: CVAttachmentMode = .shouldPropagate
) throws(CVPixelBufferError) {
    guard let size else {
        imageBuffer.attachments.removeAttachment(
            for: kCVImageBufferDisplayDimensionsKey
        )
        return
    }
    guard size.width > 0, size.height > 0 else {
        throw .invalidDisplaySize(
            width: size.width,
            height: size.height
        )
    }
    imageBuffer.attachments.setAttachment(
        CVBufferAttachment(
            value: .dictionary([
                kCVImageBufferDisplayWidthKey:
                    .floatingPoint(size.width),
                kCVImageBufferDisplayHeightKey:
                    .floatingPoint(size.height)
            ]),
            mode: mode
        ),
        for: kCVImageBufferDisplayDimensionsKey
    )
}

private func floatingPointValue(
    _ value: CVAttachmentValue?
) -> Double? {
    switch value {
    case .floatingPoint(let value): return value
    case .integer(let value): return Double(value)
    case .unsignedInteger(let value): return Double(value)
    default: return nil
    }
}
