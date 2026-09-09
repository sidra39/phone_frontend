import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/services/auth_provider.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class ChatRoomsScreen extends StatefulWidget {
  const ChatRoomsScreen({super.key});

  @override
  State<ChatRoomsScreen> createState() => _ChatRoomsScreenState();
}

class _ChatRoomsScreenState extends State<ChatRoomsScreen> {
  final ChatService _chatService = ChatService();
  List<ChatRoomModel> _rooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final rooms = await _chatService.getMyRooms(token);
      if (mounted) {
        setState(() {
          _rooms = rooms;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final msg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load chats: $msg'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;

    // Helper to check if current user is admin
    final isAdmin = currentUser?.role.toLowerCase() == 'admin';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: isAdmin
          ? null // AdminDashboardScreen already provides the AppBar
          : AppBar(
              backgroundColor: theme.cardColor,
              elevation: 1,
              title: const Text('Conversations', style: TextStyle(fontWeight: FontWeight.bold)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _loadRooms,
                ),
              ],
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rooms.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.forum_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No active conversations',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isAdmin
                            ? 'No chats have been initiated in the system yet.'
                            : 'Initiate a chat session from a parts listing screen.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadRooms,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _rooms.length,
                    itemBuilder: (ctx, idx) {
                      final room = _rooms[idx];
                      String displayName = room.otherName ?? 'Unknown';
                      String subtitle = '${room.brandName ?? ""} • ${room.modelName}';

                      if (isAdmin) {
                        displayName = '${room.customerName ?? "Customer"} ⇆ ${room.vendorShopName ?? "Vendor"}';
                        subtitle = 'Part ID: ${room.partId} | ${room.brandName ?? ""} ${room.modelName}';
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xffE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                            child: Icon(
                              isAdmin ? Icons.supervisor_account_rounded : Icons.person_rounded,
                              color: theme.primaryColor,
                            ),
                          ),
                          title: Text(
                            displayName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            key: ValueKey('sub_${room.id}'),
                            child: Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  roomId: room.id,
                                  roomTitle: room.modelName,
                                  otherPartyName: isAdmin
                                      ? 'System Audit Log'
                                      : (room.otherName ?? 'Direct Messages'),
                                ),
                              ),
                            ).then((_) => _loadRooms());
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
