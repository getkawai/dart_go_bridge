import 'package:dart_go_bridge/llm_bridge_interface.dart';

/// Minimal fake LlmBridge for use in example/ widget tests.
/// Full-featured version lives in the parent package's test/fakes/.
class FakeLlmBridge implements LlmBridgeInterface {
  String fakeResponseText = 'LLM response from fake';
  String? fakeError;
  List<String> fakeStreamChunks = ['Streaming ', 'from ', 'fake!'];

  int generateTextCallCount = 0;

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
    if (fakeError != null) {
      return <String, dynamic>{'ok': false, 'error': fakeError};
    }
    return <String, dynamic>{
      'ok': true,
      'data': {'text': fakeResponseText, 'finish_reason': 'stop'},
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
    if (fakeError != null) throw StateError(fakeError!);
    for (final chunk in fakeStreamChunks) {
      yield chunk;
    }
  }
}
