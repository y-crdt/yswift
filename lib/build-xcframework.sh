#!/usr/bin/env bash

set -e # immediately terminate script on any failure conditions
set -x # echo script commands for easier debugging

PACKAGE_NAME="yniffi"
LIB_NAME="libuniffi_yniffi.a"

# *IMPORTANT*: When changing this value, change them in `swift/pkg/YNative.h` and `swift/pkg/Info.plist` as well
FRAMEWORK_NAME="yniffiFFI"

SWIFT_FOLDER="swift"
BUILD_FOLDER="target"

XCFRAMEWORK_FOLDER="${FRAMEWORK_NAME}.xcframework"
# FRAMEWORK_FOLDER="${FRAMEWORK_NAME}.framework"

echo "▸ Install toolchains"
rustup target add x86_64-apple-ios # iOS Simulator (Intel)
rustup target add aarch64-apple-ios-sim # iOS Simulator (M1)
rustup target add aarch64-apple-ios # iOS Device
rustup target add aarch64-apple-darwin # macOS ARM/M1
rustup target add x86_64-apple-darwin # macOS Intel/x86

echo "▸ Clean state"
rm -rf "${BUILD_FOLDER}"
rm -rf "${XCFRAMEWORK_FOLDER}"

mkdir -p "${SWIFT_FOLDER}/scaffold"
echo "▸ Generate Swift Scaffolding Code"
cargo run -p uniffi-bindgen generate "src/yniffi.udl" --language swift --out-dir "${SWIFT_FOLDER}/scaffold"

echo "▸ Building for x86_64-apple-ios"
CFLAGS_x86_64_apple_ios="-target x86_64-apple-ios" \
cargo build --target x86_64-apple-ios --package "${PACKAGE_NAME}" --locked --release

echo "▸ Building for aarch64-apple-ios-sim"
CFLAGS_aarch64_apple_ios="-target aarch64-apple-ios-sim" \
cargo build --target aarch64-apple-ios-sim --package "${PACKAGE_NAME}" --locked --release

echo "▸ Building for aarch64-apple-ios"
CFLAGS_aarch64_apple_ios="-target aarch64-apple-ios" \
cargo build --target aarch64-apple-ios --package "${PACKAGE_NAME}" --locked --release

echo "▸ Building for aarch64-apple-darwin"
CFLAGS_aarch64_apple_darwin="-target aarch64-apple-darwin" \
cargo build --target aarch64-apple-darwin --package "${PACKAGE_NAME}" --locked --release

echo "▸ Building for x86_64-apple-darwin"
CFLAGS_x86_64_apple_darwin="-target x86_64-apple-darwin" \
cargo build --target x86_64-apple-darwin --package "${PACKAGE_NAME}" --locked --release

echo "▸ Consolidating the headers and modulemaps for XCFramework generation"
mkdir -p "${BUILD_FOLDER}/includes"
cp "${SWIFT_FOLDER}/scaffold/yniffiFFI.h" "${BUILD_FOLDER}/includes"
cp "${SWIFT_FOLDER}/scaffold/yniffiFFI.modulemap" "${BUILD_FOLDER}/includes/module.modulemap"

mkdir -p "${BUILD_FOLDER}/ios-simulator/release"
echo "▸ Lipo (merge) x86 and arm simulator static libraries into a fat static binary"
lipo -create  \
    "./${BUILD_FOLDER}/x86_64-apple-ios/release/${LIB_NAME}" \
    "./${BUILD_FOLDER}/aarch64-apple-ios-sim/release/${LIB_NAME}" \
    -output "${BUILD_FOLDER}/ios-simulator/release/${LIB_NAME}"

mkdir -p "${BUILD_FOLDER}/apple-darwin/release"
echo "▸ Lipo (merge) x86 and arm macOS static libraries into a fat static binary"
lipo -create  \
    "./${BUILD_FOLDER}/x86_64-apple-darwin/release/${LIB_NAME}" \
    "./${BUILD_FOLDER}/aarch64-apple-darwin/release/${LIB_NAME}" \
    -output "${BUILD_FOLDER}/apple-darwin/release/${LIB_NAME}"

# what docs there are:
# xcodebuild -create-xcframework -help
# https://developer.apple.com/documentation/xcode/creating-a-multi-platform-binary-framework-bundle

xcodebuild -create-xcframework \
    -library "./$BUILD_FOLDER/aarch64-apple-ios/release/$LIB_NAME" \
    -headers "./${BUILD_FOLDER}/includes" \
    -library "./${BUILD_FOLDER}/ios-simulator/release/${LIB_NAME}" \
    -headers "./${BUILD_FOLDER}/includes" \
    -library "./$BUILD_FOLDER/apple-darwin/release/$LIB_NAME" \
    -headers "./${BUILD_FOLDER}/includes" \
    -output "./${XCFRAMEWORK_FOLDER}"

# echo "▸ Compress xcframework"
ditto -c -k --sequesterRsrc --keepParent "$XCFRAMEWORK_FOLDER" "$XCFRAMEWORK_FOLDER.zip"

# echo "▸ Compute checksum"
openssl dgst -sha256 "$XCFRAMEWORK_FOLDER.zip"
