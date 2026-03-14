#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
GO_DIR="$ROOT_DIR/native/go"
OUT_DIR="$ROOT_DIR/android/src/main/jniLibs"

if [[ -z "${ANDROID_NDK_HOME:-}" ]]; then
  echo "ANDROID_NDK_HOME is not set." >&2
  exit 1
fi

TOOLCHAIN="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt"
HOST=$(ls "$TOOLCHAIN" | head -n 1)

build_abi() {
  local abi=$1
  local cc_prefix=$2
  local api=$3
  local cc="${TOOLCHAIN}/${HOST}/bin/${cc_prefix}${api}-clang"
  local goarch=$4
  local goarm=${5:-}

  local out="$OUT_DIR/$abi"
  mkdir -p "$out"

  pushd "$GO_DIR" >/dev/null
  envs=(
    "CC=$cc"
    "GOOS=android"
    "GOARCH=$goarch"
    "CGO_ENABLED=1"
  )
  if [[ -n "$goarm" ]]; then
    envs+=("GOARM=$goarm")
  fi
  env "${envs[@]}" go build -buildmode=c-shared -o "$out/libdart_go_bridge.so" .
  popd >/dev/null
}

# Set your minSdkVersion here (match android/build.gradle.kts).
ANDROID_API=24

build_abi arm64-v8a aarch64-linux-android $ANDROID_API arm64
build_abi armeabi-v7a armv7a-linux-androideabi $ANDROID_API arm 7

echo "Built Android libs under $OUT_DIR"
