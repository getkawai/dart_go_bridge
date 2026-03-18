import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

class LlmBridge {
  LlmBridge._(this._lib) {
    _llmGenerateTextJson = _lib.lookupFunction<
        Pointer<Utf8> Function(Pointer<Utf8>),
        Pointer<Utf8> Function(Pointer<Utf8>)>('LLMGenerateTextJSON');
    _goFreeString = _lib.lookupFunction<Void Function(Pointer<Utf8>),
        void Function(Pointer<Utf8>)>('GoFreeString');
  }

  final DynamicLibrary _lib;
  late final Pointer<Utf8> Function(Pointer<Utf8>) _llmGenerateTextJson;
  late final void Function(Pointer<Utf8>) _goFreeString;

  static LlmBridge create({
    String? androidLibraryPath,
  }) {
    final lib = _openLibrary(androidLibraryPath);
    return LlmBridge._(lib);
  }

  Map<String, dynamic> generateText({
    required String prompt,
    String? system,
    String? taskName,
    int? maxOutputTokens,
    double? temperature,
    double? topP,
    int? topK,
  }) {
    final payload = <String, dynamic>{
      'prompt': prompt,
      if (system != null && system.isNotEmpty) 'system': system,
      if (taskName != null && taskName.isNotEmpty) 'task_name': taskName,
      if (maxOutputTokens != null) 'max_output_tokens': maxOutputTokens,
      if (temperature != null) 'temperature': temperature,
      if (topP != null) 'top_p': topP,
      if (topK != null) 'top_k': topK,
    };

    final response = _callStringToString(_llmGenerateTextJson, jsonEncode(payload));
    return _decodeResponse(response);
  }

  Map<String, dynamic> _decodeResponse(String raw) {
    if (raw.isEmpty) {
      return <String, dynamic>{'ok': false, 'error': 'empty response'};
    }
    return jsonDecode(raw) as Map<String, dynamic>;
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

    throw UnsupportedError('LlmBridge only supports Android and iOS.');
  }
}
