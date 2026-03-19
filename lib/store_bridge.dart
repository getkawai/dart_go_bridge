import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

import 'store_bridge_interface.dart';

class StoreBridge implements StoreBridgeInterface {
  StoreBridge._(this._lib, this._handle) {
    _storeGetUserBalanceJson = _lib.lookupFunction<
        Pointer<Utf8> Function(Uint64, Pointer<Utf8>),
        Pointer<Utf8> Function(int, Pointer<Utf8>)>('StoreGetUserBalanceJSON');
    _storeAddBalanceJson = _lib.lookupFunction<
        Pointer<Utf8> Function(Uint64, Pointer<Utf8>, Pointer<Utf8>),
        Pointer<Utf8> Function(int, Pointer<Utf8>, Pointer<Utf8>)>('StoreAddBalanceJSON');
    _storeDeductBalanceJson = _lib.lookupFunction<
        Pointer<Utf8> Function(Uint64, Pointer<Utf8>, Pointer<Utf8>),
        Pointer<Utf8> Function(int, Pointer<Utf8>, Pointer<Utf8>)>('StoreDeductBalanceJSON');
    _storeTransferBalanceJson = _lib.lookupFunction<
        Pointer<Utf8> Function(Uint64, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>),
        Pointer<Utf8> Function(int, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>)>('StoreTransferBalanceJSON');
    _storeCreateApiKeyJson = _lib.lookupFunction<
        Pointer<Utf8> Function(Uint64, Pointer<Utf8>),
        Pointer<Utf8> Function(int, Pointer<Utf8>)>('StoreCreateAPIKeyJSON');
    _storeValidateApiKeyJson = _lib.lookupFunction<
        Pointer<Utf8> Function(Uint64, Pointer<Utf8>),
        Pointer<Utf8> Function(int, Pointer<Utf8>)>('StoreValidateAPIKeyJSON');
    _storeGetContributorJson = _lib.lookupFunction<
        Pointer<Utf8> Function(Uint64, Pointer<Utf8>),
        Pointer<Utf8> Function(int, Pointer<Utf8>)>('StoreGetContributorJSON');
    _storeListContributorsJson = _lib.lookupFunction<
        Pointer<Utf8> Function(Uint64),
        Pointer<Utf8> Function(int)>('StoreListContributorsJSON');

    _storeFree = _lib.lookupFunction<Void Function(Uint64), void Function(int)>(
        'StoreFree');
    _goFreeString = _lib.lookupFunction<Void Function(Pointer<Utf8>),
        void Function(Pointer<Utf8>)>('GoFreeString');
  }

  final DynamicLibrary _lib;
  int _handle;

  late final Pointer<Utf8> Function(int, Pointer<Utf8>) _storeGetUserBalanceJson;
  late final Pointer<Utf8> Function(int, Pointer<Utf8>, Pointer<Utf8>)
      _storeAddBalanceJson;
  late final Pointer<Utf8> Function(int, Pointer<Utf8>, Pointer<Utf8>)
      _storeDeductBalanceJson;
  late final Pointer<Utf8> Function(int, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>)
      _storeTransferBalanceJson;
  late final Pointer<Utf8> Function(int, Pointer<Utf8>) _storeCreateApiKeyJson;
  late final Pointer<Utf8> Function(int, Pointer<Utf8>) _storeValidateApiKeyJson;
  late final Pointer<Utf8> Function(int, Pointer<Utf8>) _storeGetContributorJson;
  late final Pointer<Utf8> Function(int) _storeListContributorsJson;

  late final void Function(int) _storeFree;
  late final void Function(Pointer<Utf8>) _goFreeString;

  static StoreBridge create({
    String? androidLibraryPath,
  }) {
    final lib = _openLibrary(androidLibraryPath);
    final storeNewJson = lib.lookupFunction<
        Pointer<Utf8> Function(Pointer<Utf8>),
        Pointer<Utf8> Function(Pointer<Utf8>)>('StoreNewJSON');
    final goFreeString = lib.lookupFunction<Void Function(Pointer<Utf8>),
        void Function(Pointer<Utf8>)>('GoFreeString');

    final response =
        _callStringToStringStatic(storeNewJson, goFreeString, '');
    final decoded = jsonDecode(response) as Map<String, dynamic>;
    if (decoded['ok'] != true) {
      throw StateError(decoded['error']?.toString() ?? 'StoreNewJSON failed');
    }

    final handle = decoded['handle'];
    if (handle is! int) {
      throw StateError('StoreNewJSON returned invalid handle');
    }

    return StoreBridge._(lib, handle);
  }

  Map<String, dynamic> getUserBalance(String address) {
    return _callJson1(_storeGetUserBalanceJson, address);
  }

  Map<String, dynamic> addBalance(String address, String amount) {
    return _callJson2(_storeAddBalanceJson, address, amount);
  }

