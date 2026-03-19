import 'package:flutter/material.dart';
import 'package:dart_go_bridge/dart_go_bridge.dart';
import 'package:dart_go_bridge/llm_bridge_interface.dart';
import 'package:dart_go_bridge/store_bridge_interface.dart';
import 'package:flutter/services.dart';

@visibleForTesting
LlmBridgeInterface Function() llmBridgeFactory = () => LlmBridge.create();

@visibleForTesting
StoreBridgeInterface Function() storeBridgeFactory = () => StoreBridge.create();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final TextEditingController _promptController = TextEditingController(
    text: 'Jelaskan singkat apa itu LLM.',
  );
  String _status = 'Ready';
  String _output = '';
  bool _isStreaming = false;
  bool _cancelStream = false;
  final ScrollController _scrollController = ScrollController();
  int _chunkCount = 0;
  DateTime? _streamStart;
  Duration? _streamDuration;

  @override
  void initState() {
    super.initState();
    _initBridge();
  }

  void _initBridge() {
    try {
      final bridge = storeBridgeFactory();
      final contributors = bridge.listContributors();
      bridge.dispose();
      setState(() {
        _status = 'Contributors: $contributors';
      });
    } catch (e) {
      setState(() {
        _status = 'Failed to load native library: $e';
      });
    }
  }

  Future<void> _startStream() async {
    if (_isStreaming) {
      return;
    }
    setState(() {
      _isStreaming = true;
      _cancelStream = false;
      _output = '';
      _chunkCount = 0;
      _streamStart = DateTime.now();
      _streamDuration = null;
      _status = 'Streaming...';
    });

    try {
      final llm = llmBridgeFactory();
      await for (final chunk in llm.streamText(
        prompt: _promptController.text,
        system: 'Jawab ringkas dalam bahasa Indonesia.',
        maxOutputTokens: 200,
      )) {
        if (!mounted) {
          return;
        }
        if (_cancelStream) {
          break;
        }
        setState(() {
          _output += chunk;
          _chunkCount += 1;
        });
        _scrollToBottom();
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _status = _cancelStream ? 'Cancelled' : 'Done';
        _streamDuration = DateTime.now().difference(_streamStart!);
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _status = 'Stream error: $e';
      });
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isStreaming = false;
      });
    }
  }

  void _stopStream() {
    if (!_isStreaming) {
      return;
    }
    setState(() {
      _cancelStream = true;
    });
  }

  void _clearOutput() {
    if (_isStreaming) {
      return;
    }
    setState(() {
      _output = '';
      _chunkCount = 0;
      _streamDuration = null;
      _status = 'Ready';
    });
  }

  Future<void> _copyOutput() async {
    if (_output.isEmpty) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: _output));
    if (!mounted) {
      return;
    }
    setState(() {
      _status = 'Copied';
    });
  }

  String _metricsText() {
    final durationMs = _streamDuration?.inMilliseconds;
    final durationText =
        durationMs == null ? '-' : '${durationMs}ms';
    return 'Chunks: $_chunkCount | Duration: $durationText';
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      return;
    }
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Dart-Go Bridge')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_status),
              const SizedBox(height: 4),
              Text(
                _metricsText(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _promptController,
                decoration: const InputDecoration(
                  labelText: 'Prompt',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isStreaming ? null : _startStream,
                child: Text(_isStreaming ? 'Streaming...' : 'Start Stream'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _isStreaming ? _stopStream : null,
                child: const Text('Stop'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _isStreaming ? null : _clearOutput,
                child: const Text('Clear'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _output.isEmpty ? null : _copyOutput,
                child: const Text('Copy'),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Text(_output),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
