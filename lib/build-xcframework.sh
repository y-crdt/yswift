#!/usr/bin/env bash

set -e # force the script to fail on any command failures

PACKAGE_NAME="yniffi"
LIB_NAME="libuniffi_yniffi.a"

# *IMPORTANT*: When changing this value, change them in `swift/pkg/YNative.h` and `swift/pkg/Info.plist` as well
FRAMEWORK_NAME="YniffiXC"

SWIFT_FOLDER="swift"
BUILD_FOLDER="target"

XCFRAMEWORK_FOLDER="${FRAMEWORK_NAME}.xcframework"
FRAMEWORK_FOLDER="${FRAMEWORK_NAME}.framework"

echo "▸ Install toolchains"
rustup target add x86_64-apple-ios # iOS Simulator (Intel)
rustup target add aarch64-apple-ios-sim # iOS Simulator (M1)
rustup target add aarch64-apple-ios # iOS Device
rustup target add aarch64-apple-darwin # macOS platform (M1)
rustup target add x86_64-apple-darwin # macOS platform (x86)

if [ ! -x $HOME/.cargo/bin/uniffi-bindgen ]; then
    echo "▸ Install uniffi bindgen"
    cargo install uniffi_bindgen
fi

# (heckj - 26jan2023): remove the following line IF we start to include/check in
# the local Cargo.lock file. The `--locked` command line options on the
# build steps below imply that it exists and is stable, but in a raw
# repository check-out, it doesn't get included as I'm writing this.
cargo update # creates a Cargo.lock, which is required for further steps

echo "▸ Clean state"
rm -rf "${BUILD_FOLDER}"
rm -rf "${XCFRAMEWORK_FOLDER}"

mkdir -p "${SWIFT_FOLDER}/scaffold"
echo "▸ Generate Swift Scaffolding Code"
$HOME/.cargo/bin/uniffi-bindgen generate "src/yniffi.udl" --language swift --out-dir "${SWIFT_FOLDER}/scaffold"
# Remove unused generated .modulemap
#rm "${SWIFT_FOLDER}/scaffold/${PACKAGE_NAME}FFI.modulemap"

echo "▸ Building for x86_64-apple-ios"
CFLAGS_x86_64_apple_ios="-target x86_64-apple-ios" \
cargo build --target x86_64-apple-ios --package "${PACKAGE_NAME}" --locked --release

echo "▸ Building for aarch64-apple-ios-sim"
CFLAGS_x86_64_apple_ios="-target aarch64-apple-ios-sim" \
cargo build --target aarch64-apple-ios-sim --package "${PACKAGE_NAME}" --locked --release

echo "▸ Building for aarch64-apple-ios"
CFLAGS_x86_64_apple_ios="-target aarch64-apple-ios" \
cargo build --target aarch64-apple-ios --package "${PACKAGE_NAME}" --locked --release

echo "▸ Building for aarch64-apple-darwin"
CFLAGS_x86_64_apple_ios="-target aarch64-apple-darwin" \
cargo build --target aarch64-apple-darwin --package "${PACKAGE_NAME}" --locked --release

echo "▸ Building for x86_64-apple-darwin"
CFLAGS_x86_64_apple_ios="-target x86_64-apple-darwin" \
cargo build --target x86_64-apple-darwin --package "${PACKAGE_NAME}" --locked --release

# Upstream documentation on creating XCFramework bundles:
# https://help.apple.com/xcode/mac/11.4/#/dev544efab96
# https://developer.apple.com/documentation/xcode/creating-a-multi-platform-binary-framework-bundle
# https://developer.apple.com/documentation/xcode/distributing-binary-frameworks-as-swift-packages
# WWDC 2019 video on generating binaries: https://developer.apple.com/videos/play/wwdc2019/416/

