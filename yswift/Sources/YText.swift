import Foundation
import Yniffi

public final class YText {
    private let _text: YrsText
    
    public init(text: YrsText) {
        _text = text
    }
    
    func append(tx: YrsTransaction, text: String) {
        _text.append(tx: tx, text: text)
    }
    
    func insert(tx: YrsTransaction, index: UInt32, chunk: String) {
        _text.insert(tx: tx, index: index, chunk: chunk)
    }
    
    func removeRange(tx: YrsTransaction, start: UInt32, length: UInt32) {
        _text.removeRange(tx: tx, start: start, length: length)
    }
    
    func getString(tx: YrsTransaction) -> String {
        _text.getString(tx: tx)
    }
    

    func length(tx: YrsTransaction) -> UInt32 {
        _text.length(tx: tx)
    }
    
    func observe(_ body: @escaping ([YrsDelta]) -> Void) -> UInt32 {
        let delegate = YTextObservationDelegate(callback: body)
        return _text.observe(delegate: delegate)
    }
    
    func unobserve(_ subscriptionId: UInt32) {
        _text.unobserve(subscriptionId: subscriptionId)
    }
}

class YTextObservationDelegate: YrsTextObservationDelegate {
    private var callback: ([YrsDelta]) -> Void
    
    init(callback: @escaping ([YrsDelta]) -> Void) {
        self.callback = callback
    }

    func call(value: [YrsDelta]) {
        callback(value)
    }
}

