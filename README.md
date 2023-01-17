# y-uniffi

**This repository is WIP (Work In Progress)**

This project provides [yrs](https://github.com/y-crdt/y-crdt) bindings for Kotlin and Swift using [UniFFI](https://github.com/mozilla/uniffi-rs/).

`lib/` contains Rust library that wraps `yrs` crate and `udl` (UniFFI-specific interface definition file), which is required to generate Kotlin & Swift bindings. 

`ykt/` and `yswift/` contain language-specific wrappers to provide more idiomatic API.