# echo "▸ Copy necessary files"
# mkdir -p "${XCFRAMEWORK_FOLDER}/ios-arm64/${FRAMEWORK_FOLDER}"
# cp "$SWIFT_FOLDER/pkg/Info.plist" "$XCFRAMEWORK_FOLDER"
# cp -r "${SWIFT_FOLDER}/pkg/Headers" "${XCFRAMEWORK_FOLDER}/ios-arm64/${FRAMEWORK_FOLDER}"
# cp -r "${SWIFT_FOLDER}/pkg/Modules" "${XCFRAMEWORK_FOLDER}/ios-arm64/${FRAMEWORK_FOLDER}"
# mv "${SWIFT_FOLDER}/scaffold/${PACKAGE_NAME}FFI.h" "${XCFRAMEWORK_FOLDER}/ios-arm64/${FRAMEWORK_FOLDER}/Headers"
# # Duplicate same layout for both architectures
# cp -r "${XCFRAMEWORK_FOLDER}/ios-arm64" "${XCFRAMEWORK_FOLDER}/ios-arm64_x86_64-simulator"

echo "▸ Create a unified header pool for the XCFramework"
# Creating this pool, with the unified header, with the suspicion that we might want to use
# more than a single rust-based library in our combined swift package.
mkdir -p "${BUILD_FOLDER}/FFI_headers"
cp -r "${SWIFT_FOLDER}/pkg/Headers/" "${BUILD_FOLDER}/FFI_headers"
cp "${SWIFT_FOLDER}/scaffold/yniffiFFI.h" "${BUILD_FOLDER}/FFI_headers"
cp "${SWIFT_FOLDER}/scaffold/yniffiFFI.modulemap" "${BUILD_FOLDER}/FFI_headers"

echo "▸ Lipo (merge platforms) iOS Simulator static library for consuming into an XCFramework"
mkdir -p "./${BUILD_FOLDER}/apple-ios-simulator/release"
lipo -create  \
    "./${BUILD_FOLDER}/x86_64-apple-ios/release/${LIB_NAME}" \
    "./${BUILD_FOLDER}/aarch64-apple-ios-sim/release/${LIB_NAME}" \
    -output "./${BUILD_FOLDER}/apple-ios-simulator/release/${LIB_NAME}"

echo "▸ Lipo (merge platforms) macOS static library for consuming into an XCFramework"
mkdir -p "./${BUILD_FOLDER}/apple-darwin/release"
lipo -create  \
    "./${BUILD_FOLDER}/x86_64-apple-darwin/release/${LIB_NAME}" \
    "./${BUILD_FOLDER}/aarch64-apple-darwin/release/${LIB_NAME}" \
    -output "./${BUILD_FOLDER}/apple-darwin/release/${LIB_NAME}"

# echo "▸ Move iOS Device static library to xcframework"
# cp "$BUILD_FOLDER/aarch64-apple-ios/release/$LIB_NAME" "$XCFRAMEWORK_FOLDER/ios-arm64/$FRAMEWORK_FOLDER/$FRAMEWORK_NAME"

echo "▸ Create ${XCFRAMEWORK_FOLDER}"
  xcodebuild -create-xcframework \
            -library "./$BUILD_FOLDER/apple-ios-simulator/release/${LIB_NAME}" \
            -headers "./${BUILD_FOLDER}/FFI_headers" \
            -library "./$BUILD_FOLDER/aarch64-apple-ios/release/${LIB_NAME}" \
            -headers "./${BUILD_FOLDER}/FFI_headers" \
            -library "./$BUILD_FOLDER/apple-darwin/release/${LIB_NAME}" \
            -headers "./${BUILD_FOLDER}/FFI_headers" \
            -output "${XCFRAMEWORK_FOLDER}"

echo "▸ Compress XCFramework"
ditto -c -k --sequesterRsrc --keepParent "$XCFRAMEWORK_FOLDER" "$XCFRAMEWORK_FOLDER.zip"

echo "▸ Compute checksum"
openssl dgst -sha256  "$XCFRAMEWORK_FOLDER.zip"
