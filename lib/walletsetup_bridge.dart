import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

import 'walletsetup_bridge_interface.dart';

class WalletSetupBridge implements WalletSetupBridgeInterface {
  WalletSetupBridge._(this._lib) {
    _walletValidateMnemonicJson = _lib.lookupFunction<
        Pointer<Utf8> Function(Pointer<Utf8>),
        Pointer<Utf8> Function(Pointer<Utf8>)>('WalletValidateMnemonicJSON');
    _walletValidateKeystoreJson = _lib.lookupFunction<
        Pointer<Utf8> Function(Pointer<Utf8>),
        Pointer<Utf8> Function(Pointer<Utf8>)>('WalletValidateKeystoreJSON');
    _walletValidatePrivateKeyJson = _lib.lookupFunction<
        Pointer<Utf8> Function(Pointer<Utf8>),
        Pointer<Utf8> Function(Pointer<Utf8>)>('WalletValidatePrivateKeyJSON');
    _walletPasswordStrengthJson = _lib.lookupFunction<
        Pointer<Utf8> Function(Pointer<Utf8>),
        Pointer<Utf8> Function(Pointer<Utf8>)>('WalletPasswordStrengthJSON');
    _goFreeString = _lib.lookupFunction<Void Function(Pointer<Utf8>),
        void Function(Pointer<Utf8>)>('GoFreeString');
  }

  final DynamicLibrary _lib;
  late final Pointer<Utf8> Function(Pointer<Utf8>) _walletValidateMnemonicJson;
  late final Pointer<Utf8> Function(Pointer<Utf8>) _walletValidateKeystoreJson;
  late final Pointer<Utf8> Function(Pointer<Utf8>) _walletValidatePrivateKeyJson;
  late final Pointer<Utf8> Function(Pointer<Utf8>) _walletPasswordStrengthJson;
  late final void Function(Pointer<Utf8>) _goFreeString;

  static WalletSetupBridge create({
    String? androidLibraryPath,
  }) {
    final lib = _openLibrary(androidLibraryPath);
    return WalletSetupBridge._(lib);
  }

  Map<String, dynamic> validateMnemonic(String mnemonic) {
    return _callJson(_walletValidateMnemonicJson, mnemonic);
  }

  Map<String, dynamic> validateKeystore(String keystoreJson) {
    return _callJson(_walletValidateKeystoreJson, keystoreJson);
  }

  Map<String, dynamic> validatePrivateKey(String privateKey) {
    return _callJson(_walletValidatePrivateKeyJson, privateKey);
  }

  Map<String, dynamic> passwordStrength(String password) {
    return _callJson(_walletPasswordStrengthJson, password);
  }

  Map<String, dynamic> _callJson(
    Pointer<Utf8> Function(Pointer<Utf8>) fn,
    String input,
  ) {
    final response = _callStringToString(fn, input);
    if (response.isEmpty) {
      return <String, dynamic>{'ok': false, 'error': 'empty response'};
    }
    return jsonDecode(response) as Map<String, dynamic>;
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
      final path = androidLibraryPath ?? 'libdart_go_bridge.so';
      return DynamicLibrary.open(path);
    }

    if (Platform.isIOS) {
      return DynamicLibrary.process();
    }

    throw UnsupportedError('WalletSetupBridge only supports Android and iOS.');
  }
}
