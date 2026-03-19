import 'package:dart_go_bridge/store_bridge_interface.dart';

/// Minimal fake StoreBridge for use in example/ widget tests.
class FakeStoreBridge implements StoreBridgeInterface {
  final Map<String, int> _balances = {};
  String? forceError;
  bool disposed = false;

  Map<String, dynamic> _err(String msg) =>
      <String, dynamic>{'ok': false, 'error': msg};

  Map<String, dynamic> _ok([dynamic data]) => <String, dynamic>{
        'ok': true,
        if (data != null) 'data': data,
      };

  @override
  Map<String, dynamic> getUserBalance(String address) {
    if (forceError != null) return _err(forceError!);
    return _ok((_balances[address] ?? 0).toString());
  }

  @override
  Map<String, dynamic> addBalance(String address, String amount) {
    if (forceError != null) return _err(forceError!);
    final v = int.tryParse(amount);
    if (v == null) return _err('invalid amount');
    _balances[address] = (_balances[address] ?? 0) + v;
    return _ok();
  }

  @override
  Map<String, dynamic> deductBalance(String address, String amount) {
    if (forceError != null) return _err(forceError!);
    final v = int.tryParse(amount);
    if (v == null) return _err('invalid amount');
    final cur = _balances[address] ?? 0;
    if (cur < v) return _err('insufficient balance');
    _balances[address] = cur - v;
    return _ok();
  }

  @override
  Map<String, dynamic> transferBalance(String from, String to, String amount) {
    if (forceError != null) return _err(forceError!);
    final v = int.tryParse(amount);
    if (v == null) return _err('invalid amount');
    final cur = _balances[from] ?? 0;
    if (cur < v) return _err('insufficient balance');
    _balances[from] = cur - v;
    _balances[to] = (_balances[to] ?? 0) + v;
    return _ok();
  }

  @override
  Map<String, dynamic> createApiKey(String address) {
    if (forceError != null) return _err(forceError!);
    return _ok('fake-key-$address');
  }

  @override
  Map<String, dynamic> validateApiKey(String apiKey) {
    if (forceError != null) return _err(forceError!);
    return _ok('fake-address');
  }

  @override
  Map<String, dynamic> getContributor(String address) {
    if (forceError != null) return _err(forceError!);
    return _err('contributor not found');
  }

  @override
  Map<String, dynamic> listContributors() {
    if (forceError != null) return _err(forceError!);
    return _ok(<dynamic>[]);
  }

  @override
  void dispose() {
    disposed = true;
  }
}
