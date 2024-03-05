import Combine
import Foundation
import Yniffi

public final class YUndoManager<T: AnyObject> {
    private let _manager: YrsUndoManager
    
    init(manager: YrsUndoManager) {
        _manager = manager
    }
    
    public func addOrigin(_ origin: Origin) {
        _manager.addOrigin(origin: origin.origin)
    }
    
    public func removeOrigin(_ origin: Origin) {
        _manager.removeOrigin(origin: origin.origin)
    }
    
    public func track(_ collection: YCollection) {
        _manager.addScope(trackedRef: collection.pointer())
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
    
    public func observeAdded(_ body: @escaping (UndoEvent, T?) -> T?) -> UInt32 {
        let delegate = YUndoManagerObservationDelegate(callback: body)
        return _manager.observeAdded(delegate: delegate)
    }

    public func unobserveAdded(_ subscriptionId: UInt32) {
        return _manager.unobserveAdded(subscriptionId: subscriptionId)
    }
    
    public func observeUpdated(_ body: @escaping (UndoEvent, T?) -> T?) -> UInt32 {
        let delegate = YUndoManagerObservationDelegate(callback: body)
        return _manager.observeUpdated(delegate: delegate)
    }

    public func unobserveUpdated(_ subscriptionId: UInt32) {
        return _manager.unobserveUpdated(subscriptionId: subscriptionId)
    }
    
    public func observePopped(_ body: @escaping (UndoEvent, T?) -> T?) -> UInt32 {
        let delegate = YUndoManagerObservationDelegate(callback: body)
        return _manager.observePopped(delegate: delegate)
    }

    public func unobservePopped(_ subscriptionId: UInt32) {
        return _manager.unobservePopped(subscriptionId: subscriptionId)
    }
}

class YUndoManagerObservationDelegate<T: AnyObject>: YrsUndoManagerObservationDelegate {
    private var callback: (YrsUndoEvent, UInt64) -> UInt64

    init(callback: @escaping (UndoEvent, T?) -> T?) {
        self.callback = { (event: YrsUndoEvent, ptr: UInt64) -> UInt64 in
            let obj = callback(UndoEvent(event), YUndoManagerObservationDelegate.bridge(ptr: ptr))
            return YUndoManagerObservationDelegate.bridge(obj: obj)
        }
    }

    func call(e: Yniffi.YrsUndoEvent, ptr: UInt64) -> UInt64 {
        return self.callback(e, ptr)
    }
    
    static func bridge(obj : T?) -> UInt64 {
        if let obj {
            let ptr = UnsafeRawPointer(Unmanaged.passRetained(obj).toOpaque())
            return UInt64(bitPattern: Int64(Int(bitPattern: ptr)))
        } else {
            return UInt64(bitPattern: Int64(Int(bitPattern: nil)))
        }
    }

    static func bridge(ptr : UInt64) -> T? {
        let unsafe_ptr = UnsafeRawPointer(bitPattern: Int(ptr))
        if let unsafe_ptr {
            return Unmanaged.fromOpaque(unsafe_ptr).takeRetainedValue()
        } else {
            return nil
        }
    }
}

public struct UndoEvent {
    let event: YrsUndoEvent
    init(_ event: YrsUndoEvent) {
        self.event = event
    }
    
    var type: YrsUndoEventKind {
        get {
            return self.event.kind()
        }
    }
    
    var origin: Origin? {
        get {
            let origin = self.event.origin()
            if let origin {
                return Origin(origin)
            } else {
                return nil
            }
        }
    }
    
    func hasChanged<T: YCollection>(_ sharedRef: T) -> Bool {
        return self.event.hasChanged(sharedRef: sharedRef.pointer())
    }
}
