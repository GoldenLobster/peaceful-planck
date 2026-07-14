import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class LogMessage {
  final DateTime timestamp;
  final String message;

  LogMessage(this.message) : timestamp = DateTime.now();

  @override
  String toString() {
    final timeStr = DateFormat('HH:mm:ss.SSS').format(timestamp);
    return '[$timeStr] $message';
  }
}

class AppLogger extends Notifier<List<LogMessage>> {
  static final AppLogger instance = AppLogger._internal();

  AppLogger._internal();

  @override
  List<LogMessage> build() {
    return [];
  }

  static void log(String message) {
    if (kDebugMode) {
      print('[AppLogger] $message');
    }
    // Access the notifier through a global provider instance is tricky without ref, 
    // but we can expose a stream or just keep a global list for simplicity if we want to avoid complex Riverpod setups for static access.
    // To make it simple, we'll keep a static list and broadcast.
    
    _globalLogs.add(LogMessage(message));
    if (_globalLogs.length > 500) {
      _globalLogs.removeAt(0); // Keep last 500 logs
    }
    _logStreamController.add(List.unmodifiable(_globalLogs));
  }

  static void clear() {
    _globalLogs.clear();
    _logStreamController.add([]);
  }

  static final List<LogMessage> _globalLogs = [];
  // ignore: close_sinks
  static final _logStreamController = StreamController<List<LogMessage>>.broadcast();
  static Stream<List<LogMessage>> get logStream => _logStreamController.stream;
  static List<LogMessage> get currentLogs => List.unmodifiable(_globalLogs);
}

