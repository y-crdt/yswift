import Yniffi

/// A type that contains a reference to Yrs shared collection type.
public protocol YCollection {
    func sharedHandle() -> YrsSharedRef;
}


public protocol OriginProtocol {
    //TODO: this should be fine for any type representable and comparable as [UInt8]
    func asOrigin() -> Origin;
}

extension String: OriginProtocol {
    public func asOrigin() -> Origin {
        
    }
}

extension UInt8: OriginProtocol {
    public func asOrigin() -> Origin {
        
    }
}

extension UInt16: OriginProtocol {
    public func asOrigin() -> Origin {
        <#code#>
    }
}

extension UInt32: OriginProtocol {
    public func asOrigin() -> Origin {
        <#code#>
    }
}

extension UInt64: OriginProtocol {
    public func asOrigin() -> Origin {
        <#code#>
    }
}

extension Int8: OriginProtocol {
    public func asOrigin() -> Origin {
        <#code#>
    }
}

extension Int16: OriginProtocol {
    public func asOrigin() -> Origin {
        <#code#>
    }
}

extension Int32: OriginProtocol {
    public func asOrigin() -> Origin {
        <#code#>
    }
}

extension Int64: OriginProtocol {
    public func asOrigin() -> Origin {
        <#code#>
    }
}
