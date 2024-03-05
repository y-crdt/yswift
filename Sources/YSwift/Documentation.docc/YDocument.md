# ``YSwift/YDocument``

A type that wraps all Y-CRDT shared data types, and provides transactional interactions for them.

## Overview

A `YDocument` tracks and coordinates updates to Y-CRDT shared data types, such as ``YSwift/YText``, ``YSwift/YArray``, and ``YSwift/YMap``.
Make any changes to shared data types within a document within a transaction, such as ``YSwift/YDocument/transactSync(origin:_:)``.

Interact with other copies of the shared data types by synchronizing documents.

To synchronize a remote document with a local one:

1. Retrieve the current state of remote document from within a transaction:
```
let remoteState = remoteDocument.transactSync { txn in
    txn.transactionStateVector()
}
```

2. Use the remote state to calculate a difference from the local document:
```
let updateRemote = localDocument.transactSync { txn in
    localDocument.diff(txn: txn, from: remoteState)
}
```

3. Apply the difference to the remote document within a transaction:
```
remoteDocument.transactSync { txn in
    try! txn.transactionApplyUpdate(update: updateRemote)
}
```

For a more detailed example of synchronizing a document, see <doc:SynchronizingDocuments>.

## Topics

### Creating or loading a document

- ``YSwift/YDocument/init()``

### Creating Shared Data Types

- ``YSwift/YDocument/getOrCreateText(named:)``
- ``YSwift/YDocument/getOrCreateArray(named:)``
- ``YSwift/YDocument/getOrCreateMap(named:)``

### Creating Transactions

- ``YSwift/YDocument/transactSync(origin:_:)``
- ``YSwift/YDocument/transact(origin:_:)``
- ``YSwift/YDocument/transactAsync(_:_:completion:)``

### Comparing Documents for Synchronization

- ``YSwift/YDocument/diff(txn:from:)``

### Undo and Redo

- ``YSwift/YDocument/undoManager(trackedRefs:)``
