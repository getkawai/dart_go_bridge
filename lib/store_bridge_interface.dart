/// Abstract interface for StoreBridge, enabling mock/fake implementations in tests.
///
/// All methods return a map with:
/// - `ok` (bool): whether the call succeeded
/// - `data` (dynamic): on success, the result payload
/// - `error` (string): on failure, the error message
abstract class StoreBridgeInterface {
  /// Gets the token balance for the given [address].
  Map<String, dynamic> getUserBalance(String address);

  /// Adds [amount] tokens to [address].
  Map<String, dynamic> addBalance(String address, String amount);

  /// Deducts [amount] tokens from [address].
  Map<String, dynamic> deductBalance(String address, String amount);

  /// Transfers [amount] tokens from [from] to [to].
  Map<String, dynamic> transferBalance(String from, String to, String amount);

  /// Creates a new API key tied to [address].
  Map<String, dynamic> createApiKey(String address);

  /// Validates an [apiKey] and returns the associated address.
  Map<String, dynamic> validateApiKey(String apiKey);

  /// Gets contributor details for [address].
  Map<String, dynamic> getContributor(String address);

  /// Lists all contributors.
  Map<String, dynamic> listContributors();

  /// Frees the underlying native store handle.
  void dispose();
}
