import Foundation

/// X block parity used for Hires preview (editor display metadata).
public enum XParityDisplay: String, Codable, Sendable {
    case even
    case odd

    public var xBlock: Int { self == .even ? 0 : 1 }
    public var label: String { self == .even ? "Even" : "Odd" }
}
