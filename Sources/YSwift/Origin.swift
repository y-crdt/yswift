import Yniffi

/// A type that contains a reference to Yrs shared collection type.
public protocol YCollection {
    func pointer() -> YrsCollectionPtr
}

/// A struct that identifies the origin of a change.
public struct Origin: Equatable, Codable, Sendable {
    public let origin: YrsOrigin

    init(_ origin: YrsOrigin) {
        self.origin = origin
    }

    init(_ str: String) {
        origin = [UInt8](str.utf8)
    }

    init(_ u: UInt8) {
        origin = [u]
    }

    init(_ u: UInt16) {
        origin = withUnsafeBytes(of: u.bigEndian) { (urbp: UnsafeRawBufferPointer) in
            Array(urbp)
        }
    }

    init(_ u: UInt32) {
        origin = withUnsafeBytes(of: u.bigEndian) { (urbp: UnsafeRawBufferPointer) in
            Array(urbp)
        }
    }

    init(_ u: UInt64) {
        origin = withUnsafeBytes(of: u.bigEndian) { (urbp: UnsafeRawBufferPointer) in
            Array(urbp)
        }
    }

    init(_ u: Int16) {
        origin = withUnsafeBytes(of: u.bigEndian) { (urbp: UnsafeRawBufferPointer) in
            Array(urbp)
        }
    }

    init(_ u: Int32) {
        origin = withUnsafeBytes(of: u.bigEndian) { (urbp: UnsafeRawBufferPointer) in
            Array(urbp)
        }
    }

    init(_ u: Int64) {
        origin = withUnsafeBytes(of: u.bigEndian) { (urbp: UnsafeRawBufferPointer) in
            Array(urbp)
        }
    }
}
