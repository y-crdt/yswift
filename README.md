# YSwift

This library builds on top of [Yrs](https://github.com/y-crdt/y-crdt) to provide Swift language bindings that
seamlessly interoperate with other Yjs implementations.

**This repository is WIP (Work In Progress)**
Not all features and capabilities from Yrs or Yjs are exposed at this time. 
We plan to add them as the library evolves. 

The repository includes two swift packages:

`yniffiFFI` a static binary packaged as an XCFramework in the `lib` directory, built with the Rust compiler and overlaid using [UniFFI](https://github.com/mozilla/uniffi-rs/).
`YSwift` which is an overlay to provide more idiomatic Swift language operations.

To build the package from source, you need both Rust and XCode installed. 
The GitHub releases should include versioned links to the `yniffiFFI`. 
Development releases expect that you will build you own local copy using `./scripts/build-xcframework.sh`.

## Decision log

This project maintains a [decision log](./DevLog.md). 
Please consult it in case there is some ambiguity in terms of why certain implementation details look as they are.

## License

This project is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Thanks to

Amazing people at Mozilla for their outsanding work on [UniFFI](https://github.com/mozilla/uniffi-rs/) and all of the supporting work they've done on using, packaging and distributing Rust code for Swift and Kotlin codebases.
