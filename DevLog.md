# Decision log

## 2022-01-19

### Passing complex types as `String`s through Uniffi bridging

At the moment of writing, Uniffi didn't support passing complex types through Uniffi bridge.  
(See [related issue #1](https://github.com/mozilla/uniffi-rs/issues/411), [#2](https://github.com/mozilla/uniffi-rs/issues/348)
and type mapping [table from docs](https://mozilla.github.io/uniffi-rs/udl/builtin_types.html)).

There were some attempts to implement passing any non-primitive type by the means of JSON serialization & deserialization.  
See [related PR](https://github.com/mozilla/uniffi-rs/pull/440). But it wasn't merged due to the reasons outlined in the comments.

To work around this limitation – manual JSON serialization & deserialization happens when passing complex types back and forth
between Rust and Swift code. This process leverages `lib0-serde` feature.

Few further improvements that can be made here: 
- Use `lib0` binary encoding/decoding to pass data as binary buffers rather than JSON strings.
- Pass raw pointers (e.g. `BranchPtr` from `yrs`) through the bridge and consume them using `Unmanaged` features of Swift.

## 2023-01-10

### Monorepo for Kotlin & Swift bindings development

Both Kotlin and Swift bindings need to access common `.udl` (interface definition file),
few options as git submodules were considered, but decision was made to go with
monorepo setup for the active development phase of the bindings as it was the simplest-to-use
and lowest overhead approach.

After language bindings reach their stable release states, we might consider to split the repo
into three parts: Uniffi, Kotlin and Swift, where Uniffi part will contain `.udl` file and
wrapping Rust library that will eventually publish corresponding artifacts 
(e.g. SPM package for Swift and Gradle module for Kotlin)

## 2022-12-20

### Uniffi as bindgen foundation

[UniFFI](https://mozilla.github.io/uniffi-rs/) was chosen as binding generation solution
for Kotlin & Swift language bindings due to good documentation, active maintenance state and overall
use case suitability.

Alternatives considered: [swift-bridge](https://github.com/chinedufn/swift-bridge) and [Yrs C FFI](https://github.com/y-crdt/y-crdt/tree/main/yffi)
