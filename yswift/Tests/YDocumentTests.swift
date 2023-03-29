import Foundation
import XCTest
@testable import YSwift

class YDocumentTests: XCTestCase {
    
//    func test_nestedTransactionCall() {
//        let document = YDocument()
//        let someText = document.getOrCreateText(named: "example")
//
//        document.transact { txn1 in
//            someText.append(tx: txn1, text: "123")
//            document.transact { txn2 in
//                someText.append(tx: txn2, text: "asd")
//            }
//        }
//    }
    
    func test_localAndRemoteSyncing() {
        let localDocument = YDocument()
        let localText = localDocument.getOrCreateText(named: "example")
        localDocument.transact { txn in
            localText.append(text: "hello, world!", transaction: txn)
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
            localText.getString(transaction: txn)
        }

        let remoteString = remoteDocument.transact { txn in
            remoteText.getString(transaction: txn)
        }

        XCTAssertEqual(localString, remoteString)
    }

    func test_localAndRemoteEditingAndSyncing() {
        let localDocument = YDocument()
        let localText = localDocument.getOrCreateText(named: "example")
        localDocument.transact { txn in
            localText.append(text: "hello, world!", transaction: txn)
        }

        let remoteDocument = YDocument()
        let remoteText = remoteDocument.getOrCreateText(named: "example")
        remoteDocument.transact { txn in
            remoteText.append(text: "123456", transaction: txn)
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
            localText.getString(transaction: txn)
        }

        let remoteString = remoteDocument.transact { txn in
            remoteText.getString(transaction: txn)
        }

        XCTAssertEqual(localString, remoteString)
    }
}
