import Foundation
import XCTest
@testable import YSwift

class YDocumentTests: XCTestCase {
    func test_memoryLeaks() {
        let document = YDocument()
        let array: YArray<String> = document.getOrCreateArray(named: "array")
        let map: YMap<String> = document.getOrCreateMap(named: "map")
        let text: YText = document.getOrCreateText(named: "text")

        trackForMemoryLeaks(array)
        trackForMemoryLeaks(map)
        trackForMemoryLeaks(text)
        trackForMemoryLeaks(document)
    }

    func test_localAndRemoteSyncing() {
        let localDocument = YDocument()
        let localText = localDocument.getOrCreateText(named: "example")
        localDocument.transactSync { txn in
            localText.append("hello, world!", in: txn)
        }

        let remoteDocument = YDocument()
        let remoteText = remoteDocument.getOrCreateText(named: "example")

        let remoteState = remoteDocument.transactSync { txn in
            txn.transactionStateVector()
        }
        let updateRemote = localDocument.transactSync { txn in
            localDocument.diff(txn: txn, from: remoteState)
        }
        remoteDocument.transactSync { txn in
            try! txn.transactionApplyUpdate(update: updateRemote)
        }

        let localString = localDocument.transactSync { txn in
            localText.getString(in: txn)
        }

        let remoteString = remoteDocument.transactSync { txn in
            remoteText.getString(in: txn)
        }

        XCTAssertEqual(localString, remoteString)
    }

    func test_localAndRemoteEditingAndSyncing() {
        let localDocument = YDocument()
        let localText = localDocument.getOrCreateText(named: "example")
        localDocument.transactSync { txn in
            localText.append("hello, world!", in: txn)
        }

        let remoteDocument = YDocument()
        let remoteText = remoteDocument.getOrCreateText(named: "example")
        remoteDocument.transactSync { txn in
            remoteText.append("123456", in: txn)
        }

        let remoteState = remoteDocument.transactSync { txn in
            txn.transactionStateVector()
        }
        let updateRemote = localDocument.transactSync { txn in
            localDocument.diff(txn: txn, from: remoteState)
        }
        remoteDocument.transactSync { txn in
            try! txn.transactionApplyUpdate(update: updateRemote)
        }

        let localState = localDocument.transactSync { txn in
            txn.transactionStateVector()
        }
        let updateLocal = remoteDocument.transactSync { txn in
            localDocument.diff(txn: txn, from: localState)
        }
        localDocument.transactSync { txn in
            try! txn.transactionApplyUpdate(update: updateLocal)
        }

        let localString = localDocument.transactSync { txn in
            localText.getString(in: txn)
        }

        let remoteString = remoteDocument.transactSync { txn in
            remoteText.getString(in: txn)
        }

        XCTAssertEqual(localString, remoteString)
    }
}
