import Foundation
import Yniffi

public final class YText {
    private let _text: YrsText
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    public init(text: YrsText) {
        _text = text
    }

    func append(tx: YrsTransaction, text: String) {
        _text.append(tx: tx, text: text)
    }

    func insert(tx: YrsTransaction, index: UInt32, chunk: String) {
        _text.insert(tx: tx, index: index, chunk: chunk)
    }

    func insertWithAttributes<T: Encodable>(tx: YrsTransaction, index: UInt32, chunk: String, attrs: [String: T]) {
        _text.insertWithAttributes(tx: tx, index: index, chunk: chunk, attrs: encodedMap(attrs))
    }

    func format<T: Encodable>(tx: YrsTransaction, index: UInt32, length: UInt32, attrs: [String: T]) {
        _text.format(tx: tx, index: index, length: length, attrs: encodedMap(attrs))
    }

    func insertEmbed<T: Encodable>(tx: YrsTransaction, index: UInt32, content: T) {
        _text.insertEmbed(tx: tx, index: index, content: encoded(content))
    }

    func insertEmbedWithAttributes<T: Encodable, R: Encodable>(tx: YrsTransaction, index: UInt32, content: T, attrs: [String: R]) {
        _text.insertEmbedWithAttributes(tx: tx, index: index, content: encoded(content), attrs: encodedMap(attrs))
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

    private func encoded<T: Encodable>(_ value: T) -> String {
        let data = try! encoder.encode(value)
        return String(data: data, encoding: .utf8)!
    }

    private func encodedMap<T: Encodable>(_ value: [String: T]) -> [String: String] {
        Dictionary(uniqueKeysWithValues: value.map { ($0, encoded($1)) })
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
