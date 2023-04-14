#!/bin/bash

set -e  # exit on a non-zero return code from a command
set -x  # print a trace of commands as they execute

rm -rf .build .symbol-graphs
mkdir -p .symbol-graphs

$(xcrun --find swift) build --target Yniffi \
    -Xswiftc -emit-symbol-graph \
    -Xswiftc -emit-symbol-graph-dir -Xswiftc .symbol-graphs

$(xcrun --find docc) convert swift/scaffold/Documentation.docc \
    --analyze \
    --fallback-display-name Yniffi \
    --fallback-bundle-identifier com.github.y-crdt.Yniffi \
    --fallback-bundle-version 0.16.1 \
    --additional-symbol-graph-dir .symbol-graphs \
    --experimental-documentation-coverage \
    --level brief
