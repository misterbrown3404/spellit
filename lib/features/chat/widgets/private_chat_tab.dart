// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:intl/intl.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:spellit/features/auth/auth_service.dart';
// import 'package:spellit/features/chat/chat_service.dart';
// import 'package:spellit/features/chat/screens/private_message_screen.dart';

// class PrivateChatTab extends ConsumerWidget {
//   const PrivateChatTab({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final chatService = ref.watch(chatServiceProvider);
//     final currentUser = ref.watch(authStateProvider).value;

//     if (currentUser == null) {
//       return const Center(child: Text('Not authenticated'));
//     }

//     return Scaffold(
//       appBar: AppBar(title: const Text('Messages')),
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: () => _openSearch(context),
//         icon: const Icon(Icons.edit),
//         label: const Text('New Chat'),
//       ),
//       body: StreamBuilder<List<Map<String, dynamic>>>(
//         stream: chatService.getRecentPrivateChats(currentUser.uid),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           final recentChats = snapshot.data ?? [];

//           if (recentChats.isEmpty) {
//             return Center(
//               child: Padding(
//                 padding: const EdgeInsets.all(32.0),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(
//                       Icons.chat_bubble_outline,
//                       size: 80,
//                       color: Theme.of(
//                         context,
//                       ).colorScheme.primary.withValues(alpha: 0.5),
//                     ),
//                     const SizedBox(height: 24),
//                     Text(
//                       'No private chats yet',
//                       style: Theme.of(context).textTheme.headlineSmall,
//                     ),
//                     const SizedBox(height: 16),
//                     Text(
//                       "Tap a player's name in the Global Chat or use New Chat to start a private conversation.",
//                       textAlign: TextAlign.center,
//                       style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                         color: Colors.grey,
//                         height: 1.5,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           }

//           return ListView.builder(
//             itemCount: recentChats.length,
//             itemBuilder: (context, index) {
//               final chatData = recentChats[index];
//               final participants = List<String>.from(
//                 chatData['participants'] ?? [],
//               );
//               final otherUserId = participants.firstWhere(
//                 (id) => id != currentUser.uid,
//                 orElse: () => 'Unknown',
//               );

//               final lastMessage = chatData['lastMessage'] ?? 'No messages';
//               final lastMessageTime = (chatData['lastMessageTime'] is DateTime)
//                   ? chatData['lastMessageTime'] as DateTime
//                   : DateTime.now();

//               final peerName =
//                   (chatData['name_$otherUserId'] as String?) ??
//                   chatData['otherUserName'] as String? ??
//                   'Player';

//               return ListTile(
//                 leading: const CircleAvatar(
//                   backgroundColor: Colors.blueAccent,
//                   child: Icon(Icons.person, color: Colors.white),
//                 ),
//                 title: Text(
//                   peerName,
//                   style: const TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 subtitle: Text(
//                   lastMessage,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 trailing: Text(
//                   DateFormat('MMM d, HH:mm').format(lastMessageTime),
//                   style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
//                 ),
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (_) => PrivateMessageScreen(
//                         otherUserId: otherUserId,
//                         otherUserName: peerName,
//                       ),
//                     ),
//                   );
//                 },
//               );
//             },
//           );
//         },
//       ),
//     );
//   }

//   void _openSearch(BuildContext outerContext) {
//     showDialog(
//       context: outerContext,
//       builder: (dialogContext) {
//         String query = '';
//         return AlertDialog(
//           title: const Text('Find Player'),
//           content: StatefulBuilder(
//             builder: (context, setState) {
//               return TextField(
//                 autofocus: true,
//                 decoration: const InputDecoration(
//                   hintText: 'Enter exact display name',
//                 ),
//                 onChanged: (value) => setState(() => query = value.trim()),
//               );
//             },
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(dialogContext),
//               child: const Text('Cancel'),
//             ),
//             FilledButton(
//               onPressed: () async {
//                 if (query.isEmpty) return;
//                 Navigator.pop(dialogContext);

//                 final trimmed = query.trim();
//                 if (trimmed.isEmpty) return;

//                 final snapshot = await FirebaseFirestore.instance
//                     .collection('users')
//                     .where('displayName', isEqualTo: trimmed)
//                     .limit(1)
//                     .get();

//                 if (snapshot.docs.isEmpty) {
//                   if (outerContext.mounted) {
//                     ScaffoldMessenger.of(outerContext).showSnackBar(
//                       const SnackBar(
//                         content: Text('No player found with that name'),
//                       ),
//                     );
//                   }
//                   return;
//                 }

//                 final doc = snapshot.docs.first;
//                 final uid = doc.id;
//                 final displayName = doc.get('displayName') ?? 'Player';

//                 if (outerContext.mounted) {
//                   Navigator.push(
//                     outerContext,
//                     MaterialPageRoute(
//                       builder: (_) => PrivateMessageScreen(
//                         otherUserId: uid,
//                         otherUserName: displayName,
//                       ),
//                     ),
//                   );
//                 }
//               },
//               child: const Text('Chat'),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }
