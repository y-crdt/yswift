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
    
    public func insertWithAttributes(
        _ text: String,
        attributes: [String: Any],
        at index: UInt32,
        in transaction: YrsTransaction? = nil
    ) {
        inTransaction(transaction) { txn in
            self._text.insertWithAttributes(tx: txn, index: index, chunk: text, attrs: Coder.encoded(attributes))
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

    public func insertEmbedWithAttributes<T: Encodable>(
        _ embed: T,
        attributes: [String: Any],
        at index: UInt32,
        in transaction: YrsTransaction? = nil
    ) {
        inTransaction(transaction) { txn in
            self._text.insertEmbedWithAttributes(tx: txn, index: index, content: Coder.encoded(embed), attrs: Coder.encoded(attributes))
        }
    }
    
    public func format(
        at index: UInt32,
        length: UInt32,
        attributes: [String: Any],
        in transaction: YrsTransaction? = nil
    ) {
        inTransaction(transaction) { txn in
            self._text.format(tx: txn, index: index, length: length, attrs: Coder.encoded(attributes))
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

    public func observe(_ callback: @escaping ([YTextChange]) -> Void) -> UInt32 {
        _text.observe(
            delegate: YTextObservationDelegate(
                callback: callback,
                decoded: Coder.decoded(_:)
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
    private var callback: ([YTextChange]) -> Void
    private var decoded: (String) -> [String: Any]

    internal init(
        callback: @escaping ([YTextChange]) -> Void,
        decoded: @escaping (String) -> [String: Any]
    ) {
        self.callback = callback
        self.decoded = decoded
    }

    internal func call(value: [YrsDelta]) {
        let result: [YTextChange] = value.map { rsChange -> YTextChange in
            switch rsChange {
            case let .inserted(value, attrs):
                return YTextChange.inserted(value: value, attributes: decoded(attrs))
            case let .retained(index, attrs):
                return YTextChange.retained(index: index, attributes: decoded(attrs))
            case let .deleted(index):
                return YTextChange.deleted(index: index)
            }
            
        }
        callback(result)
    }
}

public enum YTextChange {
    case inserted(value: String, attributes: [String: Any])
    case deleted(index: UInt32)
    case retained(index: UInt32, attributes: [String: Any])
}

