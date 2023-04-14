# Yswift

Swifty wrapper for yrs.

Uses [Tuist](https://tuist.io/) for Xcode project automation and dependency management.

## Getting started

### Install tuist
```
curl -Ls https://install.tuist.io | bash
```

### Fetch dependencies and generate project
```
tuist fetch && tuist generate
```

## Notes

This project depends on SPM package generated in [`uniffi/lib`](https://github.com/y-crdt/y-uniffi/tree/main/lib). For now it is referenced using local paths.

## Thanks

Huge shout-out goes to Joe ([heckj](https://github.com/heckj)) for his [work on initial prototype of Yrs port for Swift](https://github.com/heckj/YrsC).
