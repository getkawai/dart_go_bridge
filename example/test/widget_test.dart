import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_go_bridge_example/main.dart';
import 'fakes/fake_llm_bridge.dart';
import 'fakes/fake_store_bridge.dart';

void main() {
  setUp(() {
    // Override the factories with fakes so the widget test doesn't try to
    // load native libraries.
    llmBridgeFactory = () => FakeLlmBridge();
    storeBridgeFactory = () => FakeStoreBridge();
  });

  testWidgets('App initializes and shows contributors', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Because StoreBridge is fake, it returns an empty contributors list map
    // which stringifies to {ok: true, data: []}
    expect(find.text('Contributors: {ok: true, data: []}'), findsOneWidget);
  });

  testWidgets('Stream starts and displays LLM chunks', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Provide a fake delay-less stream
    final fakeLlm = FakeLlmBridge();
    fakeLlm.fakeStreamChunks = ['Hello', ' ', 'World!'];
    llmBridgeFactory = () => fakeLlm;

    // Find the "Start Stream" button
    final startButton = find.text('Start Stream');
    expect(startButton, findsOneWidget);

    // Tap it and start pumping the UI
    await tester.tap(startButton);
    await tester.pump(); // Register the tap

    // Wait for stream to finish processing
    await tester.pumpAndSettle();

    // Verify output 
    expect(find.text('Hello World!'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.textContaining('Chunks: 3'), findsOneWidget);
  });

  testWidgets('Error during initialization shows failure status', (WidgetTester tester) async {
    // Inject a factory that throws when initialized
    storeBridgeFactory = () {
      throw Exception('database is corrupt');
    };

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('Failed to load native library'), findsOneWidget);
  });
}
