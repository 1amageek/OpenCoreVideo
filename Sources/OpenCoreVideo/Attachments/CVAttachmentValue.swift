public enum CVAttachmentValue:
    CVPlatformConcurrencyContract,
    Equatable
{
    case boolean(Bool)
    case integer(Int64)
    case unsignedInteger(UInt64)
    case floatingPoint(Double)
    case string(String)
    case binary(CVBinaryAttachment)
}
