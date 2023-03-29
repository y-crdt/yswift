import Foundation

/*
 Note: This is a very-very-very WIP implementation of y-protocol.
 See https://github.com/yjs/y-protocols/blob/master/PROTOCOL.md
 */

public struct YSyncMessage: Codable {
    public let kind: Kind
    public let buffer: Buffer

    public init(kind: YSyncMessage.Kind, buffer: Buffer) {
        self.kind = kind
        self.buffer = buffer
    }

    public enum Kind: Int, Codable {
        case STEP_1 = 0
        case STEP_2 = 1
        case UPDATE = 2
    }
}

public typealias Buffer = [UInt8]

public final class YProtocol {
    private let document: YDocument

    public init(document: YDocument) {
        self.document = document
    }

    public func handleConnectionStarted() -> YSyncMessage {
        return sendStep1()
    }

    public func handleStep1(_ stateVector: Buffer) -> YSyncMessage {
        let update = document.transactSync { txn in
            try! txn.transactionEncodeStateAsUpdateFromSv(stateVector: stateVector)
        }
        return sendStep2(update)
    }

    public func handleStep2(_ update: Buffer, completionHandler: @escaping () -> Void) {
        document.transactSync { txn in
            try! txn.transactionApplyUpdate(update: update)
        }
        completionHandler()
    }

    public func handleUpdate(_ update: Buffer, completionHandler: @escaping () -> Void) {
        handleStep2(update, completionHandler: completionHandler)
    }

    func sendStep1() -> YSyncMessage {
        let stateVector: Buffer = document.transactSync { txn in
            txn.transactionStateVector()
        }
        return YSyncMessage(kind: .STEP_1, buffer: stateVector)
    }

    func sendStep2(_ update: Buffer) -> YSyncMessage {
        YSyncMessage(kind: .STEP_2, buffer: update)
    }

    func sendUpdate(_ update: Buffer) -> YSyncMessage {
        YSyncMessage(kind: .UPDATE, buffer: update)
    }
}
