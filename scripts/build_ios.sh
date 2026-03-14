#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
GO_DIR="$ROOT_DIR/native/go"
OUT_DIR="$ROOT_DIR/ios"

build_ios() {
  local arch=$1
  local sdk=$2
  local suffix=$3
  local out="$OUT_DIR/libdart_go_bridge_${suffix}.a"
  local sdkroot
  local cc
  sdkroot=$(xcrun --sdk "$sdk" --show-sdk-path)
  cc=$(xcrun --sdk "$sdk" --find clang)

  pushd "$GO_DIR" >/dev/null
  env \
    SDKROOT="$sdkroot" \
    CC="$cc -isysroot $sdkroot" \
    CGO_CFLAGS="-isysroot $sdkroot" \
    CGO_CPPFLAGS="-isysroot $sdkroot" \
    CGO_LDFLAGS="-isysroot $sdkroot" \
    CGO_ENABLED=1 GOOS=ios GOARCH="$arch" \
    go build -buildmode=c-archive -o "$out" .
  popd >/dev/null
}

mkdir -p "$OUT_DIR"

build_ios arm64 iphoneos device
build_ios arm64 iphonesimulator sim

rm -rf "$OUT_DIR/DartGoBridge.xcframework"

xcodebuild -create-xcframework \
  -library "$OUT_DIR/libdart_go_bridge_device.a" -headers "$OUT_DIR/libdart_go_bridge_device.h" \
  -library "$OUT_DIR/libdart_go_bridge_sim.a" -headers "$OUT_DIR/libdart_go_bridge_sim.h" \
  -output "$OUT_DIR/DartGoBridge.xcframework"

rm -f "$OUT_DIR/libdart_go_bridge_device.a" \
  "$OUT_DIR/libdart_go_bridge_sim.a" \
  "$OUT_DIR/libdart_go_bridge_device.h" \
  "$OUT_DIR/libdart_go_bridge_sim.h"

echo "Built iOS XCFramework at $OUT_DIR/DartGoBridge.xcframework"
