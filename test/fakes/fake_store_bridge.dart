import 'package:dart_go_bridge/store_bridge_interface.dart';

/// In-memory fake for [StoreBridgeInterface] — safe to use in flutter tests
/// without needing the native Go shared library.
///
/// Balances are stored as strings representing integers (matching the real
/// API which uses Go's big.Int serialised as a string/decimal).
class FakeStoreBridge implements StoreBridgeInterface {
  final Map<String, int> _balances = {};
  final Map<String, String> _apiKeys = {}; // address -> apiKey
  final Map<String, String> _apiKeyIndex = {}; // apiKey -> address
  final Map<String, Map<String, dynamic>> _contributors = {};

  bool disposed = false;

  /// If non-null, ALL calls will return this error instead of succeeding.
  String? forceError;

  // ──────────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────────

  Map<String, dynamic> _error(String msg) =>
      <String, dynamic>{'ok': false, 'error': msg};

  Map<String, dynamic> _ok([dynamic data]) => <String, dynamic>{
        'ok': true,
        if (data != null) 'data': data,
      };

  int _balance(String address) => _balances[address] ?? 0;

  // ──────────────────────────────────────────────────────────────────
  // StoreBridgeInterface implementation
  // ──────────────────────────────────────────────────────────────────

  @override
  Map<String, dynamic> getUserBalance(String address) {
    if (forceError != null) return _error(forceError!);
    return _ok(_balance(address).toString());
  }

  @override
  Map<String, dynamic> addBalance(String address, String amount) {
    if (forceError != null) return _error(forceError!);
    final v = int.tryParse(amount);
    if (v == null) return _error('invalid amount');
    _balances[address] = _balance(address) + v;
    return _ok();
  }

  @override
  Map<String, dynamic> deductBalance(String address, String amount) {
    if (forceError != null) return _error(forceError!);
    final v = int.tryParse(amount);
    if (v == null) return _error('invalid amount');
    final current = _balance(address);
    if (current < v) return _error('insufficient balance');
    _balances[address] = current - v;
    return _ok();
  }

  @override
  Map<String, dynamic> transferBalance(String from, String to, String amount) {
    if (forceError != null) return _error(forceError!);
    final v = int.tryParse(amount);
    if (v == null) return _error('invalid amount');
    final fromBalance = _balance(from);
    if (fromBalance < v) return _error('insufficient balance');
    _balances[from] = fromBalance - v;
    _balances[to] = _balance(to) + v;
    return _ok();
  }

  @override
  Map<String, dynamic> createApiKey(String address) {
    if (forceError != null) return _error(forceError!);
    // Return existing key if one already exists for this address
    if (_apiKeys.containsKey(address)) {
      return _ok(_apiKeys[address]);
    }
    final key = 'fake-api-key-$address-${_apiKeys.length}';
    _apiKeys[address] = key;
    _apiKeyIndex[key] = address;
    return _ok(key);
  }

  @override
  Map<String, dynamic> validateApiKey(String apiKey) {
    if (forceError != null) return _error(forceError!);
    final address = _apiKeyIndex[apiKey];
    if (address == null) return _error('invalid api key');
    return _ok(address);
  }

  @override
  Map<String, dynamic> getContributor(String address) {
    if (forceError != null) return _error(forceError!);
    final contributor = _contributors[address];
    if (contributor == null) return _error('contributor not found');
    return _ok(contributor);
  }

  /// Seeds a contributor record for testing [getContributor].
  void seedContributor(String address, Map<String, dynamic> data) {
    _contributors[address] = data;
  }

  @override
  Map<String, dynamic> listContributors() {
    if (forceError != null) return _error(forceError!);
    return _ok(_contributors.values.toList());
  }

  @override
  void dispose() {
    disposed = true;
  }

  // ──────────────────────────────────────────────────────────────────
  // Test utilities
  // ──────────────────────────────────────────────────────────────────

  /// Directly set balance for testing without going through [addBalance].
  void setBalance(String address, int amount) {
    _balances[address] = amount;
  }

  /// Returns the internal balance (as int) for assertion convenience.
  int rawBalance(String address) => _balance(address);
}
