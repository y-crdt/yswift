import Foundation
import Yniffi

public final class YText {
    private let _text: YrsText
    private let document: YDocument
    
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    internal init(text: YrsText, document: YDocument) {
        self._text = text
        self.document = document
    }

    public func append(text: String, transaction: YrsTransaction? = nil) {
        inTransaction(transaction) { txn in
            self._text.append(tx: txn, text: text)
        }
    }
    
    public func insert(at index: UInt32, text: String, transaction: YrsTransaction? = nil) {
        inTransaction(transaction) { txn in
            self._text.insert(tx: txn, index: index, chunk: text)
        }
    }
    
    public func insertWithAttributes<T: Encodable>(at index: UInt32, text: String, attributes: [String: T], transaction: YrsTransaction? = nil) {
        inTransaction(transaction) { txn in
            self._text.insertWithAttributes(tx: txn, index: index, chunk: text, attrs: self.encodedMap(attributes))
        }
    }
    
    public func insertEmbed<T: Encodable>(at index: UInt32, embed: T, transaction: YrsTransaction? = nil) {
        inTransaction(transaction) { txn in
            self._text.insertEmbed(tx: txn, index: index, content: self.encoded(embed))
        }
    }

    public func insertEmbedWithAttributes<T: Encodable, R: Encodable>(at index: UInt32, embed: T, attributes: [String: R], transaction: YrsTransaction? = nil) {
        inTransaction(transaction) { txn in
            self._text.insertEmbedWithAttributes(tx: txn, index: index, content: self.encoded(embed), attrs: self.encodedMap(attributes))
        }
    }
    
    public func format<T: Encodable>(at index: UInt32, length: UInt32, attributes: [String: T], transaction: YrsTransaction? = nil) {
        inTransaction(transaction) { txn in
            self._text.format(tx: txn, index: index, length: length, attrs: self.encodedMap(attributes))
        }
    }
    
    public func removeRange(start: UInt32, length: UInt32, transaction: YrsTransaction? = nil) {
        inTransaction(transaction) { txn in
            self._text.removeRange(tx: txn, start: start, length: length)
        }
    }

    public func getString(transaction: YrsTransaction? = nil) -> String {
        inTransaction(transaction) { txn in
            self._text.getString(tx: txn)
        }
    }

    public func length(transaction: YrsTransaction? = nil) -> UInt32 {
        inTransaction(transaction) { txn in
            self._text.length(tx: txn)
        }
    }

    public func observe(_ body: @escaping ([YrsDelta]) -> Void) -> UInt32 {
        let delegate = YTextObservationDelegate(callback: body)
        return _text.observe(delegate: delegate)
    }

    public func unobserve(_ subscriptionId: UInt32) {
        _text.unobserve(subscriptionId: subscriptionId)
    }

    private func encoded<T: Encodable>(_ value: T) -> String {
        let data = try! encoder.encode(value)
        return String(data: data, encoding: .utf8)!
    }

    private func encodedMap<T: Encodable>(_ value: [String: T]) -> [String: String] {
        Dictionary(uniqueKeysWithValues: value.map { ($0, encoded($1)) })
    }
    
    private func inTransaction<T>(_ transaction: YrsTransaction?, changes: @escaping (YrsTransaction) -> T) -> T {
        if let transaction = transaction {
            return changes(transaction)
        } else {
            return document.transact(changes)
        }
    }
}

internal class YTextObservationDelegate: YrsTextObservationDelegate {
    private var callback: ([YrsDelta]) -> Void

    internal init(callback: @escaping ([YrsDelta]) -> Void) {
        self.callback = callback
    }

    internal func call(value: [YrsDelta]) {
        callback(value)
    }
}
