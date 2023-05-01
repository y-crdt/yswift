# Implementation Notes

Implementation details related to YSwift as a layer over Yrs

## Overview

`YSwift`, and it's C library counterpart `Yniffi`, layer over the Rust library [Yrs](https://docs.rs/yrs/latest/yrs/) to provide cross platform functionality.
`Yrs` was written with the intention of being a common, cross-platform code base with implementation exposed through a variety of languages.
Not every capability of the features within Yrs are exposed through to YSwift.
This document aims to provide some background to the details of what is and isn't exposed, and how that may effect your use of YSwift.

### Schema and Type Support

Yrs is a Rust based implementation of the original algorithm as defined in Yjs.dev, written in JavaScript.
Since the original version was written in a dynamic language, the Rust implementation maintained that dynamic storage capability, but with some limitations.
Within Yrs, lists can contain different kinds of values within the same ``YArray``. 
Likewise with ``YMap``, the values are not constrained to a single type.
Maps are keyed only by the type `String`, and do not support the use of arbitrary `Hashable` types as keys.

`YSwift` further constrains this in its initial release by representing Swift types through the lens of the Codable interface.
Structs or class instances added to a `YArray` or `YMap` are processed through `Codable` to store their JSON representations as a string within `Yrs`.

### Strings and Index Positions

``YText`` is a special-case of Array that is optimized for long runs of text.
Yrs represents this internally as UTF-8 characters. 
`YText` index positions within an instance based on the UTF8 view of the corresponding Swift `String`.

In Swift a `String`, by comparison, bases its index position on Grapheme clusters - what is visually a single character.
These characters do not always map 1:1 to UTF-8 characters.
When working with Strings it is important to convert index locations correctly.
Use the type [String.Index](https://developer.apple.com/documentation/swift/string/index) methods for converting into, and out of, index positions of UTF-8 views.

### Transactions

`Yrs` supports both mutable and read-only transactions for interacting with shared data types.
`YSwift` exposes only the mutable transactions through it's methods.
`YSwift` also implicitly creates those transactions, in some cases, although all the methods that read or update a shared data type accept a transaction that you might create directly.
Transactions in `YSwift` are always created from a ``YDocument`` instance.
