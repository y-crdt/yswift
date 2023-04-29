# ``YSwift/YDocument``

Swift language bindings to Y-CRDT shared data types to sync and collaborate.

## Overview

YSwift is part of a collection of cross-platform and cross-language Conflict-free Replicated Data Types (CRDT).
These data types enable automatic synchronization and merge without conflicts.
YSwift is network agnostic, supporting peer to peer, server based interactions.
You can edit offline, and reconnect later to synchronize updates.

## Topics

### Creating or loading a document

- ``YSwift/YDocument/init()``

### Creating Transactions

- ``YSwift/YDocument/transactSync(_:)``
- ``YSwift/YDocument/transact(_:)``
- ``YSwift/YDocument/transactAsync(_:completion:)``

### Comparing Documents for Synchronization

- ``YSwift/YDocument/diff(txn:from:)``

### Creating Shared Data Types

- ``YSwift/YDocument/getOrCreateText(named:)``
- ``YSwift/YDocument/getOrCreateArray(named:)``
- ``YSwift/YDocument/getOrCreateMap(named:)``
