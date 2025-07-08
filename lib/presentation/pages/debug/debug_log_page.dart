import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/logger.dart';

/// デバッグログ表示ページ
class DebugLogPage extends StatefulWidget {
  const DebugLogPage({super.key});

  @override
  State<DebugLogPage> createState() => _DebugLogPageState();
}

class _DebugLogPageState extends State<DebugLogPage> {
  LogLevel _selectedLevel = LogLevel.debug;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logs = AppLogger.instance.getLogsOfLevel(_selectedLevel);

    return Scaffold(
      appBar: AppBar(
        title: const Text('デバッグログ'),
        actions: [
          PopupMenuButton<LogLevel>(
            icon: const Icon(Icons.filter_list),
            onSelected: (level) {
              setState(() {
                _selectedLevel = level;
              });
            },
            itemBuilder: (context) => LogLevel.values.map((level) {
              return PopupMenuItem(
                value: level,
                child: Row(
                  children: [
                    Icon(level.icon, color: level.color),
                    const SizedBox(width: 8),
                    Text(level.name.toUpperCase()),
                  ],
                ),
              );
            }).toList(),
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              AppLogger.instance.clear();
              setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              final logText = logs.map((log) => log.toString()).join('\n');
              Clipboard.setData(ClipboardData(text: logText));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ログをクリップボードにコピーしました')),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: logs.isEmpty
            ? const Center(
                child: Text('ログがありません'),
              )
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8),
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    child: ListTile(
                      dense: true,
                      leading: Icon(
                        log.level.icon,
                        color: log.level.color,
                        size: 16,
                      ),
                      title: Text(
                        log.message,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: log.level.color,
                        ),
                      ),
                      subtitle: Text(
                        '${log.timestamp.hour.toString().padLeft(2, '0')}:'
                        '${log.timestamp.minute.toString().padLeft(2, '0')}:'
                        '${log.timestamp.second.toString().padLeft(2, '0')}.'
                        '${log.timestamp.millisecond.toString().padLeft(3, '0')}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                      onTap: () {
                        _showLogDetails(context, log);
                      },
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        },
        child: const Icon(Icons.arrow_downward),
      ),
    );
  }

  void _showLogDetails(BuildContext context, LogEntry log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(log.level.icon, color: log.level.color),
            const SizedBox(width: 8),
            Text(log.level.name.toUpperCase()),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'タイムスタンプ:',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              Text(log.timestamp.toString()),
              const SizedBox(height: 16),
              Text(
                'メッセージ:',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              Text(
                log.message,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: log.toString()));
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ログをコピーしました')),
              );
            },
            child: const Text('コピー'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}