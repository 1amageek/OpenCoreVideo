extension CVPixelFormatDescription {
    public final class Registry: Sendable {
        private struct State: Sendable {
            var descriptions: [CVPixelFormatDescription]
        }

        public static let shared = Registry(
            descriptions: CVPixelFormatDescription.standardDescriptions
        )

        private let state: CVStateLock<State>

        public init(descriptions: [CVPixelFormatDescription] = []) {
            self.state = CVStateLock(State(descriptions: []))
            for description in descriptions {
                register(description)
            }
        }

        public var formatDescriptions: [CVPixelFormatDescription] {
            state.withLock { $0.descriptions }
        }

        public subscript(
            pixelFormatType: CVPixelFormatType
        ) -> CVPixelFormatDescription? {
            let descriptions = state.withLock { $0.descriptions }
            return descriptions.first {
                $0.pixelFormatType == pixelFormatType
            }
        }

        public func register(
            _ formatDescription: CVPixelFormatDescription
        ) {
            state.withLock { state in
                if let index = state.descriptions.firstIndex(where: {
                    $0.pixelFormatType
                        == formatDescription.pixelFormatType
                }) {
                    state.descriptions[index] = formatDescription
                } else {
                    state.descriptions.append(formatDescription)
                }
            }
        }
    }
}
