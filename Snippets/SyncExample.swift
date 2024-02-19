// // snippet.establishDocuments
// import YSwift

// let localDocument = YDocument()
// let localText = localDocument.getOrCreateText(named: "example")
// localDocument.transactSync { txn in
//     localText.append("hello, world!", in: txn)
// }

// let remoteDocument = YDocument()
// let remoteText = remoteDocument.getOrCreateText(named: "example")
// // snippet.end

// // snippet.displayTextFromDocuments
// localDocument.transactSync { txn in
//     print("local document text from `example`: \"\(localText.getString(in: txn))\"")
// }

// remoteDocument.transactSync { txn in
//     print("remote document text from `example`: \"\(remoteText.getString(in: txn))\"")
// }

// // snippet.end

// // snippet.syncDocuments
// print(" --> Synchronizing local to remote")
// let remoteState = remoteDocument.transactSync { txn in
//     txn.transactionStateVector()
// }

// print("  . Size of the remote state is \(remoteState.count) bytes.")
// let updateRemote = localDocument.transactSync { txn in
//     localDocument.diff(txn: txn, from: remoteState)
// }

// print("  . Size of the diff from remote state is \(updateRemote.count) bytes.")
// remoteDocument.transactSync { txn in
//     try! txn.transactionApplyUpdate(update: updateRemote)
// }

// // snippet.end

// // Synchronization complete, read out results into local variables

// // snippet.captureAndDisplaySyncedData
// let localString = localDocument.transactSync { txn in
//     localText.getString(in: txn)
// }

// let remoteString = remoteDocument.transactSync { txn in
//     remoteText.getString(in: txn)
// }

// print("local document text from `example`: \"\(localString)\"")
// print("remote document text from `example`: \"\(remoteString)\"")
// // snippet.end
