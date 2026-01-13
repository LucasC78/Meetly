import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Meetly/config/theme.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String currentUserId;
  final String otherUserId;

  const ChatScreen({
    Key? key,
    required this.currentUserId,
    required this.otherUserId,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _controller = TextEditingController();

  DocumentReference<Map<String, dynamic>> _myBlockRef() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUserId)
        .collection('blocked')
        .doc(widget.otherUserId);
  }

  DocumentReference<Map<String, dynamic>> _otherBlockRef() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(widget.otherUserId)
        .collection('blocked')
        .doc(widget.currentUserId);
  }

  Future<bool> _isBlockedEitherWayOnce() async {
    final myBlockSnap = await _myBlockRef().get();
    if (myBlockSnap.exists) return true;

    final otherBlockSnap = await _otherBlockRef().get();
    if (otherBlockSnap.exists) return true;

    return false;
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // ✅ sécurité : on re-check le blocage au moment d’envoyer
    final blocked = await _isBlockedEitherWayOnce();
    if (blocked) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Impossible d'envoyer : utilisateur bloqué."),
        ),
      );
      return;
    }

    await _chatService.sendMessage(
      senderId: widget.currentUserId,
      receiverId: widget.otherUserId,
      message: text,
    );

    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _blockedBanner(
    ThemeData theme, {
    required bool youBlocked,
    required bool theyBlocked,
  }) {
    String text;
    if (youBlocked) {
      text = "Tu as bloqué cet utilisateur. Tu ne verras plus ses messages.";
    } else if (theyBlocked) {
      text =
          "Cet utilisateur t'a bloqué. Tu ne peux plus lui envoyer de message.";
    } else {
      text = "Conversation";
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: theme.brightness == Brightness.dark
            ? darkGlowShadow
            : lightSoftShadow,
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true, // ✅ FIX Android clavier/navbar
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          padding: const EdgeInsets.only(top: 10, bottom: 10),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: Icon(Icons.arrow_back,
                      color: theme.colorScheme.onBackground),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.otherUserId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();

                  final data =
                      (snapshot.data!.data() as Map<String, dynamic>?) ?? {};
                  final name = (data['pseudo'] ?? 'Utilisateur').toString();
                  final avatarUrl = data['profilepicture'];

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundImage: (avatarUrl != null &&
                                avatarUrl.toString().isNotEmpty)
                            ? NetworkImage(avatarUrl.toString())
                            : null,
                        backgroundColor: Colors.grey[800],
                        child:
                            (avatarUrl == null || avatarUrl.toString().isEmpty)
                                ? const Icon(Icons.person, color: Colors.white)
                                : null,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onBackground,
                          fontWeight: FontWeight.bold,
                          fontSize: 26,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        bottom: true, // ✅ FIX navbar Android
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _myBlockRef().snapshots(),
          builder: (context, myBlockSnap) {
            final youBlocked = myBlockSnap.data?.exists == true;

            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _otherBlockRef().snapshots(),
              builder: (context, otherBlockSnap) {
                final theyBlocked = otherBlockSnap.data?.exists == true;
                final blockedEitherWay = youBlocked || theyBlocked;

                return Column(
                  children: [
                    if (blockedEitherWay)
                      _blockedBanner(
                        theme,
                        youBlocked: youBlocked,
                        theyBlocked: theyBlocked,
                      ),

                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _chatService.getMessages(
                          widget.currentUserId,
                          widget.otherUserId,
                        ),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          // ✅ filtre messages si TU as bloqué l'autre
                          final rawMessages = snapshot.data!.docs;
                          final messages = youBlocked
                              ? rawMessages.where((m) {
                                  final data = m.data() as Map<String, dynamic>;
                                  return data['senderId'] ==
                                      widget.currentUserId;
                                }).toList()
                              : rawMessages;

                          final chatId = _chatService.getChatId(
                            widget.currentUserId,
                            widget.otherUserId,
                          );

                          // ✅ mark seen uniquement si pas bloqué
                          if (!blockedEitherWay) {
                            for (final msg in rawMessages) {
                              final data = msg.data() as Map<String, dynamic>;
                              if (data['receiverId'] == widget.currentUserId &&
                                  data['seen'] == false) {
                                _chatService.markMessageAsSeen(chatId, msg.id);
                              }
                            }
                          }

                          return ListView.builder(
                            reverse: true,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final msg = messages[messages.length - 1 - index];
                              final data = msg.data() as Map<String, dynamic>;
                              final isMe =
                                  data['senderId'] == widget.currentUserId;

                              return Align(
                                alignment: isMe
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 6, horizontal: 4),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 16),
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width *
                                            0.75,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isMe
                                          ? [
                                              theme.primaryColor,
                                              theme.colorScheme.secondary
                                            ]
                                          : [Colors.black26, Colors.black45],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(20),
                                      topRight: const Radius.circular(20),
                                      bottomLeft:
                                          Radius.circular(isMe ? 20 : 0),
                                      bottomRight:
                                          Radius.circular(isMe ? 0 : 20),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (data['text'] ?? '').toString(),
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 16),
                                      ),
                                      if (isMe)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4),
                                          child: Text(
                                            (data['seen'] == true)
                                                ? 'Vu'
                                                : 'Non vu',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 10,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),

                    // ✅ INPUT FIX : remonte au-dessus clavier + navbar Android
                    AnimatedPadding(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      padding: EdgeInsets.only(
                        left: 12,
                        right: 12,
                        top: 0,
                        bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: SafeArea(
                        top: false,
                        left: false,
                        right: false,
                        bottom: true,
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: theme.colorScheme.primary,
                                    width: 1.5,
                                  ),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: TextField(
                                  controller: _controller,
                                  enabled: !blockedEitherWay,
                                  style: TextStyle(
                                      color: theme.colorScheme.onBackground),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,
                                    hintText: blockedEitherWay
                                        ? "Messagerie désactivée (blocage)"
                                        : "Message...",
                                    hintStyle: TextStyle(
                                      color: theme.colorScheme.primary
                                          .withOpacity(0.9),
                                    ),
                                    icon: Icon(
                                      Icons.chat_bubble_outline,
                                      color: theme.colorScheme.primary,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    isCollapsed: true,
                                    filled: false,
                                    fillColor: Colors.transparent,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: blockedEitherWay ? null : _sendMessage,
                              child: Opacity(
                                opacity: blockedEitherWay ? 0.45 : 1,
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: pinkGradient,
                                  ),
                                  child: const Icon(Icons.send,
                                      color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
