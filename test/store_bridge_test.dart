import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_store_bridge.dart';

void main() {
  group('FakeStoreBridge – getUserBalance', () {
    late FakeStoreBridge store;

    setUp(() => store = FakeStoreBridge());

    test('returns 0 for an unknown address', () {
      final result = store.getUserBalance('unknown');

      expect(result['ok'], isTrue);
      expect(result['data'], '0');
    });

    test('returns seeded balance', () {
      store.setBalance('alice', 500);

      final result = store.getUserBalance('alice');

      expect(result['ok'], isTrue);
      expect(result['data'], '500');
    });

    test('returns error when forceError is set', () {
      store.forceError = 'store unavailable';

      final result = store.getUserBalance('alice');

      expect(result['ok'], isFalse);
      expect(result['error'], 'store unavailable');
    });
  });

  group('FakeStoreBridge – addBalance', () {
    late FakeStoreBridge store;

    setUp(() => store = FakeStoreBridge());

    test('increases balance for new address', () {
      store.addBalance('alice', '100');

      expect(store.rawBalance('alice'), 100);
    });

    test('accumulates multiple additions', () {
      store.addBalance('alice', '100');
      store.addBalance('alice', '50');

      expect(store.rawBalance('alice'), 150);
    });

    test('returns ok:true on success', () {
      final result = store.addBalance('alice', '100');

      expect(result['ok'], isTrue);
    });

    test('returns error for non-numeric amount', () {
      final result = store.addBalance('alice', 'not-a-number');

      expect(result['ok'], isFalse);
      expect(result['error'], 'invalid amount');
    });
  });

  group('FakeStoreBridge – deductBalance', () {
    late FakeStoreBridge store;

    setUp(() => store = FakeStoreBridge());

    test('decreases balance correctly', () {
      store.setBalance('alice', 200);

      store.deductBalance('alice', '80');

      expect(store.rawBalance('alice'), 120);
    });

    test('returns error when balance is insufficient', () {
      store.setBalance('alice', 50);

      final result = store.deductBalance('alice', '100');

      expect(result['ok'], isFalse);
      expect(result['error'], contains('insufficient'));
    });

    test('allows deducting exact balance (reaches 0)', () {
      store.setBalance('alice', 100);

      final result = store.deductBalance('alice', '100');

      expect(result['ok'], isTrue);
      expect(store.rawBalance('alice'), 0);
    });

    test('returns error for non-numeric amount', () {
      store.setBalance('alice', 100);

      final result = store.deductBalance('alice', 'abc');

      expect(result['ok'], isFalse);
    });
  });

  group('FakeStoreBridge – transferBalance', () {
    late FakeStoreBridge store;

    setUp(() => store = FakeStoreBridge());

    test('moves funds from sender to receiver', () {
      store.setBalance('alice', 500);

      store.transferBalance('alice', 'bob', '200');

      expect(store.rawBalance('alice'), 300);
      expect(store.rawBalance('bob'), 200);
    });

    test('returns error when sender has insufficient funds', () {
      store.setBalance('alice', 50);

      final result = store.transferBalance('alice', 'bob', '100');

      expect(result['ok'], isFalse);
      expect(result['error'], contains('insufficient'));
    });

    test('accumulates balance at receiver', () {
      store.setBalance('alice', 500);
      store.setBalance('bob', 100);

      store.transferBalance('alice', 'bob', '200');

      expect(store.rawBalance('alice'), 300);
      expect(store.rawBalance('bob'), 300);
    });

    test('does not modify balances on failure', () {
      store.setBalance('alice', 10);
      store.setBalance('bob', 50);

      store.transferBalance('alice', 'bob', '100');

      // Unchanged on failure
      expect(store.rawBalance('alice'), 10);
      expect(store.rawBalance('bob'), 50);
    });

    test('returns error for non-numeric amount', () {
      store.setBalance('alice', 100);

      final result = store.transferBalance('alice', 'bob', 'bad');

      expect(result['ok'], isFalse);
    });
  });

  group('FakeStoreBridge – createApiKey / validateApiKey', () {
    late FakeStoreBridge store;

    setUp(() => store = FakeStoreBridge());

    test('createApiKey returns ok with a key string', () {
      final result = store.createApiKey('alice');

      expect(result['ok'], isTrue);
      expect(result['data'], isA<String>());
      expect((result['data'] as String).isNotEmpty, isTrue);
    });

    test('same address always gets the same key', () {
      final r1 = store.createApiKey('alice');
      final r2 = store.createApiKey('alice');

      expect(r1['data'], equals(r2['data']));
    });

    test('different addresses get different keys', () {
      final k1 = store.createApiKey('alice')['data'];
      final k2 = store.createApiKey('bob')['data'];

      expect(k1, isNot(equals(k2)));
    });

    test('validateApiKey returns the associated address', () {
      final key = store.createApiKey('alice')['data'] as String;

      final result = store.validateApiKey(key);

      expect(result['ok'], isTrue);
      expect(result['data'], 'alice');
    });

    test('validateApiKey returns error for unknown key', () {
      final result = store.validateApiKey('nonexistent-key');

      expect(result['ok'], isFalse);
      expect(result['error'], contains('invalid api key'));
    });
  });

  group('FakeStoreBridge – getContributor / listContributors', () {
    late FakeStoreBridge store;

    setUp(() => store = FakeStoreBridge());

    test('getContributor returns error for unknown address', () {
      final result = store.getContributor('unknown');

      expect(result['ok'], isFalse);
      expect(result['error'], contains('not found'));
    });

    test('getContributor returns seeded data', () {
      store.seedContributor('alice', {'name': 'Alice', 'score': 42});

      final result = store.getContributor('alice');

      expect(result['ok'], isTrue);
      expect((result['data'] as Map)['name'], 'Alice');
      expect((result['data'] as Map)['score'], 42);
    });

    test('listContributors returns empty list initially', () {
      final result = store.listContributors();

      expect(result['ok'], isTrue);
      expect(result['data'], isEmpty);
    });

    test('listContributors returns all seeded contributors', () {
      store.seedContributor('alice', {'name': 'Alice'});
      store.seedContributor('bob', {'name': 'Bob'});

      final result = store.listContributors();
      final list = result['data'] as List;

      expect(list.length, 2);
    });
  });

  group('FakeStoreBridge – dispose', () {
    test('marks store as disposed', () {
      final store = FakeStoreBridge();

      store.dispose();

      expect(store.disposed, isTrue);
    });
  });

  group('FakeStoreBridge – forceError', () {
    test('all calls return error when forceError is set', () {
      final store = FakeStoreBridge()..forceError = 'db is down';

      expect(store.getUserBalance('alice')['ok'], isFalse);
      expect(store.addBalance('alice', '10')['ok'], isFalse);
      expect(store.deductBalance('alice', '10')['ok'], isFalse);
      expect(store.transferBalance('a', 'b', '10')['ok'], isFalse);
      expect(store.createApiKey('alice')['ok'], isFalse);
      expect(store.validateApiKey('key')['ok'], isFalse);
      expect(store.getContributor('alice')['ok'], isFalse);
      expect(store.listContributors()['ok'], isFalse);
    });
  });
}
