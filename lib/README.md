
## Install Rust compiler targets with `rustup`

```sh
% rustup target add x86_64-apple-ios aarch64-apple-ios aarch64-apple-ios-sim
```

## Generate headers & Swift scaffolding

```sh
$HOME/.cargo/bin/uniffi-bindgen generate "$INPUT_FILE_PATH" --language swift --out-dir "$DERIVED_FILE_DIR"
```

## Tell Xcode how to build the Rust project.



1. In Xcode, click on the project in the Project Navigator.
2. In the main window, select the app's main target, and then select "Build Phases".
3. Add a new `Run Script` build phase and move it to the top.
4. Add the script that will build a universal binary for the Rust project.

For this project, we've used a script adapted from the #mozilla/application-services project to build a universal binary with `lipo`.

```sh
bash $SRCROOT/xc-universal-binary.sh libuniffi_todolist.a uniffi-example-todolist $SRCROOT/../../../ $CONFIGURATION
```

In this case we constructed the command:

```sh
xc-universal-binary.sh <STATIC_LIB_NAME> <FFI_TARGET> <WORKSPACE_PATH> <BUILD_CONFIGURATION>"
```

by making:

 * `STATIC_LIB_NAME` from the `lib` `name` above: `uniffi_todolist` --> `libuniffi_todolist.a`
 * `FFI_TARGET` from the `package` `name` above: `uniffi-example-todolist`.

The `WORKSPACE_PATH` is where the `Cargo.toml` will resolve the Rust project, and also determine the target directory that `cargo build` and `lipo` will put its artifacts.

This script performs a few steps:

1. Runs `cargo build` to compile the Rust project for the `x86_64-apple-ios` and `aarch64-apple-ios` targets.
    * This includes using `uniffi-bindgen` to generate the Rust scaffolding so we can go from C to Rust.
2. Runs `lipo` to combine these libs in to a universal binary.
3. Puts the universal binary in to the `$WORKSPACE_PATH/target/universal` directory.

## Tell Xcode where the universal library is

Finally, we need to tell Xcode to look for the universal binary `libuniffi_todolist.a` is, so it can tie it together with the header file `todolist-Bridging-Header.h`.

1. In Xcode, click on the project in the Project Navigator.
2. In the main window, select the app's main target, and then select "Build Settings".
3. Search for `Library Search Paths`.
4. Add paths to where lipo constructed the universal binaries for each of `Debug` and `Release`.

```sh
$(SRCROOT)/../../../target/universal/debug
$(SRCROOT)/../../../target/universal/release
```