  Map<String, dynamic> deductBalance(String address, String amount) {
    return _callJson2(_storeDeductBalanceJson, address, amount);
  }

  Map<String, dynamic> transferBalance(String from, String to, String amount) {
    return _callJson3(_storeTransferBalanceJson, from, to, amount);
  }

  Map<String, dynamic> createApiKey(String address) {
    return _callJson1(_storeCreateApiKeyJson, address);
  }

  Map<String, dynamic> validateApiKey(String apiKey) {
    return _callJson1(_storeValidateApiKeyJson, apiKey);
  }

  Map<String, dynamic> getContributor(String address) {
    return _callJson1(_storeGetContributorJson, address);
  }

  Map<String, dynamic> listContributors() {
    return _callJson0(_storeListContributorsJson);
  }

  void dispose() {
    if (_handle == 0) {
      return;
    }
    _storeFree(_handle);
    _handle = 0;
  }

  Map<String, dynamic> _callJson0(Pointer<Utf8> Function(int) fn) {
    final result = _callStringToString0(fn, _handle);
    return _decodeResponse(result);
  }

  Map<String, dynamic> _callJson1(
      Pointer<Utf8> Function(int, Pointer<Utf8>) fn, String arg) {
    final result = _callStringToString1(fn, arg);
    return _decodeResponse(result);
  }

  Map<String, dynamic> _callJson2(
      Pointer<Utf8> Function(int, Pointer<Utf8>, Pointer<Utf8>) fn,
      String arg1,
      String arg2) {
    final result = _callStringToString2(fn, arg1, arg2);
    return _decodeResponse(result);
  }

  Map<String, dynamic> _callJson3(
      Pointer<Utf8> Function(int, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>) fn,
      String arg1,
      String arg2,
      String arg3) {
    final result = _callStringToString3(fn, arg1, arg2, arg3);
    return _decodeResponse(result);
  }

  Map<String, dynamic> _decodeResponse(String raw) {
    if (raw.isEmpty) {
      return <String, dynamic>{'ok': false, 'error': 'empty response'};
    }
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  String _callStringToString0(Pointer<Utf8> Function(int) fn, int handle) {
    final resultPtr = fn(handle);
    if (resultPtr.address == 0) {
      return '';
    }
    final result = resultPtr.toDartString();
    _goFreeString(resultPtr);
    return result;
  }

  String _callStringToString1(
      Pointer<Utf8> Function(int, Pointer<Utf8>) fn, String input) {
    final inputPtr = input.toNativeUtf8();
    final resultPtr = fn(_handle, inputPtr);
    malloc.free(inputPtr);
    if (resultPtr.address == 0) {
      return '';
    }
    final result = resultPtr.toDartString();
    _goFreeString(resultPtr);
    return result;
  }

  String _callStringToString2(
      Pointer<Utf8> Function(int, Pointer<Utf8>, Pointer<Utf8>) fn,
      String input1,
      String input2) {
    final inputPtr1 = input1.toNativeUtf8();
    final inputPtr2 = input2.toNativeUtf8();
    final resultPtr = fn(_handle, inputPtr1, inputPtr2);
    malloc.free(inputPtr1);
    malloc.free(inputPtr2);
    if (resultPtr.address == 0) {
      return '';
    }
    final result = resultPtr.toDartString();
    _goFreeString(resultPtr);
    return result;
  }

  String _callStringToString3(
      Pointer<Utf8> Function(int, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>) fn,
      String input1,
      String input2,
      String input3) {
    final inputPtr1 = input1.toNativeUtf8();
    final inputPtr2 = input2.toNativeUtf8();
    final inputPtr3 = input3.toNativeUtf8();
    final resultPtr = fn(_handle, inputPtr1, inputPtr2, inputPtr3);
    malloc.free(inputPtr1);
    malloc.free(inputPtr2);
    malloc.free(inputPtr3);
    if (resultPtr.address == 0) {
      return '';
    }
    final result = resultPtr.toDartString();
    _goFreeString(resultPtr);
    return result;
  }

  static String _callStringToStringStatic(
    Pointer<Utf8> Function(Pointer<Utf8>) fn,
    void Function(Pointer<Utf8>) goFreeString,
    String input,
  ) {
    final inputPtr = input.toNativeUtf8();
    final resultPtr = fn(inputPtr);
    malloc.free(inputPtr);
    if (resultPtr.address == 0) {
      return '';
    }
    final result = resultPtr.toDartString();
    goFreeString(resultPtr);
    return result;
  }

  static DynamicLibrary _openLibrary(String? androidLibraryPath) {
    if (Platform.isAndroid) {
      final path = androidLibraryPath ?? 'libdart_go_bridge.so';
      return DynamicLibrary.open(path);
    }

    if (Platform.isIOS) {
      return DynamicLibrary.process();
    }

    throw UnsupportedError('StoreBridge only supports Android and iOS.');
  }
}
