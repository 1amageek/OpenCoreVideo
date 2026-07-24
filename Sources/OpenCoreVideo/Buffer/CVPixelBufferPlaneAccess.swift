/// Returns the number of image planes.
///
/// This matches `CVPixelBufferGetPlaneCount` for valid buffers, including
/// returning zero for packed buffers.
public func CVPixelBufferGetPlaneCount<Buffer: CVPixelBuffer>(
    _ pixelBuffer: borrowing Buffer
) -> Int {
    pixelBuffer.planeCount
}

/// Returns a plane width after validating the plane index.
///
/// Unlike Apple's C function, the portable API reports an invalid plane index
/// as a typed error instead of returning zero.
public func CVPixelBufferGetWidthOfPlane<Buffer: CVPixelBuffer>(
    _ pixelBuffer: borrowing Buffer,
    _ planeIndex: Int
) throws(CVPixelBufferError) -> Int {
    try pixelBuffer.dimensionsOfPlane(at: planeIndex).width
}

/// Returns a plane height after validating the plane index.
///
/// Unlike Apple's C function, the portable API reports an invalid plane index
/// as a typed error instead of returning zero.
public func CVPixelBufferGetHeightOfPlane<Buffer: CVPixelBuffer>(
    _ pixelBuffer: borrowing Buffer,
    _ planeIndex: Int
) throws(CVPixelBufferError) -> Int {
    try pixelBuffer.dimensionsOfPlane(at: planeIndex).height
}

/// Returns a plane row stride after validating the plane index.
///
/// Unlike Apple's C function, the portable API reports an invalid plane index
/// as a typed error instead of returning zero.
public func CVPixelBufferGetBytesPerRowOfPlane<Buffer: CVPixelBuffer>(
    _ pixelBuffer: borrowing Buffer,
    _ planeIndex: Int
) throws(CVPixelBufferError) -> Int {
    try pixelBuffer.bytesPerRowOfPlane(at: planeIndex)
}
