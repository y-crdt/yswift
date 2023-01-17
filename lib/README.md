## Description

This is a Rust package that wraps public interface from `yrs` and defines `udl` for UniFFI bindgen.

## Packaging for Swift

Run `./build-xcframework.sh` in the root of this directory. It will generate binary `.xcframework` and wrap it in SPM package (check [Package.swift](https://github.com/y-crdt/y-uniffi/blob/main/lib/Package.swift) for details).

During the current active development phase – only local, path-based distribution of SPM package is supported. Check [yswift](https://github.com/y-crdt/y-uniffi/tree/main/yswift) for more details.
