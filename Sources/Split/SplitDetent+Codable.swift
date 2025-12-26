import Foundation

extension SplitDetent: Codable {
    enum CodingKeys: String, CodingKey {
        case type, value
    }

    enum DetentType: String, Codable {
        case small, medium, large, fraction, length
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch id {
        case .small:
            try container.encode(DetentType.small, forKey: .type)
        case .medium:
            try container.encode(DetentType.medium, forKey: .type)
        case .large:
            try container.encode(DetentType.large, forKey: .type)
        case .fraction(let fraction):
            try container.encode(DetentType.fraction, forKey: .type)
            try container.encode(fraction.fraction, forKey: .value)
        case .length(let length):
            try container.encode(DetentType.length, forKey: .type)
            try container.encode(length.length, forKey: .value)
        case .custom:
            throw EncodingError.invalidValue(self,
                EncodingError.Context(codingPath: encoder.codingPath,
                    debugDescription: "Custom detents cannot be encoded"))
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(DetentType.self, forKey: .type)

        switch type {
        case .small:
            self = .small
        case .medium:
            self = .medium
        case .large:
            self = .large
        case .fraction:
            let value = try container.decode(CGFloat.self, forKey: .value)
            self = .fraction(value)
        case .length:
            let value = try container.decode(CGFloat.self, forKey: .value)
            self = .length(value)
        }
    }
}

extension SplitDetent: RawRepresentable {
    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let string = String(data: data, encoding: .utf8) else {
            return ""
        }
        return string
    }

    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let detent = try? JSONDecoder().decode(SplitDetent.self, from: data) else {
            return nil
        }
        self = detent
    }
}
