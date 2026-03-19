import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_llm_bridge.dart';

void main() {
  group('FakeLlmBridge – generateText', () {
    late FakeLlmBridge llm;

    setUp(() => llm = FakeLlmBridge());

    test('returns ok:true with default response text', () {
      final result = llm.generateText(prompt: 'Say hello');

      expect(result['ok'], isTrue);
      final data = result['data'] as Map<String, dynamic>;
      expect(data['text'], 'Hello from FakeLlmBridge!');
      expect(data['finish_reason'], 'stop');
      expect(data['model'], isNotNull);
      expect(data['provider'], isNotNull);
    });

    test('returns ok:false when fakeError is set', () {
      llm.fakeError = 'no model available';

      final result = llm.generateText(prompt: 'Say hello');

      expect(result['ok'], isFalse);
      expect(result['error'], 'no model available');
    });

    test('returns custom response text', () {
      llm.fakeResponseText = 'Custom response';

      final result = llm.generateText(prompt: 'Tell me something');

      expect((result['data'] as Map)['text'], 'Custom response');
    });

    test('tracks call count', () {
      llm.generateText(prompt: 'first');
      llm.generateText(prompt: 'second');

      expect(llm.generateTextCallCount, 2);
    });

    test('records last call args', () {
      llm.generateText(
        prompt: 'test prompt',
        system: 'sys',
        taskName: 'task',
        maxOutputTokens: 100,
        temperature: 0.7,
      );

      expect(llm.lastGenerateTextArgs!['prompt'], 'test prompt');
      expect(llm.lastGenerateTextArgs!['system'], 'sys');
      expect(llm.lastGenerateTextArgs!['taskName'], 'task');
      expect(llm.lastGenerateTextArgs!['maxOutputTokens'], 100);
      expect(llm.lastGenerateTextArgs!['temperature'], 0.7);
    });

    test('usage data is present in successful response', () {
      final result = llm.generateText(prompt: 'hello');
      final data = result['data'] as Map<String, dynamic>;
      expect(data['usage'], isNotNull);
    });
  });

  group('FakeLlmBridge – streamText', () {
    late FakeLlmBridge llm;

    setUp(() => llm = FakeLlmBridge());

    test('yields configured chunks in order', () async {
      llm.fakeStreamChunks = ['chunk1', 'chunk2', 'chunk3'];

      final chunks = await llm.streamText(prompt: 'hello').toList();

      expect(chunks, ['chunk1', 'chunk2', 'chunk3']);
    });

    test('yields empty list when no chunks configured', () async {
      llm.fakeStreamChunks = [];

      final chunks = await llm.streamText(prompt: 'hello').toList();

      expect(chunks, isEmpty);
    });

    test('throws StateError when fakeError is set', () async {
      llm.fakeError = 'stream failed';

      expect(
        () => llm.streamText(prompt: 'hello').toList(),
        throwsA(isA<StateError>().having((e) => e.message, 'message',
            contains('stream failed'))),
      );
    });

    test('throws mid-stream when fakeStreamError is set', () async {
      llm.fakeStreamChunks = ['a', 'b', 'c', 'd'];
      llm.fakeStreamError = 'mid-stream error';
      llm.streamErrorAfterChunks = 2;

      final collected = <String>[];
      await expectLater(
        llm.streamText(prompt: 'hello').forEach((c) => collected.add(c)),
        throwsA(isA<StateError>()),
      );
      // Should have yielded partial chunks before error
      expect(collected, ['a', 'b']);
    });

    test('tracks streamText call count', () async {
      await llm.streamText(prompt: 'a').toList();
      await llm.streamText(prompt: 'b').toList();

      expect(llm.streamTextCallCount, 2);
    });

    test('can concatenate stream into full text', () async {
      llm.fakeStreamChunks = ['Hello', ' ', 'world', '!'];

      final fullText =
          await llm.streamText(prompt: 'greet').fold('', (a, b) => a + b);

      expect(fullText, 'Hello world!');
    });
  });

  group('SlowFakeLlmBridge', () {
    test('yields same chunks as FakeLlmBridge but with delay', () async {
      final llm = SlowFakeLlmBridge(chunkDelayMs: 1);
      llm.fakeStreamChunks = ['slow', ' ', 'response'];

      final sw = Stopwatch()..start();
      final chunks = await llm.streamText(prompt: 'hi').toList();
      sw.stop();

      expect(chunks, ['slow', ' ', 'response']);
      // At least 3ms elapsed (3 chunks × 1ms each)
      expect(sw.elapsedMilliseconds, greaterThanOrEqualTo(3));
    });
  });

  group('RandomFakeLlmBridge', () {
    test('returns deterministic output for a given seed', () {
      final llm1 = RandomFakeLlmBridge(wordCount: 4, seed: 42);
      final llm2 = RandomFakeLlmBridge(wordCount: 4, seed: 42);

      final r1 = (llm1.generateText(prompt: 'x')['data']
          as Map<String, dynamic>)['text'];
      final r2 = (llm2.generateText(prompt: 'x')['data']
          as Map<String, dynamic>)['text'];

      expect(r1, equals(r2));
    });

    test('generates the expected number of words', () {
      final llm = RandomFakeLlmBridge(wordCount: 6, seed: 1);

      final text = (llm.generateText(prompt: 'x')['data']
          as Map<String, dynamic>)['text'] as String;

      expect(text.split(' ').length, 6);
    });
  });
}
