/// Abstract interface for WalletSetupBridge, enabling mock/fake in tests.
///
/// All methods return a map with:
/// - `ok` (bool): whether the native call succeeded
/// - `data` (map): on success, the result payload
/// - `error` (string): on failure, the error message
abstract class WalletSetupBridgeInterface {
  /// Validates a BIP-39 mnemonic phrase.
  ///
  /// `data` contains:
  /// - `valid` (bool): whether the mnemonic is valid
  /// - `message` (string, optional): explanation when invalid
  Map<String, dynamic> validateMnemonic(String mnemonic);

  /// Validates a JSON keystore string (Ethereum / EIP-55).
  ///
  /// `data` contains:
  /// - `valid` (bool): whether the keystore JSON is valid
  /// - `message` (string, optional): explanation when invalid
  Map<String, dynamic> validateKeystore(String keystoreJson);

  /// Validates a hex-encoded private key.
  ///
  /// `data` contains:
  /// - `valid` (bool): whether the private key is valid
  /// - `message` (string, optional): explanation when invalid
  Map<String, dynamic> validatePrivateKey(String privateKey);

  /// Evaluates password strength.
  ///
  /// `data` contains:
  /// - `score` (int): 0–4 strength score
  /// - `label` (string): e.g. "Very Weak", "Weak", "Fair", "Strong", "Very Strong"
  /// - `color` (string): hex colour hint for the UI
  Map<String, dynamic> passwordStrength(String password);
}
