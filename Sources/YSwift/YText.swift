import Combine
import Foundation
import Yniffi

/// A type that provides a text-oriented shared data type.
///
/// Create a new `YText` instance using ``YSwift/YDocument/getOrCreateText(named:)`` from a ``YDocument``.
public final class YText: Transactable, YCollection {
    private let _text: YrsText
    let document: YDocument

    init(text: YrsText, document: YDocument) {
        _text = text
        self.document = document
    }

    /// Appends a string you provide to the shared text data type.
    /// - Parameters:
    ///   - text: The string to append.
    ///   - transaction: An optional transaction to use when appending the string.
    public func append(_ text: String, in transaction: YrsTransaction? = nil) {
        if let transaction {
            self._text.append(tx: transaction, text: text)
        } else {
            withTransaction(transaction) { txn in
                self._text.append(tx: txn, text: text)
            }
        }
    }

    /// Inserts a string at an index position you provide.
    /// - Parameters:
    ///   - text: The string to insert.
    ///   - index: The position, within the UTF-8 buffer view, to insert the string.
    ///   - transaction: An optional transaction to use when appending the string.
    public func insert(
        _ text: String,
        at index: UInt32,
        in transaction: YrsTransaction? = nil
    ) {
        if let transaction {
            self._text.insert(tx: transaction, index: index, chunk: text)
        } else {
            withTransaction(transaction) { txn in
                self._text.insert(tx: txn, index: index, chunk: text)
            }
        }
    }

    /// Inserts a string, with attributes, at an index position you provide.
    /// - Parameters:
    ///   - text: The string to insert.
    ///   - attributes: The attributes to associate with the appended string.
    ///   - index: The position, within the UTF-8 buffer view, to insert the string.
    ///   - transaction: An optional transaction to use when appending the string.
    public func insertWithAttributes(
        _ text: String,
        attributes: [String: Any],
        at index: UInt32,
        in transaction: YrsTransaction? = nil
    ) {
        if let transaction {
            self._text.insertWithAttributes(tx: transaction, index: index, chunk: text, attrs: Coder.encoded(attributes))
        } else {
            withTransaction(transaction) { txn in
                self._text.insertWithAttributes(tx: txn, index: index, chunk: text, attrs: Coder.encoded(attributes))
            }
        }
    }

    /// Embeds a Codable type you provide within the text at the location you provide.
    /// - Parameters:
    ///   - embed: The codable type to embed.
    ///   - index: The position, within the UTF-8 buffer view, to embed the object.
    ///   - transaction: An optional transaction to use when appending the string.
    public func insertEmbed<T: Encodable>(
        _ embed: T,
        at index: UInt32,
        in transaction: YrsTransaction? = nil
    ) {
        if let transaction {
            self._text.insertEmbed(tx: transaction, index: index, content: Coder.encoded(embed))
        } else {
            withTransaction(transaction) { txn in
                self._text.insertEmbed(tx: txn, index: index, content: Coder.encoded(embed))
            }
        }
    }

    /// Embeds a Codable type you provide within the text at the location you provide.
    /// - Parameters:
    ///   - embed: The codable type to embed.
    ///   - attributes: The attributes to associate with the embedded type.
    ///   - index: The position, within the UTF-8 buffer view, to embed the object.
    ///   - transaction: An optional transaction to use when appending the string.
    public func insertEmbedWithAttributes<T: Encodable>(
        _ embed: T,
        attributes: [String: Any],
        at index: UInt32,
        in transaction: YrsTransaction? = nil
    ) {
        if let transaction {
            self._text.insertEmbedWithAttributes(tx: transaction, index: index, content: Coder.encoded(embed), attrs: Coder.encoded(attributes))
        } else {
            withTransaction(transaction) { txn in
                self._text.insertEmbedWithAttributes(tx: txn, index: index, content: Coder.encoded(embed), attrs: Coder.encoded(attributes))
            }
        }
    }

