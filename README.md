# dart_go_bridge

Dart/Flutter FFI bridge for a Go shared library on Android and iOS.

This project wires a minimal Go function (`GoWebSearchJSON`) into Dart using `dart:ffi`.

## Quick Start

### 1) Build native libraries

Android (requires `ANDROID_NDK_HOME`):

```bash
./scripts/build_android.sh
```

iOS (requires Xcode command line tools):

```bash
./scripts/build_ios.sh
```

### 2) Run the example app

```bash
cd example
flutter run
```

You should see `GoAdd(2, 3) = 5` and a stripped string output.

## Go source

The Go bridge lives at:

- `native/go/bridge.go` (exports `GoWebSearchJSON`)

It calls into the `tools` repo via `github.com/getkawai/tools/mobilebridge`.

## Notes

- Android builds produce `android/src/main/jniLibs/<abi>/libdart_go_bridge.so`.
- iOS builds produce `ios/DartGoBridge.xcframework`, linked via the podspec.
