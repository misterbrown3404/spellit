import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:spellit/features/auth/auth_service.dart';
import 'package:spellit/features/chat/chat_service.dart';
import 'package:spellit/features/lobby/room_service.dart';
import 'package:spellit/features/lobby/screens/waiting_room_screenn.dart';
import 'package:spellit/features/chat/screens/private_message_screen.dart';
import '../../../models/chat_model.dart';

class GlobalChatTab extends ConsumerStatefulWidget {
  final String? initialMessage;

  const GlobalChatTab({super.key, this.initialMessage});

  @override
  ConsumerState<GlobalChatTab> createState() => _GlobalChatTabState();
}

class _GlobalChatTabState extends ConsumerState<GlobalChatTab> {
  late final TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController(text: widget.initialMessage ?? '');
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text;
    if (text.trim().isEmpty) return;
    
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    
    _messageController.clear();
    
    try {
      await ref.read(chatServiceProvider).sendGlobalMessage(
        user.uid,
        user.displayName?.isEmpty ?? true ? 'Player' : user.displayName!,
        text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _joinRoom(String code) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final room = await ref.read(roomServiceProvider).joinRoom(
        roomCode: code,
        playerId: user.uid,
      );

      if (mounted) {
        Navigator.pop(context); // Dismiss loading
        if (room != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WaitingRoomScreen(roomId: room.roomId),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not join: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showUserOptions(String userId, String userName) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: Text(
                  userName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.chat),
                title: const Text('Send Private Message'),
                onTap: () {
                  Navigator.pop(context); // close bottom sheet
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PrivateMessageScreen(
                        otherUserId: userId,
                        otherUserName: userName,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatService = ref.watch(chatServiceProvider);
    final currentUser = ref.watch(authStateProvider).value;
    
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<ChatMessage>>(
            stream: chatService.getGlobalChatStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              final messages = snapshot.data ?? [];
              if (messages.isEmpty) {
                return Center(
                  child: Text(
                    'No messages yet. Be the first to say hi!',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                );
              }
              
              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isMe = msg.senderId == currentUser?.uid;
                  
                  return _buildMessageBubble(msg, isMe);
                },
              );
            },
          ),
        ),
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isMe) {
    final codeRegex = RegExp(r'[A-Z0-9]{6}', caseSensitive: false);
    final text = msg.text;
    final firstMatch = codeRegex.firstMatch(text);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
            bottomLeft: !isMe ? const Radius.circular(0) : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              GestureDetector(
                onTap: () => _showUserOptions(msg.senderId, msg.senderName),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    msg.senderName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            if (firstMatch != null)
              Wrap(
                children: [
                  Text(
                    text.substring(0, firstMatch.start),
                    style: TextStyle(
                      color: isMe ? Colors.white : null,
                      fontSize: 16,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _joinRoom(firstMatch.group(0)!.toUpperCase()),
                    child: Text(
                      firstMatch.group(0)!,
                      style: TextStyle(
                        color: isMe ? Colors.yellowAccent : Colors.blue,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (firstMatch.end < text.length)
                    Text(
                      text.substring(firstMatch.end),
                      style: TextStyle(
                        color: isMe ? Colors.white : null,
                        fontSize: 16,
                      ),
                    ),
                ],
              )
            else
              Text(
                text,
                style: TextStyle(
                  color: isMe ? Colors.white : null,
                  fontSize: 16,
                ),
              ),
          ]
        )
        )
        );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Share a room code or chat...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.withOpacity(0.1),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send),
              color: Theme.of(context).colorScheme.primary,
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
