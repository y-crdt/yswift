#!/bin/bash

echo "Make sure you've rebased over the current HEAD branch:"
echo "git rebase -i origin/main docs"

set -e  # exit on a non-zero return code from a command
set -x  # print a trace of commands as they execute

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

rm -rf .build .symbol-graphs
mkdir -p .symbol-graphs

$(xcrun --find swift) build --target Yniffi \
    -Xswiftc -emit-symbol-graph \
    -Xswiftc -emit-symbol-graph-dir -Xswiftc .symbol-graphs

$(xcrun --find docc) convert swift/scaffold/Documentation.docc \
    --fallback-display-name Yniffi \
    --fallback-bundle-identifier com.github.y-crdt.Yniffi \
    --fallback-bundle-version 0.16.1 \
    --additional-symbol-graph-dir .symbol-graphs \
    --emit-digest \
    --transform-for-static-hosting \
    --output-path ./docs \
    --hosting-base-path 'Yniffi'
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
# path for generating HTML documentation, however there seems to be some notable
# quirkyness when attempting to build with a binary package. The symbols are 
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

cat docs/linkable-entities.json | jq '.[].referenceURL' -r > all_identifiers.txt
sort all_identifiers.txt \
    | sed -e 's/doc:\/\/com\.github\.y-crdt\.Yniffi\/documentation\///g' \
    | sed -e 's/^/- ``/g' \
    | sed -e 's/$/``/g' > all_symbols.txt

# echo "Page will be available at https://y-crdt.github.io/y-uniffi/documentation/yniffi/"
