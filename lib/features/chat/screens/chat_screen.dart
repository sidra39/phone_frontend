import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/services/auth_provider.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final int roomId;
  final String roomTitle;
  final String otherPartyName;

  const ChatScreen({
    super.key,
    required this.roomId,
    required this.roomTitle,
    required this.otherPartyName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessageModel> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  Timer? _pollingTimer;
  int _charCount = 0;

  @override
  void initState() {
    super.initState();
    _loadMessages(initial: true);
    _startPolling();
    _messageController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {
      _charCount = _messageController.text.length;
    });
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _loadMessages(initial: false);
    });
  }

  Future<void> _loadMessages({required bool initial}) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) return;

    try {
      final messages = await _chatService.getRoomMessages(token, widget.roomId);
      if (mounted) {
        final bool isNewMessage = messages.length > _messages.length;
        setState(() {
          _messages = messages;
          _isLoading = false;
        });

        if (isNewMessage || initial) {
          _scrollToBottom();
        }
      }
    } catch (e) {
      if (initial && mounted) {
        setState(() => _isLoading = false);
        final msg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load chat: $msg'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final String text = _messageController.text.trim();
    if (text.isEmpty) return;

    if (text.length > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message exceeds 500 character limit'), backgroundColor: Colors.red),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      final newMsg = await _chatService.sendMessage(token, widget.roomId, text);
      if (mounted) {
        setState(() {
          _messages.add(newMsg);
          _isSending = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        _messageController.text = text; // Restore text on failure
        final msg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $msg'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;

    final isAdmin = currentUser?.role.toLowerCase() == 'admin';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardColor,
        elevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.otherPartyName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              widget.roomTitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Message History List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'No messages in this chat session.',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _messages.length,
                        itemBuilder: (ctx, idx) {
                          final msg = _messages[idx];
                          final bool isSelf = msg.senderId == currentUser?.id;

                          return Align(
                            alignment: isSelf ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.75,
                              ),
                              decoration: BoxDecoration(
                                color: isSelf
                                    ? theme.primaryColor
                                    : theme.cardColor,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(isSelf ? 16 : 0),
                                  bottomRight: Radius.circular(isSelf ? 0 : 16),
                                ),
                                border: isSelf
                                    ? null
                                    : Border.all(color: const Color(0xffE2E8F0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isAdmin || !isSelf) ...[
                                    Text(
                                      msg.senderName,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isSelf ? Colors.white70 : theme.primaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                  Text(
                                    msg.message,
                                    style: TextStyle(
                                      color: isSelf ? Colors.white : theme.textTheme.bodyLarge?.color,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Message Input Field (Hidden for Admins - Read-Only Audit Mode)
          if (!isAdmin)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: theme.cardColor,
                border: const Border(
                  top: BorderSide(color: Color(0xffCCCCCC)),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            maxLength: 500,
                            maxLines: null,
                            buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                            decoration: InputDecoration(
                              hintText: 'Type your message...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              fillColor: theme.scaffoldBackgroundColor,
                              filled: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _isSending ? null : _sendMessage,
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: theme.primaryColor,
                            child: _isSending
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Custom counter display
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '$_charCount/500',
                        style: TextStyle(
                          fontSize: 10,
                          color: _charCount >= 500 ? Colors.red : Colors.grey,
                          fontWeight: _charCount >= 500 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
