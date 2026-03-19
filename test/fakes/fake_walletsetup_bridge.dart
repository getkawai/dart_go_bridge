import 'package:dart_go_bridge/walletsetup_bridge_interface.dart';

/// In-memory fake for [WalletSetupBridgeInterface].
///
/// By default:
/// - All validation calls return `valid: true`
/// - [passwordStrength] returns score 3 / "Strong"
///
/// Override public fields in each test to simulate different scenarios.
class FakeWalletSetupBridge implements WalletSetupBridgeInterface {
  // ──────────────────────────────────────────────────────────────────
  // Configuration
  // ──────────────────────────────────────────────────────────────────

  /// If non-null, ALL calls return this error.
  String? forceError;

  /// Controls what [validateMnemonic] returns.
  bool mnemonicValid = true;
  String? mnemonicMessage;

  /// Controls what [validateKeystore] returns.
  bool keystoreValid = true;
  String? keystoreMessage;

  /// Controls what [validatePrivateKey] returns.
  bool privateKeyValid = true;
  String? privateKeyMessage;

  /// Controls what [passwordStrength] returns.
  int passwordScore = 3;
  String passwordLabel = 'Strong';
  String passwordColor = '#4CAF50';

  // ──────────────────────────────────────────────────────────────────
  // Call tracking
  // ──────────────────────────────────────────────────────────────────

  final List<String> mnemonicCalls = [];
  final List<String> keystoreCalls = [];
  final List<String> privateKeyCalls = [];
  final List<String> passwordCalls = [];

  // ──────────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────────

  Map<String, dynamic> _err(String msg) =>
      <String, dynamic>{'ok': false, 'error': msg};

  Map<String, dynamic> _validationResult(bool valid, String? message) =>
      <String, dynamic>{
        'ok': true,
        'data': <String, dynamic>{
          'valid': valid,
          if (message != null && message.isNotEmpty) 'message': message,
        },
      };

  // ──────────────────────────────────────────────────────────────────
  // WalletSetupBridgeInterface
  // ──────────────────────────────────────────────────────────────────

  @override
  Map<String, dynamic> validateMnemonic(String mnemonic) {
    mnemonicCalls.add(mnemonic);
    if (forceError != null) return _err(forceError!);
    return _validationResult(mnemonicValid, mnemonicMessage);
  }

  @override
  Map<String, dynamic> validateKeystore(String keystoreJson) {
    keystoreCalls.add(keystoreJson);
    if (forceError != null) return _err(forceError!);
    return _validationResult(keystoreValid, keystoreMessage);
  }

  @override
  Map<String, dynamic> validatePrivateKey(String privateKey) {
    privateKeyCalls.add(privateKey);
    if (forceError != null) return _err(forceError!);
    return _validationResult(privateKeyValid, privateKeyMessage);
  }

  @override
  Map<String, dynamic> passwordStrength(String password) {
    passwordCalls.add(password);
    if (forceError != null) return _err(forceError!);
    return <String, dynamic>{
      'ok': true,
      'data': <String, dynamic>{
        'score': passwordScore,
        'label': passwordLabel,
        'color': passwordColor,
      },
    };
  }
}

/// A [FakeWalletSetupBridge] that bases validation on basic heuristics,
/// useful for testing UI logic that needs realistic accept/reject behaviour.
class HeuristicFakeWalletSetupBridge implements WalletSetupBridgeInterface {
  static const _validWordCount = {12, 15, 18, 21, 24};

  @override
  Map<String, dynamic> validateMnemonic(String mnemonic) {
    final words = mnemonic.trim().split(RegExp(r'\s+'));
    final valid = _validWordCount.contains(words.length);
    return <String, dynamic>{
      'ok': true,
      'data': <String, dynamic>{
        'valid': valid,
        if (!valid) 'message': 'Expected 12/15/18/21/24 words',
      },
    };
  }

  @override
  Map<String, dynamic> validateKeystore(String keystoreJson) {
    final trimmed = keystoreJson.trim();
    final valid = trimmed.startsWith('{') && trimmed.endsWith('}');
    return <String, dynamic>{
      'ok': true,
      'data': <String, dynamic>{
        'valid': valid,
        if (!valid) 'message': 'Not valid JSON',
      },
    };
  }

  @override
  Map<String, dynamic> validatePrivateKey(String privateKey) {
    final hex = privateKey.startsWith('0x')
        ? privateKey.substring(2)
        : privateKey;
    // 64 hex chars = 32 bytes
    final valid =
        hex.length == 64 && RegExp(r'^[0-9a-fA-F]+$').hasMatch(hex);
    return <String, dynamic>{
      'ok': true,
      'data': <String, dynamic>{
        'valid': valid,
        if (!valid) 'message': 'Must be 32-byte hex',
      },
    };
  }

  @override
  Map<String, dynamic> passwordStrength(String password) {
    var score = 0;
    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[^A-Za-z0-9]'))) score++;

    final labels = ['Very Weak', 'Weak', 'Fair', 'Strong', 'Very Strong'];
    final colors = ['#F44336', '#FF9800', '#FFC107', '#4CAF50', '#2196F3'];

    return <String, dynamic>{
      'ok': true,
      'data': <String, dynamic>{
        'score': score,
        'label': labels[score],
        'color': colors[score],
      },
    };
  }
}
