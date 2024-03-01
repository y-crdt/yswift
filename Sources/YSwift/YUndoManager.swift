import Combine
import Foundation
import Yniffi

public final class YUndoManager {
    private let _manager: YrsUndoManager
    
    init(manager: YrsUndoManager) {
        _manager = manager
    }
    
    public func addOrigin<O>(_ origin: O) where O: OriginProtocol {
        _manager.addOrigin(origin: origin.asOrigin())
    }
    
    public func removeOrigin<O>(_ origin: O) where O: OriginProtocol {
        _manager.removeOrigin(origin: origin.asOrigin())
    }
    
    public func track(_ collection: YCollection) {
        _manager.addScope(trackedRef: collection.sharedHandle())
    }
    
    public func undo() throws -> Bool {
        return try _manager.undo()
    }
    
    public func redo() throws -> Bool {
        return try _manager.redo()
    }
    
    public func wrap() {
        _manager.wrapChanges()
    }
    
    public func clear() throws {
        try _manager.clear()
    }
    
    public func observeAdded(_ body: (YrsUndoEvent, AnyObject?) -> AnyObject?) -> UInt32 {
        let delegate = YUndoManager.createDelegate(body)
        return _manager.observeAdded(delegate: delegate)
    }

    public func unobserveAdded(_ subscriptionId: UInt32) {
        return _manager.unobserveAdded(subscriptionId: subscriptionId)
    }
    
    public func observeUpdated(_ body: (YrsUndoEvent, AnyObject?) -> AnyObject?) -> UInt32 {
        let delegate = YUndoManager.createDelegate(body)
        return _manager.observeUpdated(delegate: delegate)
    }

    public func unobserveUpdated(_ subscriptionId: UInt32) {
        return _manager.unobserveUpdated(subscriptionId: subscriptionId)
    }
    
    public func observePopped(_ body: (YrsUndoEvent, AnyObject?) -> AnyObject?) -> UInt32 {
        let delegate = YUndoManager.createDelegate(body)
        return _manager.observePopped(delegate: delegate)
    }

    public func unobservePopped(_ subscriptionId: UInt32) {
        return _manager.unobservePopped(subscriptionId: subscriptionId)
    }
    
    static func createDelegate(_ body: (YrsUndoEvent, AnyObject?) -> AnyObject?) -> YrsUndoManagerObservationDelegate {
        let callback = { (event: YrsUndoEvent, ptr: UInt64) -> UInt64 in
            let obj = body(event, bridge(ptr: ptr))
            return bridge(obj: obj)
        }
        return YrsUndoManagerObservationDelegate(callback: callback, decoded: Coder.decodedArray)
    }
}

func bridge(obj : AnyObject?) -> UInt64 {
    if let obj {
        let ptr = UnsafeRawPointer(Unmanaged.passRetained(obj).toOpaque())
        return UInt64(bitPattern: Int64(Int(bitPattern: ptr)))
    } else {
        return UInt64(bitPattern: Int64(Int(bitPattern: nil)))
    }
}

func bridge(ptr : UInt64) -> AnyObject? {
    let unsafe_ptr = UnsafeRawPointer(bitPattern: Int(ptr))
    if let unsafe_ptr {
        return Unmanaged.fromOpaque(unsafe_ptr).takeRetainedValue()
    } else {
        return nil
    }
}
