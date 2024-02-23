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
    
    public func undo() throws -> Bool {
        return _manager.undo()
    }
    
    public func redo() throws -> Bool {
        return _manager.redo()
    }
    
    public func wrap() {
        _manager.wrapChanges()
    }
    
    public func clear() throws {
        _manager.clear()
    }
}
