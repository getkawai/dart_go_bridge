import 'dart:math';

import 'package:dart_go_bridge/llm_bridge_interface.dart';

/// In-memory fake for [LlmBridgeInterface] — safe to use in flutter tests
/// without needing the native Go shared library.
class FakeLlmBridge implements LlmBridgeInterface {
  /// The canned response returned by [generateText].
  /// Override this in your test to simulate different responses.
  String fakeResponseText = 'Hello from FakeLlmBridge!';

  /// If non-null, [generateText] will throw / return an error response.
  String? fakeError;

  /// The token chunks [streamText] will yield, in order.
  List<String> fakeStreamChunks = ['Hello ', 'from ', 'stream!'];

  /// If non-null, [streamText] will throw a [StateError] after yielding
  /// [streamErrorAfterChunks] chunks.
  String? fakeStreamError;

  /// Number of chunks to yield before emitting [fakeStreamError].
  int streamErrorAfterChunks = 0;

  /// Counts how many times [generateText] was called.
  int generateTextCallCount = 0;

  /// Counts how many times [streamText] was called.
  int streamTextCallCount = 0;

  /// The last call args passed to [generateText].
  Map<String, dynamic>? lastGenerateTextArgs;

  @override
  Map<String, dynamic> generateText({
    required String prompt,
    String? system,
    String? taskName,
    int? maxOutputTokens,
    double? temperature,
    double? topP,
    int? topK,
  }) {
    generateTextCallCount++;
    lastGenerateTextArgs = {
      'prompt': prompt,
      if (system != null) 'system': system,
      if (taskName != null) 'taskName': taskName,
      if (maxOutputTokens != null) 'maxOutputTokens': maxOutputTokens,
      if (temperature != null) 'temperature': temperature,
      if (topP != null) 'topP': topP,
      if (topK != null) 'topK': topK,
    };

    if (fakeError != null) {
      return <String, dynamic>{'ok': false, 'error': fakeError};
    }

    return <String, dynamic>{
      'ok': true,
      'data': {
        'text': fakeResponseText,
        'finish_reason': 'stop',
        'usage': {'input_tokens': 10, 'output_tokens': 5},
        'model': 'fake-model',
        'provider': 'fake-provider',
      },
    };
  }

  @override
  Stream<String> streamText({
    required String prompt,
    String? system,
    String? taskName,
    int? maxOutputTokens,
    double? temperature,
    double? topP,
    int? topK,
  }) async* {
    streamTextCallCount++;

    if (fakeError != null) {
      throw StateError(fakeError!);
    }

    for (var i = 0; i < fakeStreamChunks.length; i++) {
      if (fakeStreamError != null && i >= streamErrorAfterChunks) {
        throw StateError(fakeStreamError!);
      }
      yield fakeStreamChunks[i];
    }
  }
}

/// A [FakeLlmBridge] that simulates a slow network by introducing artificial
/// delays between stream chunks.
class SlowFakeLlmBridge extends FakeLlmBridge {
  SlowFakeLlmBridge({this.chunkDelayMs = 10});

  final int chunkDelayMs;

  @override
  Stream<String> streamText({
    required String prompt,
    String? system,
    String? taskName,
    int? maxOutputTokens,
    double? temperature,
    double? topP,
    int? topK,
  }) async* {
    streamTextCallCount++;
    for (final chunk in fakeStreamChunks) {
      await Future<void>.delayed(Duration(milliseconds: chunkDelayMs));
      yield chunk;
    }
  }
}

/// A [FakeLlmBridge] that returns a random response of [wordCount] words.
class RandomFakeLlmBridge extends FakeLlmBridge {
  RandomFakeLlmBridge({this.wordCount = 5, int? seed})
      : _rng = Random(seed);

  final int wordCount;
  final Random _rng;

  static const _words = [
    'the', 'quick', 'brown', 'fox', 'jumps', 'over', 'lazy', 'dog',
    'hello', 'world', 'test', 'fake', 'model', 'response', 'stream',
  ];

  @override
  Map<String, dynamic> generateText({
    required String prompt,
    String? system,
    String? taskName,
    int? maxOutputTokens,
    double? temperature,
    double? topP,
    int? topK,
  }) {
    generateTextCallCount++;
    final text = List.generate(
      wordCount,
      (_) => _words[_rng.nextInt(_words.length)],
    ).join(' ');

    return <String, dynamic>{
      'ok': true,
      'data': {
        'text': text,
        'finish_reason': 'stop',
        'usage': {'input_tokens': prompt.length, 'output_tokens': wordCount},
        'model': 'random-fake-model',
        'provider': 'fake-provider',
      },
    };
  }
}
