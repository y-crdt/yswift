# Synchronizing Documents

Consistently merge content between two documents.

## Overview

One of the primary benefits of using `YSwift` is to be able to seamlessly and consistently synchronize data between two or more documents.
In this example, we show creating two instances of ``YSwift/YDocument`` and synchronizing between them, but in a real-world scenario the synchronization data would more likely be transmitted between two peers, or between a client application and server.

### Establish the Documents

Once the library is imported, create an instance of ``YSwift/YDocument`` and use that instance to create the schema you wish to synchronize.
You can create ``YSwift/YText`` to synchronize text, or either of ``YSwift/YArray`` or ``YSwift/YMap`` to synchronize any `Codable` type you provide.
The keys for the schema are strings, and are required to match between two instances of ``YSwift/YDocument`` to synchronize the values.

```swift
import YSwift

let localDocument = YDocument()
let localText = localDocument.getOrCreateText(named: "example")
localDocument.transactSync { txn in
    localText.append("hello, world!", in: txn)
}

let remoteDocument = YDocument()
let remoteText = remoteDocument.getOrCreateText(named: "example")
```

### Display the Initial State

To read, or update, values from within a ``YDocument``, do so from within a transaction.
The following sample uses ``YText/getString(in:)`` from within the closure passed through ``YDocument/transactSync(origin:_:)`` to directly access the values:

```swift
localDocument.transactSync { txn in
    print("local document text from `example`: \"\(localText.getString(in: txn))\"")
}

remoteDocument.transactSync { txn in
    print("remote document text from `example`: \"\(remoteText.getString(in: txn))\"")
}
```

### Synchronize the Document

The synchronization process follows a three step process:

1. Get the current state of document you want to which you want to synchronize data.
2. Compute an update from the document by comparing that state with another document.
3. Apply the computed update to the original document from which you retrieved the initial state.

The retrieved state and computed difference are raw byte buffers.
In the following example, we only synchronize in one direction - from the `localDocument` to `remoteDocument`.
In most scenarios, you likely should compute the state of both sides, compute the differences, and
synchronize in both directions:

```swift
print (" --> Synchronizing local to remote")
let remoteState = remoteDocument.transactSync { txn in
    txn.transactionStateVector()
}
print("  . Size of the remote state is \(remoteState.count) bytes.")

let updateRemote = localDocument.transactSync { txn in
    localDocument.diff(txn: txn, from: remoteState)
}
print("  . Size of the diff from remote state is \(updateRemote.count) bytes.")

remoteDocument.transactSync { txn in
    try! txn.transactionApplyUpdate(update: updateRemote)
}
```

### Retrieve and display data

With the synchronization complete, the value of the current state of the shared data type can be extracted and used.
In the following example, we return the copies of the string values of ``YText`` back from the ``YDocument/transactSync(_:)`` closure in order to use them outside of a transaction:

```swift
let localString = localDocument.transactSync { txn in
    localText.getString(in: txn)
}

let remoteString = remoteDocument.transactSync { txn in
    remoteText.getString(in: txn)
}

print("local document text from `example`: \"\(localString)\"")
print("remote document text from `example`: \"\(remoteString)\"")
```

For a more complete example that illustrates synchronizing a simple To-Do list, see the [examples directory in the YSwift repository](https://github.com/y-crdt/yswift/tree/main/examples).
