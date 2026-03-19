/// Abstract interface for LlmBridge, enabling mock/fake implementations in tests.
abstract class LlmBridgeInterface {
  /// Generates text synchronously and returns the full response.
  ///
  /// Returns a map with:
  /// - `ok` (bool): whether the call succeeded
  /// - `data` (map): on success, contains `text`, `finish_reason`, `usage`, `model`, `provider`
  /// - `error` (string): on failure, contains the error message
  Map<String, dynamic> generateText({
    required String prompt,
    String? system,
    String? taskName,
    int? maxOutputTokens,
    double? temperature,
    double? topP,
    int? topK,
  });

  /// Streams text tokens one by one.
  ///
  /// Each yielded string is a partial text delta from the model.
  /// Throws [StateError] if the underlying Go stream call fails.
  Stream<String> streamText({
    required String prompt,
    String? system,
    String? taskName,
    int? maxOutputTokens,
    double? temperature,
    double? topP,
    int? topK,
  });
}
