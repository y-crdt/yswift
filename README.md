# y-uniffi

**This repository is WIP (Work In Progress)**

This project provides [yrs](https://github.com/y-crdt/y-crdt) bindings for Kotlin and Swift using [UniFFI](https://github.com/mozilla/uniffi-rs/).

`lib/` contains Rust library that wraps `yrs` crate and `udl` (UniFFI-specific interface definition file), which is required to generate Kotlin & Swift bindings. 

`ykt/` and `yswift/` contain language-specific wrappers to provide more idiomatic API.

## Decision log

We maintain a [decision log](https://github.com/y-crdt/y-uniffi/blob/main/docs/decisions.md). Please consult it in case there is some ambiguity in terms of why certain implementation details look as they are.

## License

This project is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Thanks to

Amazing guys at Mozilla for their outsanding work on [UniFFI](https://github.com/mozilla/uniffi-rs/) and all of the supporting work they've done on using, packaging and distributing Rust code for Swift and Kotlin codebases.
