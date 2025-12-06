import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/colors.dart';
import '../../models/friend_model.dart';
import '../../models/user_model.dart';
import '../../services/friend_service.dart';
import 'chat_screen.dart'; // Nanti kita buat file ini

class FriendScreen extends StatefulWidget {
  const FriendScreen({super.key});

  @override
  State<FriendScreen> createState() => _FriendScreenState();
}

class _FriendScreenState extends State<FriendScreen> {
  final FriendService _friendService = FriendService();
  final String _myId = Supabase.instance.client.auth.currentUser!.id;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white, // Background putih bersih
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.darkPurple),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
          title: const Text(
            "Pinky Circle",
            style: TextStyle(
              color: AppColors.darkPurple,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          actions: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryPink.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.search_rounded, color: AppColors.primaryPink, size: 20),
              ),
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: FriendSearchDelegate(friendService: _friendService),
                );
              },
            ),
            const SizedBox(width: 16),
          ],
          // ✨ BAGIAN TAB BAR YANG DIPERCANTIK ✨
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.greyLight,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  color: AppColors.primaryPink, // Warna PinkyPay!
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryPink.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent, // Hilangkan garis pemisah default
                tabs: const [
                  Tab(text: "My Friends"),
                  Tab(text: "Requests"),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildMyFriendsTab(),
            _buildRequestsTab(),
          ],
        ),
      ),
    );
  }

  // ... (Kode _buildMyFriendsTab, _buildRequestsTab, dll tetap sama,
  // TAPI di bagian _buildModernFriendItem kita ubah tombol actionnya ke Chat)

  Widget _buildModernFriendItem(UserModel profile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.greyLight), // Border tipis rapi
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: AppColors.lightPeach,
              child: Text(
                profile.name[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryPink,
                ),
              ),
            ),
            // Indikator Online (Hiasan visual)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.greenAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            )
          ],
        ),
        title: Text(
          profile.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 16,
            color: AppColors.darkPurple,
          ),
        ),
        subtitle: Text(
          profile.email,
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
        // TOMBOL CHAT BARU
        trailing: IconButton(
          style: IconButton.styleFrom(
            backgroundColor: AppColors.primaryPink.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primaryPink, size: 20),
          onPressed: () {
            // NAVIGASI KE CHAT SCREEN
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(friend: profile),
              ),
            );
          },
        ),
      ),
    );
  }
  
  // ... (Sisa kode seperti _buildRequestsTab, SearchDelegate, dll copy dari sebelumnya)
  
  // --- TAB 1: DAFTAR TEMAN (Copy paste code sebelumnya disini) ---
  Widget _buildMyFriendsTab() {
    return FutureBuilder<List<FriendModel>>(
      future: _friendService.getMyFriends(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryPink));
        }

        final friends = snapshot.data ?? [];

        if (friends.isEmpty) {
          return _buildEmptyState(
            "Circle kamu masih sepi 😔",
            "Coba cari teman baru dengan menekan tombol Search di atas!",
            Icons.diversity_1_rounded,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          itemCount: friends.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final friendship = friends[index];
            final isMeSender = friendship.sender?.id == _myId;
            final friendProfile = isMeSender ? friendship.receiver : friendship.sender;

            return _buildModernFriendItem(friendProfile!);
          },
        );
      },
    );
  }

  // --- TAB 2: REQUEST MASUK (Copy paste code sebelumnya disini) ---
  Widget _buildRequestsTab() {
    return FutureBuilder<List<FriendModel>>(
      future: _friendService.getIncomingRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryPink));
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return _buildEmptyState(
            "Tidak ada permintaan",
            "Tenang, tidak ada yang mengganggumu hari ini.",
            Icons.mark_email_read_rounded,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          itemCount: requests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            return _buildModernRequestItem(requests[index]);
          },
        );
      },
    );
  }
  
  Widget _buildModernRequestItem(FriendModel request) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primaryPink.withValues(alpha: 0.1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPink.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.lightBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_add_rounded, color: AppColors.lightBlue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.sender?.name ?? "Unknown",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 16,
                        color: AppColors.darkPurple,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Minta berteman 👋",
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () async {
                    await _friendService.deleteFriendship(request.id);
                    setState(() {});
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    backgroundColor: Colors.grey[100],
                  ),
                  child: Text("Tolak", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await _friendService.acceptRequest(request.id);
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    backgroundColor: AppColors.primaryPink,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text("Terima", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryPink.withValues(alpha: 0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  )
                ]
              ),
              child: Icon(icon, size: 64, color: AppColors.primaryPink.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkPurple),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class FriendSearchDelegate extends SearchDelegate {
  final FriendService friendService;

  FriendSearchDelegate({required this.friendService});

  @override
  String get searchFieldLabel => 'Cari email teman...';

  @override
  TextStyle? get searchFieldStyle => const TextStyle(color: AppColors.darkPurple, fontSize: 16);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear_rounded, color: Colors.grey),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.darkPurple, size: 20),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) return Container();

    return FutureBuilder<List<UserModel>>(
      future: friendService.searchUsers(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryPink));
        }

        final users = snapshot.data ?? [];

        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off_rounded, size: 60, color: Colors.grey),
                const SizedBox(height: 16),
                Text("Tidak ditemukan user dengan email '$query'", style: const TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final user = users[index];
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryPink,
                  child: Text(user.name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkPurple)),
                subtitle: Text(user.email),
                trailing: IconButton(
                  icon: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.lightBlue),
                  onPressed: () async {
                    try {
                      await friendService.sendFriendRequest(user.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Request dikirim ke ${user.name} ✅"), backgroundColor: Colors.green),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red),
                      );
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9FD),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search_rounded, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text("Ketik email untuk mencari teman", style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}