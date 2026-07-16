// import 'package:flutter/material.dart';
// import 'package:spellit/features/chat/widgets/global_chat_tab.dart';
// import 'package:spellit/features/chat/widgets/private_chat_tab.dart';

// class ChatScreen extends StatefulWidget {
//   final String? initialMessage;
//   final int initialTab;

//   const ChatScreen({super.key, this.initialMessage, this.initialTab = 0});

//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//     if (widget.initialTab != 0) {
//       _tabController.index = widget.initialTab;
//     }
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Chat & Connect'),
//         bottom: TabBar(
//           controller: _tabController,
//           tabs: const [
//             Tab(text: 'Global Chat'),
//             Tab(text: 'Private Chat'),
//           ],
//         ),
//       ),
//       body: TabBarView(
//         controller: _tabController,
//         children: [
//           GlobalChatTab(initialMessage: widget.initialMessage),
//           const PrivateChatTab(),
//         ],
//       ),
//     );
//   }
// }
