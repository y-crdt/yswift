import Foundation
import XCTest
import Yniffi
@testable import YSwift

class YDocumentTests: XCTestCase {
    /// A real yrs v1 update from `pycrdt.Doc(client_id=967714667641833)` inserting
    /// "hello" into the root text "prompt". The id is above 2^32: yrs 0.18's V1
    /// decoder read client ids into a u32, so this update used to land under a
    /// different, truncated author and silently fork the document. The fork this
    /// package is exists to make this apply under the id that authored it.
    ///   python3 -c "from pycrdt import Doc, Text; d = Doc(client_id=967714667641833); \
    ///     t = d.get('prompt', type=Text); t.insert(0, 'hello'); \
    ///     import base64; print(base64.b64encode(d.get_update()).decode())"
    func test_updateFromA53BitClientIsCreditedToThatClient() {
        let author: UInt64 = 967_714_667_641_833
        let update = [UInt8](Data(base64Encoded: "AQHp94iImoTcAQAEAQZwcm9tcHQFaGVsbG8A")!)
        let document = YDocument()
        let text = document.getOrCreateText(named: "prompt")
        let states: [YrsClientState] = document.transactSync { txn in
            try! txn.transactionApplyUpdate(update: update)
            XCTAssertEqual(text.getString(in: txn), "hello")
            return txn.transactionClientStates()
        }
        XCTAssertEqual(states.map { $0.clientId }, [author], "credited to the 53-bit author, not a u32 of it")
        XCTAssertEqual(states.first?.clock, 5)
    }

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

    // MARK: - diff(from: []) tests
    //
    // Before this fix, calling `diff(txn:from:)` with a literal empty
    // `[UInt8]` state vector (also the default-argument case) panicked
    // inside `Yniffi.YrsDoc.encodeDiffV1` with
    // `Yniffi.CodingError.DecodingError`. After the fix the empty
    // state vector is treated as "diff from nothing" — i.e. the full
    // document state — which is the intuitive semantic.

    /// Fix-case test. After the fix this no longer panics; the
    /// returned bytes synchronise a fresh remote doc to the full
    /// local state.
    func test_diff_fromEmptyStateVector_returnsFullState() {
        let localDocument = YDocument()
        let localText = localDocument.getOrCreateText(named: "example")
        localDocument.transactSync { txn in
            localText.append("hello, world!", in: txn)
        }

        // Empty state vector — explicit and via the default argument.
        let updateFromEmptyExplicit = localDocument.transactSync { txn in
            localDocument.diff(txn: txn, from: [])
        }
        let updateFromDefaultArg = localDocument.transactSync { txn in
            localDocument.diff(txn: txn)
        }

        // The default argument is `from: []`, so the two buffers must
        // be byte-equivalent.
        XCTAssertEqual(updateFromEmptyExplicit, updateFromDefaultArg)

        // Apply to a fresh remote and confirm full state arrives.
        let remoteDocument = YDocument()
        let remoteText = remoteDocument.getOrCreateText(named: "example")
        remoteDocument.transactSync { txn in
            try! txn.transactionApplyUpdate(update: updateFromEmptyExplicit)
        }
        let remoteString = remoteDocument.transactSync { txn in
            remoteText.getString(in: txn)
        }
        XCTAssertEqual(remoteString, "hello, world!")
    }

    /// Equivalence test. The empty-state-vector path should produce
    /// the same bytes as the documented workaround (pair with a fresh
    /// remote doc's `transactionStateVector()`), confirming the fix's
    /// internal synthesis matches what callers were doing manually.
    func test_diff_fromEmptyStateVector_equivalent_to_freshDocStateVector() {
        let localDocument = YDocument()
        let localText = localDocument.getOrCreateText(named: "example")
        localDocument.transactSync { txn in
            localText.append("equivalence check", in: txn)
        }

        let freshRemote = YDocument()
        let freshRemoteSV = freshRemote.transactSync { txn in
            txn.transactionStateVector()
        }

        let updateFromFresh = localDocument.transactSync { txn in
            localDocument.diff(txn: txn, from: freshRemoteSV)
        }
        let updateFromEmpty = localDocument.transactSync { txn in
            localDocument.diff(txn: txn, from: [])
        }

        XCTAssertEqual(updateFromEmpty, updateFromFresh,
                       "diff(from: []) should produce the same bytes as diff(from: freshDoc.transactionStateVector()) — both encode 'full state'")
    }

    /// Regression test. The non-empty-state-vector path (the existing
    /// happy path exercised by `test_localAndRemoteSyncing` etc) must
    /// continue to work unchanged.
    func test_diff_fromNonEmptyStateVector_unchangedBehaviour() {
        let localDocument = YDocument()
        let localText = localDocument.getOrCreateText(named: "example")
        localDocument.transactSync { txn in
            localText.append("regression target", in: txn)
        }

        // Remote already has some state.
        let remoteDocument = YDocument()
        let remoteText = remoteDocument.getOrCreateText(named: "example")
        remoteDocument.transactSync { txn in
            remoteText.append("already here", in: txn)
        }
        let remoteStateVector = remoteDocument.transactSync { txn in
            txn.transactionStateVector()
        }

        let update = localDocument.transactSync { txn in
            localDocument.diff(txn: txn, from: remoteStateVector)
        }

        // Update applies cleanly and remote converges to a string that
        // contains both local + remote contributions.
        remoteDocument.transactSync { txn in
            try! txn.transactionApplyUpdate(update: update)
        }
        let remoteString = remoteDocument.transactSync { txn in
            remoteText.getString(in: txn)
        }
        XCTAssertTrue(remoteString.contains("regression target"),
                      "regression: existing diff(from: nonEmpty) path must remain functional")
        XCTAssertTrue(remoteString.contains("already here"),
                      "regression: remote's pre-existing state must survive the merge")
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
