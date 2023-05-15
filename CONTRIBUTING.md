# Contributing to YSwift

This project is a Swift language layer over a binding to the Rust [Yrs](https://github.com/y-crdt/y-crdt) library using Mozilla's [UniFFI](https://github.com/mozilla/uniffi-rs/) project.

## Issues and project work

Issues for `YSwift` are tracked on GitHub at https://github.com/y-crdt/yswift/issues.
We typically keep our roadmap plans within one of those issues, and use issues to loosely track out progress.

This project keeps track of decision points and choices in the library development in a [Developer's Log](./devnotes/DevLog.md), and has a [release process documented](./devnotes/release-process.md).

## Local Development Setup

Scripts in the project build an XCFramework for iOS and macOS using UniFFI from the Rust sources as defined in [lib/Cargo.toml](./lib/Cargo.toml).
The binary included in the released XCFramework is intimately tied to the code that UniFFI generates into `lib/swift/scaffold`.

The rough pattern of dependencies that are reflected in `Package.swift`:

```
   +-----------+      +--------+      +--------+
   | yniffiFFI | <--- | Yniffi | <--- | YSwift |
   +-----------+      +--------+      +--------+
 C static library       UniFFI      Developer created
  from Rust lib        generated      Swift overlay
```

If you are working on any of the layers within the `lib` directory (the targets `yniffiFFI` or `Yniffi`) then set a local environment variable `LOCALDEV` to true and regenerate the XCFramework using the script `scripts/build-xcframework.sh`.
The [Package.swift](./Package.swift) file is configured to look for the `LOCALDEV` environment variable and use a local reference to the XCFramework if it is set.
Without that environment variable set, `Package.swift` uses the latest release version of the XCFramework.

If you are working on the Swift overlay (`YSwift` target), then you can safely use
the previous released version of the XCFramework and its associated generated code for `Yniffi`.
