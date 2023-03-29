import Foundation
import XCTest
@testable import YSwift

class YDocumentTests: XCTestCase {
    func test_localAndRemoteSyncing() {
        let localDocument = YDocument()
        let localText = localDocument.getOrCreateText(named: "example")
        localDocument.transact { txn in
            localText.append(tx: txn, text: "hello, world!")
        }

        let remoteDocument = YDocument()
        let remoteText = remoteDocument.getOrCreateText(named: "example")

        let remoteState = remoteDocument.transact { txn in
            txn.transactionStateVector()
        }
        let updateRemote = localDocument.transact { txn in
            localDocument.diff(txn: txn, from: remoteState)
        }
        remoteDocument.transact { txn in
            try! txn.transactionApplyUpdate(update: updateRemote)
        }

        let localString = localDocument.transact { txn in
            localText.getString(tx: txn)
        }

        let remoteString = remoteDocument.transact { txn in
            remoteText.getString(tx: txn)
        }

        XCTAssertEqual(localString, remoteString)
    }

    func test_localAndRemoteEditingAndSyncing() {
        let localDocument = YDocument()
        let localText = localDocument.getOrCreateText(named: "example")
        localDocument.transact { txn in
            localText.append(tx: txn, text: "hello, world!")
        }

        let remoteDocument = YDocument()
        let remoteText = remoteDocument.getOrCreateText(named: "example")
        remoteDocument.transact { txn in
            remoteText.append(tx: txn, text: "123456")
        }

        let remoteState = remoteDocument.transact { txn in
            txn.transactionStateVector()
        }
        let updateRemote = localDocument.transact { txn in
            localDocument.diff(txn: txn, from: remoteState)
        }
        remoteDocument.transact { txn in
            try! txn.transactionApplyUpdate(update: updateRemote)
        }

        let localState = localDocument.transact { txn in
            txn.transactionStateVector()
        }
        let updateLocal = remoteDocument.transact { txn in
            localDocument.diff(txn: txn, from: localState)
        }
        localDocument.transact { txn in
            try! txn.transactionApplyUpdate(update: updateLocal)
        }

        let localString = localDocument.transact { txn in
            localText.getString(tx: txn)
        }

        let remoteString = remoteDocument.transact { txn in
            remoteText.getString(tx: txn)
        }

        XCTAssertEqual(localString, remoteString)
    }
}
