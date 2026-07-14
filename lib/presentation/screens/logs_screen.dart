import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/app_logger.dart';
import '../providers/player_provider.dart';

class LogsScreen extends ConsumerStatefulWidget {
  const LogsScreen({super.key});

  @override
  ConsumerState<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends ConsumerState<LogsScreen> {
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final useProxy = ref.watch(useProxyProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              final text = AppLogger.currentLogs.map((l) => l.toString()).join('\n');
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logs copied to clipboard')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              AppLogger.clear();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.black12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Use Local Audio Proxy',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Switch(
                  value: useProxy,
                  onChanged: (val) {
                    ref.read(useProxyProvider.notifier).setProxy(val);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<LogMessage>>(
              stream: AppLogger.logStream,
              initialData: AppLogger.currentLogs,
              builder: (context, snapshot) {
                final logs = snapshot.data ?? [];
                
                // Auto scroll to bottom on new logs
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                if (logs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No logs yet.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8.0),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        log.toString(),
                        style: const TextStyle(
                          fontFamily: 'Courier', // Monospace for logs
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
