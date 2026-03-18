import 'package:flutter/material.dart';
import 'package:dart_go_bridge/dart_go_bridge.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _status = 'Loading...';

  @override
  void initState() {
    super.initState();
    _initBridge();
  }

  void _initBridge() {
    try {
      final bridge = StoreBridge.create();
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Dart-Go Bridge')),
        body: Center(child: Text(_status)),
      ),
    );
  }
}
