import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../config/colors.dart';
import '../../models/user_model.dart';

class ChatScreen extends StatefulWidget {
  final UserModel friend;

  const ChatScreen({super.key, required this.friend});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController(); // Kontrol Scroll
  final SupabaseClient _supabase = Supabase.instance.client;
  late final String _myId;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _myId = _supabase.auth.currentUser!.id;
  }

  // Fungsi Scroll Otomatis ke Bawah
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      // Beri sedikit delay agar widget selesai dirender dulu
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true); // Ubah icon jadi loading
    _messageController.clear();

    try {
      await _supabase.from('messages').insert({
        'sender_id': _myId,
        'receiver_id': widget.friend.id,
        'content': text,
      });
      // Sukses kirim, scroll ke bawah
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal kirim pesan: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Stream<List<Map<String, dynamic>>> _getMessagesStream() {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .map((maps) {
          final filtered = maps.where((msg) {
            final sender = msg['sender_id'];
            final receiver = msg['receiver_id'];
            return (sender == _myId && receiver == widget.friend.id) ||
                   (sender == widget.friend.id && receiver == _myId);
          }).toList();
          
          // Trigger scroll setiap kali data baru masuk (realtime)
          if (filtered.isNotEmpty) _scrollToBottom();
          
          return filtered;
        });
  }

  // Helper untuk format tanggal header
  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final msgDate = DateTime(date.year, date.month, date.day);

    if (msgDate == today) return "Hari Ini";
    if (msgDate == yesterday) return "Kemarin";
    return DateFormat('d MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.darkPurple),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.lightPeach,
                  backgroundImage: widget.friend.avatarUrl.isNotEmpty 
                      ? NetworkImage(widget.friend.avatarUrl) 
                      : null,
                  child: widget.friend.avatarUrl.isEmpty 
                      ? Text(widget.friend.name[0].toUpperCase(), style: const TextStyle(color: AppColors.primaryPink, fontWeight: FontWeight.bold)) 
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.friend.name,
                  style: const TextStyle(color: AppColors.darkPurple, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Text(
                  "Online", // Nanti bisa dikembangkan jadi 'Typing...' atau 'Last seen'
                  style: TextStyle(color: Colors.green, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
            onPressed: () {}, // Menu opsi tambahan (Block, Clear Chat, dll)
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _getMessagesStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primaryPink));
                }

                final messages = snapshot.data!;
                
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: AppColors.primaryPink.withOpacity(0.1), blurRadius: 20)
                            ]
                          ),
                          child: const Icon(Icons.waving_hand_rounded, size: 50, color: Color(0xFFFFB74D)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Sapa ${widget.friend.name} sekarang! 👋",
                          style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['sender_id'] == _myId;
                    final date = DateTime.parse(msg['created_at']).toLocal();
                    
                    // Logic untuk Header Tanggal
                    bool showHeader = false;
                    if (index == 0) {
                      showHeader = true;
                    } else {
                      final prevDate = DateTime.parse(messages[index - 1]['created_at']).toLocal();
                      if (prevDate.day != date.day || prevDate.month != date.month || prevDate.year != date.year) {
                        showHeader = true;
                      }
                    }

                    return Column(
                      children: [
                        if (showHeader) 
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _formatDateHeader(date),
                                style: const TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        _buildMessageBubble(msg['content'], isMe, msg['created_at']),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // INPUT AREA MODERN
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), // Extra padding bottom for iOS safe area style
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, -4))
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end, // Agar icon tetap di bawah jika multiline
              children: [
                // Tombol Attachment (Hiasan)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10, right: 8),
                  child: Icon(Icons.add_circle_outline_rounded, color: Colors.grey[400], size: 28),
                ),
                
                // Text Field
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F7),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 5, // Bisa expand sampai 5 baris
                      style: const TextStyle(color: AppColors.darkPurple),
                      decoration: InputDecoration(
                        hintText: "Tulis pesan...",
                        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 15),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Tombol Kirim
                GestureDetector(
                  onTap: _isSending ? null : _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isSending ? Colors.grey : AppColors.primaryPink,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryPink.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: _isSending 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe, String timestamp) {
    final time = DateFormat('HH:mm').format(DateTime.parse(timestamp).toLocal());
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 4, 
          bottom: 4, 
          left: isMe ? 60 : 0, 
          right: isMe ? 0 : 60
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          // Gradient untuk pesan sendiri, Putih untuk pesan teman
          gradient: isMe 
              ? const LinearGradient(colors: [AppColors.primaryPink, Color(0xFFFF4081)]) 
              : null,
          color: isMe ? null : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 4), // Sudut lancip indikator pengirim
            bottomRight: Radius.circular(isMe ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04), 
              blurRadius: 4, 
              offset: const Offset(0, 2)
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min, // Agar bubble menyesuaikan panjang teks
          children: [
            Text(
              text,
              style: TextStyle(
                color: isMe ? Colors.white : AppColors.darkPurple,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: isMe ? Colors.white.withOpacity(0.8) : Colors.grey[400],
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.done_all_rounded, size: 14, color: Colors.white.withOpacity(0.8)),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }
}