import Foundation
import Yniffi

#warning("@TODO: check if `self` in Transactions is not leaking")
#warning("@TODO: check if strong reference to Document is ok (no retain cycles)")

public final class YText: Transactable {
    private let _text: YrsText
    internal let document: YDocument

    internal init(text: YrsText, document: YDocument) {
        self._text = text
        self.document = document
    }
    
    public func append(_ text: String, in transaction: YrsTransaction? = nil) {
        inTransaction(transaction) { txn in
            self._text.append(tx: txn, text: text)
        }
    }
    
    public func insert(
        _ text: String,
        at index: UInt32,
        in transaction: YrsTransaction? = nil
    ) {
        inTransaction(transaction) { txn in
            self._text.insert(tx: txn, index: index, chunk: text)
        }
    }
    
    public func insertWithAttributes<T: Encodable>(
        _ text: String,
        attributes: [String: T],
        at index: UInt32,
        in transaction: YrsTransaction? = nil
    ) {
        inTransaction(transaction) { txn in
            self._text.insertWithAttributes(tx: txn, index: index, chunk: text, attrs: Coder.encodedDictionary(attributes))
        }
    }
    
    public func insertEmbed<T: Encodable>(
        _ embed: T,
        at index: UInt32,
        in transaction: YrsTransaction? = nil
    ) {
        inTransaction(transaction) { txn in
            self._text.insertEmbed(tx: txn, index: index, content: Coder.encoded(embed))
        }
    }

    public func insertEmbedWithAttributes<T: Encodable, R: Encodable>(
        _ embed: T,
        attributes: [String: R],
        at index: UInt32,
        in transaction: YrsTransaction? = nil
    ) {
        inTransaction(transaction) { txn in
            self._text.insertEmbedWithAttributes(tx: txn, index: index, content: Coder.encoded(embed), attrs: Coder.encodedDictionary(attributes))
        }
    }
    
    public func format<T: Encodable>(
        at index: UInt32,
        length: UInt32,
        attributes: [String: T],
        in transaction: YrsTransaction? = nil
    ) {
        inTransaction(transaction) { txn in
            self._text.format(tx: txn, index: index, length: length, attrs: Coder.encodedDictionary(attributes))
        }
    }
    
    public func removeRange(
        start: UInt32,
        length: UInt32,
        in transaction: YrsTransaction? = nil
    ) {
        inTransaction(transaction) { txn in
            self._text.removeRange(tx: txn, start: start, length: length)
        }
    }

    public func getString(in transaction: YrsTransaction? = nil) -> String {
        inTransaction(transaction) { txn in
            self._text.getString(tx: txn)
        }
    }

    public func length(in transaction: YrsTransaction? = nil) -> UInt32 {
        inTransaction(transaction) { txn in
            self._text.length(tx: txn)
        }
    }

    public func observe(_ callback: @escaping ([YrsDelta]) -> Void) -> UInt32 {
        _text.observe(
            delegate: YTextObservationDelegate(
                callback: callback
            )
        )
    }

    public func unobserve(_ subscriptionId: UInt32) {
        _text.unobserve(subscriptionId: subscriptionId)
    }
}

extension YText: Equatable {
    public static func == (lhs: YText, rhs: YText) -> Bool {
        lhs.getString() == rhs.getString()
    }
}

extension String {
    public init(_ yText: YText) {
        self = yText.getString()
    }
}

extension YText: CustomStringConvertible {
    public var description: String {
        getString()
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
