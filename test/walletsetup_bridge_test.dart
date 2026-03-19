import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_walletsetup_bridge.dart';

void main() {
  // ════════════════════════════════════════════════════════════════════
  // FakeWalletSetupBridge
  // ════════════════════════════════════════════════════════════════════

  group('FakeWalletSetupBridge – validateMnemonic', () {
    late FakeWalletSetupBridge wallet;

    setUp(() => wallet = FakeWalletSetupBridge());

    test('returns ok:true and valid:true by default', () {
      final result = wallet.validateMnemonic('word1 word2 word3');

      expect(result['ok'], isTrue);
      expect((result['data'] as Map)['valid'], isTrue);
    });

    test('returns valid:false when configured', () {
      wallet.mnemonicValid = false;
      wallet.mnemonicMessage = 'invalid word count';

      final result = wallet.validateMnemonic('bad mnemonic');

      expect(result['ok'], isTrue);
      expect((result['data'] as Map)['valid'], isFalse);
      expect((result['data'] as Map)['message'], 'invalid word count');
    });

    test('returns ok:false when forceError is set', () {
      wallet.forceError = 'native error';

      final result = wallet.validateMnemonic('anything');

      expect(result['ok'], isFalse);
      expect(result['error'], 'native error');
    });

    test('tracks all mnemonic calls', () {
      wallet.validateMnemonic('first call');
      wallet.validateMnemonic('second call');

      expect(wallet.mnemonicCalls, ['first call', 'second call']);
    });

    test('does not include message key when message is null', () {
      wallet.mnemonicMessage = null;

      final data = wallet.validateMnemonic('hello')['data'] as Map;

      expect(data.containsKey('message'), isFalse);
    });
  });

  group('FakeWalletSetupBridge – validateKeystore', () {
    late FakeWalletSetupBridge wallet;

    setUp(() => wallet = FakeWalletSetupBridge());

    test('returns valid:true by default', () {
      final result = wallet.validateKeystore('{}');

      expect(result['ok'], isTrue);
      expect((result['data'] as Map)['valid'], isTrue);
    });

    test('returns valid:false with message when configured', () {
      wallet.keystoreValid = false;
      wallet.keystoreMessage = 'missing version field';

      final result = wallet.validateKeystore('bad json');

      expect((result['data'] as Map)['valid'], isFalse);
      expect((result['data'] as Map)['message'], 'missing version field');
    });

    test('tracks keystoreCalls', () {
      wallet.validateKeystore('ks1');
      wallet.validateKeystore('ks2');

      expect(wallet.keystoreCalls, ['ks1', 'ks2']);
    });

    test('forceError overrides keystore validation', () {
      wallet.forceError = 'bridge unavailable';

      expect(wallet.validateKeystore('{}')['ok'], isFalse);
    });
  });

  group('FakeWalletSetupBridge – validatePrivateKey', () {
    late FakeWalletSetupBridge wallet;

    setUp(() => wallet = FakeWalletSetupBridge());

    test('returns valid:true by default', () {
      final result = wallet.validatePrivateKey('0xdeadbeef');

      expect(result['ok'], isTrue);
      expect((result['data'] as Map)['valid'], isTrue);
    });

    test('returns valid:false when configured', () {
      wallet.privateKeyValid = false;
      wallet.privateKeyMessage = 'wrong length';

      final result = wallet.validatePrivateKey('short');

      expect((result['data'] as Map)['valid'], isFalse);
      expect((result['data'] as Map)['message'], 'wrong length');
    });

    test('tracks privateKeyCalls', () {
      wallet.validatePrivateKey('key1');
      wallet.validatePrivateKey('key2');

      expect(wallet.privateKeyCalls, ['key1', 'key2']);
    });

    test('forceError overrides private key validation', () {
      wallet.forceError = 'error';

      expect(wallet.validatePrivateKey('key')['ok'], isFalse);
    });
  });

  group('FakeWalletSetupBridge – passwordStrength', () {
    late FakeWalletSetupBridge wallet;

    setUp(() => wallet = FakeWalletSetupBridge());

    test('returns default score 3 / Strong', () {
      final result = wallet.passwordStrength('mypassword');
      final data = result['data'] as Map;

      expect(result['ok'], isTrue);
      expect(data['score'], 3);
      expect(data['label'], 'Strong');
      expect(data['color'], isNotEmpty);
    });

    test('returns customised score and label', () {
      wallet.passwordScore = 0;
      wallet.passwordLabel = 'Very Weak';
      wallet.passwordColor = '#F44336';

      final data =
          wallet.passwordStrength('a')['data'] as Map<String, dynamic>;

      expect(data['score'], 0);
      expect(data['label'], 'Very Weak');
      expect(data['color'], '#F44336');
    });

    test('tracks password calls', () {
      wallet.passwordStrength('pass1');
      wallet.passwordStrength('pass2');

      expect(wallet.passwordCalls, ['pass1', 'pass2']);
    });

    test('forceError overrides password strength', () {
      wallet.forceError = 'unavailable';

      expect(wallet.passwordStrength('test')['ok'], isFalse);
    });
  });

  group('FakeWalletSetupBridge – forceError applies to all methods', () {
    test('every method returns ok:false', () {
      final wallet = FakeWalletSetupBridge()..forceError = 'global error';

      expect(wallet.validateMnemonic('m')['ok'], isFalse);
      expect(wallet.validateKeystore('k')['ok'], isFalse);
      expect(wallet.validatePrivateKey('p')['ok'], isFalse);
      expect(wallet.passwordStrength('s')['ok'], isFalse);
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // HeuristicFakeWalletSetupBridge
  // ════════════════════════════════════════════════════════════════════

  group('HeuristicFakeWalletSetupBridge – validateMnemonic', () {
    late HeuristicFakeWalletSetupBridge wallet;

    setUp(() => wallet = HeuristicFakeWalletSetupBridge());

    test('accepts 12-word mnemonic', () {
      final mnemonic = List.filled(12, 'word').join(' ');
      final data = wallet.validateMnemonic(mnemonic)['data'] as Map;

      expect(data['valid'], isTrue);
    });

    test('accepts 24-word mnemonic', () {
      final mnemonic = List.filled(24, 'word').join(' ');
      final data = wallet.validateMnemonic(mnemonic)['data'] as Map;

      expect(data['valid'], isTrue);
    });

    test('rejects 10-word mnemonic', () {
      final mnemonic = List.filled(10, 'word').join(' ');
      final data = wallet.validateMnemonic(mnemonic)['data'] as Map;

      expect(data['valid'], isFalse);
      expect(data['message'], isNotNull);
    });

    test('rejects empty string', () {
      final data = wallet.validateMnemonic('')['data'] as Map;

      expect(data['valid'], isFalse);
    });
  });

  group('HeuristicFakeWalletSetupBridge – validateKeystore', () {
    late HeuristicFakeWalletSetupBridge wallet;

    setUp(() => wallet = HeuristicFakeWalletSetupBridge());

    test('accepts JSON object string', () {
      final data = wallet.validateKeystore('{"version":3}')['data'] as Map;

      expect(data['valid'], isTrue);
    });

    test('rejects plain string', () {
      final data = wallet.validateKeystore('not-json')['data'] as Map;

      expect(data['valid'], isFalse);
    });

    test('rejects empty string', () {
      final data = wallet.validateKeystore('')['data'] as Map;

      expect(data['valid'], isFalse);
    });
  });

  group('HeuristicFakeWalletSetupBridge – validatePrivateKey', () {
    late HeuristicFakeWalletSetupBridge wallet;

    setUp(() => wallet = HeuristicFakeWalletSetupBridge());

    test('accepts valid 64-char hex (no prefix)', () {
      final key = 'a' * 64;
      final data = wallet.validatePrivateKey(key)['data'] as Map;

      expect(data['valid'], isTrue);
    });

    test('accepts valid hex with 0x prefix', () {
      final key = '0x${'b' * 64}';
      final data = wallet.validatePrivateKey(key)['data'] as Map;

      expect(data['valid'], isTrue);
    });

    test('rejects too-short hex', () {
      final data = wallet.validatePrivateKey('0xdeadbeef')['data'] as Map;

      expect(data['valid'], isFalse);
    });

    test('rejects non-hex characters', () {
      final data = wallet.validatePrivateKey('z' * 64)['data'] as Map;

      expect(data['valid'], isFalse);
    });
  });

  group('HeuristicFakeWalletSetupBridge – passwordStrength', () {
    late HeuristicFakeWalletSetupBridge wallet;

    setUp(() => wallet = HeuristicFakeWalletSetupBridge());

    test('score 0 for single character password', () {
      final data = wallet.passwordStrength('a')['data'] as Map;

      expect(data['score'], 0);
      expect(data['label'], 'Very Weak');
    });

    test('score 1 for 8+ char all-lowercase (length only)', () {
      final data = wallet.passwordStrength('abcdefgh')['data'] as Map;

      // length >= 8 → +1
      expect(data['score'], 1);
    });

    test('score 4 for complex password', () {
      final data = wallet.passwordStrength('Abcdef1!')['data'] as Map;

      expect(data['score'], 4);
      expect(data['label'], 'Very Strong');
    });

    test('score increases with complexity', () {
      final bare = (wallet.passwordStrength('abcdefgh')['data'] as Map)['score'] as int;
      final withUpper = (wallet.passwordStrength('Abcdefgh')['data'] as Map)['score'] as int;
      final withNum = (wallet.passwordStrength('Abcdefg1')['data'] as Map)['score'] as int;
      final withSpecial = (wallet.passwordStrength('Abcdefg1!')['data'] as Map)['score'] as int;

      expect(withUpper, greaterThan(bare));
      expect(withNum, greaterThan(withUpper));
      expect(withSpecial, greaterThan(withNum));
    });

    test('returns color as non-empty string for each score', () {
      for (final pw in ['a', 'abcdefgh', 'Abcdefgh', 'Abcdef1h', 'Abcdef1!']) {
        final data = wallet.passwordStrength(pw)['data'] as Map;
        expect((data['color'] as String).isNotEmpty, isTrue,
            reason: 'color should be non-empty for password "$pw"');
      }
    });
  });
}
