import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/chat_ws_provider.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _controller = TextEditingController();

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      ref.read(chatWsProvider.notifier).sendMessage(text);
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wsState = ref.watch(chatWsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('WS Chat Room'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Icon(
              wsState.isConnected ? Icons.check_circle : Icons.error,
              color: wsState.isConnected ? Colors.green : Colors.red,
            ),
          )
        ],
      ),
      body: Column(
        children: [
          if (wsState.error != null)
            Container(
              color: Colors.red.withValues(alpha:0.2),
              padding: const EdgeInsets.all(8),
              width: double.infinity,
              child: Text(
                'Error: ${wsState.error}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: wsState.messages.length,
              itemBuilder: (context, index) {
                final msg = wsState.messages[index];
                return ListTile(
                  title: Text(msg),
                  leading: const Icon(Icons.message),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
