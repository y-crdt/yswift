#!/bin/bash

set -e  # exit on a non-zero return code from a command
set -x  # print a trace of commands as they execute

THIS_SCRIPT_DIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
# ^^ provides an absolutely local path to where the script is being invoked,
# which lets us target further build commands specific to a directory
# srtucture.
# example: /Users/heckj/src/y-uniffi/scripts
pushd "$THIS_SCRIPT_DIR/.."

# Enables deterministic output
# - useful when you're committing the results to host on github pages
export DOCC_JSON_PRETTYPRINT=YES

# Add the following as a dependency into your Package.swift
# // Swift-DocC Plugin - swift 5.6+ ONLY
#     dependencies: [
#        .package(url: "https://github.com/apple/swift-docc-plugin", branch: "main"),
#    ],
# run:
#   $(xcrun --find swift) package resolve
#   $(xcrun --find swift) build

# rm -rf .build .ffisymbol-graphs
# mkdir -p .ffisymbol-graphs

rm -rf .build .symbol-graphs
mkdir -p .symbol-graphs

$(xcrun --find swift) build --target Yniffi \
    -Xswiftc -emit-symbol-graph \
    -Xswiftc -emit-symbol-graph-dir -Xswiftc .ffisymbol-graphs

$(xcrun --find swift) build --target YSwift \
    -Xswiftc -emit-symbol-graph \
    -Xswiftc -emit-symbol-graph-dir -Xswiftc .symbol-graphs

#$(xcrun --find docc) convert lib/swift/scaffold/Documentation.docc \
#    --fallback-display-name Yniffi \
#    --fallback-bundle-identifier com.github.y-crdt.Yniffi \
#    --fallback-bundle-version 0.2.0  \
#    --additional-symbol-graph-dir .ffisymbol-graphs \
#    --emit-digest \
#    --transform-for-static-hosting \
#    --output-path ./docs \
#    --hosting-base-path 'yswift'
    # --experimental-documentation-coverage \
    # --level brief
    # --disable-indexing \

$(xcrun --find docc) convert Sources/YSwift/Documentation.docc \
    --fallback-display-name YSwift \
    --fallback-bundle-identifier com.github.y-crdt.YSwift \
    --fallback-bundle-version 0.2.0 \
    --additional-symbol-graph-dir .symbol-graphs \
    --emit-digest \
    --transform-for-static-hosting \
    --output-path ./docs \
    --hosting-base-path 'yswift'
    # --experimental-documentation-coverage \
    # --level brief
    # --disable-indexing \

# Swift package plugin for hosted content:
#

# PREVIEW:
#
# $(xcrun --find swift) package --disable-sandbox preview-documentation
#
# Note - this ALSO doesn't appear to be working entirely correctly, although
# I may be "holding it wrong". It runs and activates the preview browser,
# but accessing the expected target URL locally:
#     http://localhost:8000/documentation/yniffi/
# doesn't appear to load the expected target JSON, although it's in the
# `docs/data/documentation` directory. Instead it's reporting a 404 for
# the resource: http://localhost:8000/data/documentation/yniffi.json

# NOTE(heckj): Using the swift-docc-plugin would generally be my preferred
# path for generating HTML documentation, however there is a bug when building
# documentation with a binary package dependency. The symbols are
# coming up "empty, which I suspect is due to not correctly handling the static
# library from the binary target.

# $(xcrun --find swift) package \
#      --allow-writing-to-directory ./docs \
#      generate-documentation \
#      --fallback-bundle-identifier com.github.y-crdt.Yniffi \
#      --fallback-bundle-version 0.16.1 \
#      --target Yniffi \
#      --output-path ./docs \
#      --emit-digest \
#      --disable-indexing \
#      --transform-for-static-hosting \
#      --hosting-base-path 'Yniffi'

# Generate a list of all the identifiers to assist in DocC curation
#

cat docs/linkable-entities.json | jq '.[].referenceURL' -r | grep 'Yniffi' > yniffi_identifiers.txt
cat docs/linkable-entities.json | jq '.[].referenceURL' -r | grep 'YSwift' | grep -v "Yniffi" > yswift_identifiers.txt
sort yniffi_identifiers.txt \
    | sed -e 's/doc:\/\/com\.github\.y-crdt\.YSwift\/documentation\///g' \
    | sed -e 's/^/- ``/g' \
    | sed -e 's/$/``/g' > yniffi_symbols.txt
sort yswift_identifiers.txt \
    | sed -e 's/doc:\/\/com\.github\.y-crdt\.YSwift\/documentation\///g' \
    | sed -e 's/^/- ``/g' \
    | sed -e 's/$/``/g' > yswift_symbols.txt

echo "Page will be available at https://y-crdt.github.io/yswift/documentation/yswift/"
