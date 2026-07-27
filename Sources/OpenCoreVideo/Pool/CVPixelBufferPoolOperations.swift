/// Creates an attachment-free pixel buffer from reusable pool storage.
///
/// The portable form returns the buffer and reports a typed error instead of
/// accepting a Core Foundation allocator, out parameter, and `CVReturn`.
public func CVPixelBufferPoolCreatePixelBuffer<
    Allocator: CVPixelBufferPoolAllocator
>(
    _ pool: borrowing CVPixelBufferPool<Allocator>
) throws(CVPixelBufferError) -> CVPackedPixelBuffer {
    try pool.makePixelBuffer()
}

/// Creates a pixel buffer subject to a per-request allocation threshold.
///
/// Reusable storage does not count as a new allocation and remains available
/// when the current allocation count has reached the threshold.
public func CVPixelBufferPoolCreatePixelBufferWithAuxAttributes<
    Allocator: CVPixelBufferPoolAllocator
>(
    _ pool: borrowing CVPixelBufferPool<Allocator>,
    allocationThreshold: Int?
) throws(CVPixelBufferError) -> CVPackedPixelBuffer {
    try pool.makePixelBuffer(
        allocationThreshold: allocationThreshold
    )
}

/// Frees cached pixel-buffer storage according to the supplied flags.
public func CVPixelBufferPoolFlush<
    Allocator: CVPixelBufferPoolAllocator
>(
    _ pool: borrowing CVPixelBufferPool<Allocator>,
    _ flags: CVPixelBufferPoolFlushFlags
) {
    pool.flush(flags)
}
