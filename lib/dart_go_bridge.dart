import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

class DartGoBridge {
  DartGoBridge({String? androidLibraryPath})
      : _lib = _openLibrary(androidLibraryPath);

  late final DynamicLibrary _lib;

  late final Pointer<Utf8> Function(Pointer<Utf8>) _goWebSearchJson =
      _lib.lookupFunction<
          Pointer<Utf8> Function(Pointer<Utf8>),
          Pointer<Utf8> Function(Pointer<Utf8>)>('GoWebSearchJSON');

  late final void Function(Pointer<Utf8>) _goFreeString = _lib.lookupFunction<
      Void Function(Pointer<Utf8>),
      void Function(Pointer<Utf8>)>('GoFreeString');

  String webSearchJson(String query) {
    return _callStringToString(_goWebSearchJson, query);
  }

  String _callStringToString(
    Pointer<Utf8> Function(Pointer<Utf8>) fn,
    String input,
  ) {
    final inputPtr = input.toNativeUtf8();
    final resultPtr = fn(inputPtr);
    malloc.free(inputPtr);
    if (resultPtr.address == 0) {
      return '';
    }
    final result = resultPtr.toDartString();
    _goFreeString(resultPtr);
    return result;
  }

  static DynamicLibrary _openLibrary(String? androidLibraryPath) {
    if (Platform.isAndroid) {
      // Default name for the shared lib placed in jniLibs.
      final path = androidLibraryPath ?? 'libdart_go_bridge.so';
      return DynamicLibrary.open(path);
    }

    if (Platform.isIOS) {
      // iOS links the static library into the process.
      return DynamicLibrary.process();
    }

    throw UnsupportedError('DartGoBridge only supports Android and iOS.');
  }
}
