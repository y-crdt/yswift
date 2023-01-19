import Foundation
import XCTest
import YNativeFinal
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
}
