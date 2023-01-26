#!/usr/bin/env bash

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

echo "▸ Install uniffi bindgen"
cargo install uniffi_bindgen

echo "▸ Clean state"
rm -rf "${BUILD_FOLDER}"
rm -rf "${XCFRAMEWORK_FOLDER}"

mkdir -p "${SWIFT_FOLDER}/scaffold"
echo "▸ Generate Swift Scaffolding Code"
$HOME/.cargo/bin/uniffi-bindgen generate "src/yniffi.udl" --language swift --out-dir "${SWIFT_FOLDER}/scaffold"
# Remove unused generated .modulemap
rm "${SWIFT_FOLDER}/scaffold/${PACKAGE_NAME}FFI.modulemap"

echo "▸ Building for x86_64-apple-ios"
CFLAGS_x86_64_apple_ios="-target x86_64-apple-ios" \
cargo build --target x86_64-apple-ios --package "${PACKAGE_NAME}" --locked --release

echo "▸ Building for aarch64-apple-ios-sim"
CFLAGS_x86_64_apple_ios="-target aarch64-apple-ios-sim" \
cargo build --target aarch64-apple-ios-sim --package "${PACKAGE_NAME}" --locked --release

echo "▸ Building for aarch64-apple-ios"
CFLAGS_x86_64_apple_ios="-target aarch64-apple-ios" \
cargo build --target aarch64-apple-ios --package "${PACKAGE_NAME}" --locked --release

echo "▸ Starting xcframework creation"
echo "▸ Copy necessary files"
mkdir -p "${XCFRAMEWORK_FOLDER}/ios-arm64/${FRAMEWORK_FOLDER}"
cp "$SWIFT_FOLDER/pkg/Info.plist" "$XCFRAMEWORK_FOLDER"
cp -r "${SWIFT_FOLDER}/pkg/Headers" "${XCFRAMEWORK_FOLDER}/ios-arm64/${FRAMEWORK_FOLDER}"
cp -r "${SWIFT_FOLDER}/pkg/Modules" "${XCFRAMEWORK_FOLDER}/ios-arm64/${FRAMEWORK_FOLDER}"
mv "${SWIFT_FOLDER}/scaffold/${PACKAGE_NAME}FFI.h" "${XCFRAMEWORK_FOLDER}/ios-arm64/${FRAMEWORK_FOLDER}/Headers"
# Duplicate same layout for both architectures
cp -r "${XCFRAMEWORK_FOLDER}/ios-arm64" "${XCFRAMEWORK_FOLDER}/ios-arm64_x86_64-simulator"

echo "▸ Lipo & move iOS Simulator static library to xcframework"
lipo -create  \
    "./${BUILD_FOLDER}/x86_64-apple-ios/release/${LIB_NAME}" \
    "./${BUILD_FOLDER}/aarch64-apple-ios-sim/release/${LIB_NAME}" \
    -output "$XCFRAMEWORK_FOLDER/ios-arm64_x86_64-simulator/$FRAMEWORK_FOLDER/$FRAMEWORK_NAME"

echo "▸ Move iOS Device static library to xcframework"
cp "$BUILD_FOLDER/aarch64-apple-ios/release/$LIB_NAME" "$XCFRAMEWORK_FOLDER/ios-arm64/$FRAMEWORK_FOLDER/$FRAMEWORK_NAME"

echo "▸ Compress xcframework"
ditto -c -k --sequesterRsrc --keepParent "$XCFRAMEWORK_FOLDER" "$XCFRAMEWORK_FOLDER.zip"

echo "▸ Compute checksum"
openssl dgst -sha256  "$XCFRAMEWORK_FOLDER.zip"
