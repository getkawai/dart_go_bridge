import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

class LlmBridge {
  LlmBridge._(this._lib) {
    _llmGenerateTextJson = _lib.lookupFunction<
        Pointer<Utf8> Function(Pointer<Utf8>),
        Pointer<Utf8> Function(Pointer<Utf8>)>('LLMGenerateTextJSON');
    _llmStreamStartJson = _lib.lookupFunction<
        Pointer<Utf8> Function(Pointer<Utf8>),
        Pointer<Utf8> Function(Pointer<Utf8>)>('LLMStreamStartJSON');
    _llmStreamNextJson = _lib.lookupFunction<
        Pointer<Utf8> Function(Uint64),
        Pointer<Utf8> Function(int)>('LLMStreamNextJSON');
    _llmStreamFree = _lib.lookupFunction<Void Function(Uint64), void Function(int)>(
        'LLMStreamFree');
    _goFreeString = _lib.lookupFunction<Void Function(Pointer<Utf8>),
        void Function(Pointer<Utf8>)>('GoFreeString');
  }

  final DynamicLibrary _lib;
  late final Pointer<Utf8> Function(Pointer<Utf8>) _llmGenerateTextJson;
  late final Pointer<Utf8> Function(Pointer<Utf8>) _llmStreamStartJson;
  late final Pointer<Utf8> Function(int) _llmStreamNextJson;
  late final void Function(int) _llmStreamFree;
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

  Stream<String> streamText({
    required String prompt,
    String? system,
    String? taskName,
    int? maxOutputTokens,
    double? temperature,
    double? topP,
    int? topK,
  }) async* {
    final payload = <String, dynamic>{
      'prompt': prompt,
      if (system != null && system.isNotEmpty) 'system': system,
      if (taskName != null && taskName.isNotEmpty) 'task_name': taskName,
      if (maxOutputTokens != null) 'max_output_tokens': maxOutputTokens,
      if (temperature != null) 'temperature': temperature,
      if (topP != null) 'top_p': topP,
      if (topK != null) 'top_k': topK,
    };

    final startResponse =
        _decodeResponse(_callStringToString(_llmStreamStartJson, jsonEncode(payload)));
    if (startResponse['ok'] != true) {
      throw StateError(startResponse['error']?.toString() ?? 'LLMStreamStartJSON failed');
    }

    final handle = startResponse['handle'];
    if (handle is! int) {
      throw StateError('LLMStreamStartJSON returned invalid handle');
    }

    try {
      while (true) {
        final raw = _callStringToString0(_llmStreamNextJson, handle);
        final decoded = _decodeResponse(raw);
        if (decoded['ok'] != true) {
          throw StateError(decoded['error']?.toString() ?? 'LLMStreamNextJSON failed');
        }
        final data = decoded['data'];
        if (data is Map && data['done'] == true) {
          break;
        }
        if (data is Map && data['text'] is String) {
          final text = data['text'] as String;
          if (text.isNotEmpty) {
            yield text;
          }
        }
      }
    } finally {
      _llmStreamFree(handle);
    }
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

  String _callStringToString0(Pointer<Utf8> Function(int) fn, int handle) {
    final resultPtr = fn(handle);
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
