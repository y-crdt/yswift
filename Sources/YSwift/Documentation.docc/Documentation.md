# ``YSwift``

Swift language bindings to Y-CRDT shared data types to sync and collaborate.

## Overview

YSwift is part of a collection of cross-platform and cross-language Conflict-free Replicated Data Types (CRDT).
These data types enable automatic synchronization and merge without conflicts.
YSwift is network agnostic, supporting offline asynchronous, peer to peer, and server based interactions.

YSwift is a Swift language overlay of the Rust library [Yrs](https://docs.rs/yrs/latest/yrs/), but not all of the features of Yrs are current exposed in YSwift.

## Topics

### Documents

- ``YSwift/YDocument``
- ``YSwift/Buffer``
- <doc:SynchronizingDocuments>
- <doc:ImplementationNotes>

### Arrays

- ``YSwift/YArray``
- ``YSwift/YArrayChange``

### Maps

- ``YSwift/YMap``
- ``YSwift/YMapChange``

### Text

- ``YSwift/YText``
- ``YSwift/YTextChange``

### Synchronization

- ``YSwift/YProtocol``
- ``YSwift/YSyncMessage``