    /// Applies or updates attributes associated with a range of the string.
    /// - Parameters:
    ///   - index: The index position, in the UTF-8 view of the string, to start formatting characters.
    ///   - length: The length of characters to update.
    ///   - attributes: The attributes to associate with the string.
    ///   - transaction: An optional transaction to use when appending the string.
    public func format(
        at index: UInt32,
        length: UInt32,
        attributes: [String: Any],
        in transaction: YrsTransaction? = nil
    ) {
        if let transaction {
            self._text.format(tx: transaction, index: index, length: length, attrs: Coder.encoded(attributes))
        } else {
            withTransaction(transaction) { txn in
                self._text.format(tx: txn, index: index, length: length, attrs: Coder.encoded(attributes))
            }
        }
    }

    /// Removes a range of text starting at a position you provide, removing the length that you provide.
    /// - Parameters:
    ///   - start: The index position, in the UTF-8 view of the string, to start removing characters.
    ///   - length: The length of characters to remove.
    ///   - transaction: An optional transaction to use when appending the string.
    public func removeRange(
        start: UInt32,
        length: UInt32,
        in transaction: YrsTransaction? = nil
    ) {
        if let transaction {
            self._text.removeRange(tx: transaction, start: start, length: length)
        } else {
            withTransaction(transaction) { txn in
                self._text.removeRange(tx: txn, start: start, length: length)
            }
        }
    }

    /// Returns the string within the text.
    /// - Parameter transaction: An optional transaction to use when appending the string.
    public func getString(in transaction: YrsTransaction? = nil) -> String {
        if let transaction {
            self._text.getString(tx: transaction)
        } else {
            withTransaction(transaction) { txn in
                self._text.getString(tx: txn)
            }
        }
    }

    /// Returns the length of the string.
    /// - Parameter transaction: An optional transaction to use when appending the string.
    public func length(in transaction: YrsTransaction? = nil) -> UInt32 {
        if let transaction {
            self._text.length(tx: transaction)
        } else {
            withTransaction(transaction) { txn in
                self._text.length(tx: txn)
            }
        }
    }

    /// Returns a publisher of changes for the text.
    public func observe() -> AnyPublisher<[YTextChange], Never> {
        let subject = PassthroughSubject<[YTextChange], Never>()
        let subscription = observe { subject.send($0) }
        return subject.handleEvents(receiveCancel: {
            subscription.cancel()
        })
        .eraseToAnyPublisher()
    }

    /// Registers a closure that is called with an array of changes to the text.
    /// - Parameter callback: The closure to process reported changes from the text.
    /// - Returns: An observer identifier that you can use to stop observing the text.
    public func observe(_ callback: @escaping ([YTextChange]) -> Void) -> YSubscription {
        YSubscription(
            subscription: _text.observe(
                delegate: YTextObservationDelegate(
                    callback: callback,
                    decoded: Coder.decoded(_:)
                )
            )
        )
    }
    
    public func pointer() -> YrsCollectionPtr {
        return _text.rawPtr()
    }
}

extension YText: Equatable {
    /// Returns a Boolean value that indicates whether the text values are identical.
    /// - Parameters:
    ///   - lhs: The first text type
    ///   - rhs: The second text type
    /// - Returns: Returns `true` if the text is identical, irrespective of attributes, otherwise false.
    public static func == (lhs: YText, rhs: YText) -> Bool {
        lhs.getString() == rhs.getString()
    }
}

public extension String {
    init(_ yText: YText) {
        self = yText.getString()
    }
}

extension YText: CustomStringConvertible {
    /// Returns the current string within the text.
    public var description: String {
        getString()
    }
}

class YTextObservationDelegate: YrsTextObservationDelegate {
    private var callback: ([YTextChange]) -> Void
    private var decoded: (String) -> [String: Any]

    init(
        callback: @escaping ([YTextChange]) -> Void,
        decoded: @escaping (String) -> [String: Any]
    ) {
        self.callback = callback
        self.decoded = decoded
    }

    func call(value: [YrsDelta]) {
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

/// A change to the text or attributes associated with the text.
public enum YTextChange {
    /// Inserted string,and any associated attributes.
    case inserted(value: String, attributes: [String: Any])
    /// Deleted characters.
    case deleted(index: UInt32)
    /// Updated character position and any associated attributes.
    case retained(index: UInt32, attributes: [String: Any])
}
