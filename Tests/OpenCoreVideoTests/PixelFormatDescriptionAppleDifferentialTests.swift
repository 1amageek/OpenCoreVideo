#if canImport(CoreVideo) && canImport(Foundation)
import CoreVideo
import Foundation
import OpenCoreVideo
import Testing

@Suite("Apple pixel format description differential")
struct PixelFormatDescriptionAppleDifferentialTests {
    @Test("FourCC formatting matches Core Video")
    func fourCharacterCode() {
        guard #available(macOS 26.0, *) else {
            return
        }
        #expect(
            OpenCoreVideo.CVPixelFormatTypeCopyFourCharCodeString(
                .yCbCr422Packed10
            )
                == CoreVideo.CVPixelFormatTypeCopyFourCharCodeString(
                    CoreVideo.kCVPixelFormatType_422YpCbCr10
                ) as String
        )
    }

    @Test("Packed and planar descriptions match Core Video")
    func standardDescriptions() throws {
        try compare(
            appleType: kCVPixelFormatType_24RGB,
            portableType: .rgb24
        )
        try compare(
            appleType: kCVPixelFormatType_32ARGB,
            portableType: .argb32
        )
        try compare(
            appleType: kCVPixelFormatType_32BGRA,
            portableType: .bgra32
        )
        try compare(
            appleType: kCVPixelFormatType_64RGBAHalf,
            portableType: .rgba64Half
        )
        try compare(
            appleType: kCVPixelFormatType_128RGBAFloat,
            portableType: .rgba128Float
        )
        try compare(
            appleType: kCVPixelFormatType_OneComponent10,
            portableType: .oneComponent10
        )
        try compare(
            appleType: kCVPixelFormatType_OneComponent32Float,
            portableType: .oneComponent32Float
        )
        try compare(
            appleType: kCVPixelFormatType_DepthFloat32,
            portableType: .depth32Float
        )
        try compare(
            appleType: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
            portableType: .yCbCr420BiPlanarVideoRange
        )
        try compare(
            appleType: kCVPixelFormatType_422YpCbCr8BiPlanarFullRange,
            portableType: .yCbCr422BiPlanarFullRange
        )
        try compare(
            appleType: kCVPixelFormatType_420YpCbCr10BiPlanarVideoRange,
            portableType: .yCbCr420BiPlanar10VideoRange
        )
        try compare(
            appleType: kCVPixelFormatType_444YpCbCr10BiPlanarFullRange,
            portableType: .yCbCr444BiPlanar10FullRange
        )
        try compare(
            appleType: kCVPixelFormatType_444YpCbCr16BiPlanarVideoRange,
            portableType: .yCbCr444BiPlanar16VideoRange
        )
        try compare(
            appleType:
                kCVPixelFormatType_420YpCbCr8VideoRange_8A_TriPlanar,
            portableType: .yCbCr420VideoRangeWithAlphaTriPlanar
        )
        try compare(
            appleType:
                kCVPixelFormatType_444YpCbCr16VideoRange_16A_TriPlanar,
            portableType: .yCbCr444VideoRangeWithAlphaTriPlanar16
        )
        try compare(
            appleType: kCVPixelFormatType_30RGBLE_8A_BiPlanar,
            portableType: .rgb30WideGamutWithAlphaBiPlanar
        )
        try compare(
            appleType: kCVPixelFormatType_8IndexedGray_WhiteIsZero,
            portableType: .indexedGrayWhiteIsZero8
        )
        try compare(
            appleType: kCVPixelFormatType_16BE555,
            portableType: .rgb555BigEndian
        )
        try compare(
            appleType: kCVPixelFormatType_30RGB,
            portableType: .rgb30BigEndian
        )
        try compare(
            appleType: kCVPixelFormatType_30RGB_r210,
            portableType: .rgb30BigEndianVideoRange
        )
        try compare(
            appleType: kCVPixelFormatType_30RGBLEPackedWideGamut,
            portableType: .rgb30LittleEndianWideGamut
        )
        try compare(
            appleType: kCVPixelFormatType_ARGB2101010LEPacked,
            portableType: .argb2101010LittleEndian
        )
        try compare(
            appleType: kCVPixelFormatType_40ARGBLEWideGamut,
            portableType: .argb40LittleEndianWideGamut
        )
        try compare(
            appleType: kCVPixelFormatType_40ARGBLEWideGamutPremultiplied,
            portableType: .argb40LittleEndianWideGamutPremultiplied
        )
        try compare(
            appleType: kCVPixelFormatType_14Bayer_GRBG,
            portableType: .bayer14GRBG
        )
        try compare(
            appleType: kCVPixelFormatType_14Bayer_RGGB,
            portableType: .bayer14RGGB
        )
        try compare(
            appleType: kCVPixelFormatType_14Bayer_BGGR,
            portableType: .bayer14BGGR
        )
        try compare(
            appleType: kCVPixelFormatType_14Bayer_GBRG,
            portableType: .bayer14GBRG
        )
        try compare(
            appleType: kCVPixelFormatType_16VersatileBayer,
            portableType: .versatileBayer16
        )
        try compare(
            appleType: kCVPixelFormatType_96VersatileBayerPacked12,
            portableType: .versatileBayerPacked12
        )
        try compare(
            appleType: kCVPixelFormatType_64RGBA_DownscaledProResRAW,
            portableType: .rgba64DownscaledProResRAW
        )
        try compare(
            appleType: kCVPixelFormatType_422YpCbCr8,
            portableType: .yCbCr422Packed8
        )
        try compare(
            appleType: kCVPixelFormatType_4444YpCbCrA8,
            portableType: .yCbCr4444AlphaPacked8
        )
        try compare(
            appleType: kCVPixelFormatType_4444YpCbCrA8R,
            portableType: .yCbCr4444AlphaRenderingPacked8
        )
        try compare(
            appleType: kCVPixelFormatType_4444AYpCbCr8,
            portableType: .alphaYCbCr4444Packed8
        )
        try compare(
            appleType: kCVPixelFormatType_4444AYpCbCr16,
            portableType: .alphaYCbCr4444Packed16
        )
        try compare(
            appleType: kCVPixelFormatType_4444AYpCbCrFloat,
            portableType: .alphaYCbCr4444PackedFloat
        )
        try compare(
            appleType: kCVPixelFormatType_444YpCbCr8,
            portableType: .yCbCr444Packed8
        )
        try compare(
            appleType: kCVPixelFormatType_422YpCbCr16,
            portableType: .yCbCr422Packed16
        )
        try compare(
            appleType: kCVPixelFormatType_422YpCbCr10,
            portableType: .yCbCr422Packed10
        )
        try compare(
            appleType: kCVPixelFormatType_444YpCbCr10,
            portableType: .yCbCr444Packed10
        )
        try compare(
            appleType: kCVPixelFormatType_422YpCbCr8_yuvs,
            portableType: .yCbCr422Packed8YUY2
        )
        try compare(
            appleType: kCVPixelFormatType_422YpCbCr8FullRange,
            portableType: .yCbCr422Packed8FullRange
        )
        try compare(
            appleType: kCVPixelFormatType_420YpCbCr8Planar,
            portableType: .yCbCr420PlanarVideoRange
        )
        try compare(
            appleType: kCVPixelFormatType_420YpCbCr8PlanarFullRange,
            portableType: .yCbCr420PlanarFullRange
        )
        try compare(
            appleType: kCVPixelFormatType_422YpCbCr_4A_8BiPlanar,
            portableType: .yCbCr422WithAlphaBiPlanar
        )
    }

    private func compare(
        appleType: OSType,
        portableType: OpenCoreVideo.CVPixelFormatType
    ) throws {
        let appleDictionary = try #require(
            CoreVideo.CVPixelFormatDescriptionCreateWithPixelFormatType(
                nil,
                appleType
            ) as? [String: Any]
        )
        let portableCandidate =
            OpenCoreVideo.CVPixelFormatDescriptionCreateWithPixelFormatType(
                portableType
            )
        guard let portable = portableCandidate else {
            Issue.record(
                "The portable registry must contain the standard format"
            )
            return
        }

        #expect(
            appleDictionary["PixelFormat"] as? UInt32
                == portable.pixelFormatType.rawValue
        )
        #expect(
            appleDictionary["ContainsAlpha"] as? Bool
                == portable.components.contains(.alpha)
        )
        #expect(
            appleDictionary["ContainsRGB"] as? Bool
                == portable.components.contains(.rgb)
        )
        #expect(
            appleDictionary["ContainsYCbCr"] as? Bool
                == portable.components.contains(.yCbCr)
        )
        #expect(
            ((appleDictionary["ContainsGrayscale"] as? Bool) ?? false)
                == portable.components.contains(.grayscale)
        )
        #expect(
            ((appleDictionary["ContainsSenselArray"] as? Bool) ?? false)
                == portable.components.contains(.senselArray)
        )
        #expect(
            appleDictionary["ComponentRange"] as? String
                == componentRangeName(portable.componentRange)
        )

        if let applePlanes = appleDictionary["Planes"] as? [[String: Any]] {
            guard case .planar(let portablePlanes) = portable.planeConfiguration else {
                Issue.record("Apple planar format must be portable planar")
                return
            }
            #expect(applePlanes.count == portablePlanes.count)
            #expect(
                ((appleDictionary["HorizontalSubsampling"] as? Int) ?? 1)
                    == (portable.componentSubsampling?.horizontal ?? 1)
            )
            #expect(
                ((appleDictionary["VerticalSubsampling"] as? Int) ?? 1)
                    == (portable.componentSubsampling?.vertical ?? 1)
            )
            for index in applePlanes.indices {
                #expect(
                    applePlanes[index]["BitsPerBlock"] as? Int
                        == portablePlanes[index].bitsPerBlock
                )
                #expect(
                    ((applePlanes[index]["HorizontalSubsampling"] as? Int)
                        ?? 1)
                        == portablePlanes[index].subsampling.horizontal
                )
                #expect(
                    ((applePlanes[index]["VerticalSubsampling"] as? Int)
                        ?? 1)
                        == portablePlanes[index].subsampling.vertical
                )
                #expect(
                    ((applePlanes[index]["BlockWidth"] as? Int) ?? 1)
                        == portablePlanes[index].blockSize.width
                )
                #expect(
                    ((applePlanes[index]["BlockHeight"] as? Int) ?? 1)
                        == portablePlanes[index].blockSize.height
                )
                #expect(
                    ((applePlanes[index]["BlockHorizontalAlignment"]
                        as? Int) ?? 1)
                        == portablePlanes[index].blockAlignment.horizontal
                )
                #expect(
                    ((applePlanes[index]["BlockVerticalAlignment"]
                        as? Int) ?? 1)
                        == portablePlanes[index].blockAlignment.vertical
                )
                compareBlackBlock(
                    applePlanes[index]["BlackBlock"] as? Data,
                    portablePlanes[index].blackBlock
                )
            }
            #expect(
                appleDictionary["BitsPerComponent"] as? Int
                    == portablePlanes.first?.bitsPerComponent
            )
        } else {
            guard case .nonPlanar(let portableLayout) = portable.planeConfiguration else {
                Issue.record("Apple packed format must be portable packed")
                return
            }
            #expect(
                appleDictionary["BitsPerBlock"] as? Int
                    == portableLayout.bitsPerBlock
            )
            #expect(
                appleDictionary["BitsPerComponent"] as? Int
                    == portableLayout.bitsPerComponent
            )
            #expect(
                ((appleDictionary["BlockWidth"] as? Int) ?? 1)
                    == portableLayout.blockSize.width
            )
            #expect(
                ((appleDictionary["BlockHeight"] as? Int) ?? 1)
                    == portableLayout.blockSize.height
            )
            #expect(
                ((appleDictionary["BlockHorizontalAlignment"] as? Int) ?? 1)
                    == portableLayout.blockAlignment.horizontal
            )
            #expect(
                ((appleDictionary["BlockVerticalAlignment"] as? Int) ?? 1)
                    == portableLayout.blockAlignment.vertical
            )
            #expect(
                ((appleDictionary["HorizontalSubsampling"] as? Int) ?? 1)
                    == portableLayout.subsampling.horizontal
            )
            #expect(
                ((appleDictionary["VerticalSubsampling"] as? Int) ?? 1)
                    == portableLayout.subsampling.vertical
            )
            compareBlackBlock(
                appleDictionary["BlackBlock"] as? Data,
                portableLayout.blackBlock
            )
        }
    }

    private func componentRangeName(
        _ range: OpenCoreVideo.CVPixelFormatDescription.ComponentRange?
    ) -> String? {
        switch range {
        case .full: return "FullRange"
        case .video: return "VideoRange"
        case .wide: return "WideRange"
        case nil: return nil
        }
    }

    private func compareBlackBlock(
        _ apple: Data?,
        _ portable: [UInt8]?
    ) {
        guard let apple else {
            #expect(portable == nil)
            return
        }
        #expect(Array(apple) == portable)
    }
}
#endif
