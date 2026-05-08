import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'player_screen.dart'; // Nối với màn hình phát nhạc hiện tại

class LikedSongsScreen extends StatefulWidget {
  const LikedSongsScreen({super.key});

  @override
  State<LikedSongsScreen> createState() => _LikedSongsScreenState();
}

class _LikedSongsScreenState extends State<LikedSongsScreen> {
  String searchQuery = '';
  final String? currentUserUid = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhạc yêu thích', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // --- THANH TÌM KIẾM (Chỉ tìm trong nhạc yêu thích) ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm bài hát yêu thích...',
                prefixIcon: const Icon(Icons.search, color: Colors.redAccent),
                filled: true,
                fillColor: Colors.grey[850],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          
          // --- DANH SÁCH BÀI HÁT YÊU THÍCH ---
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              // 1. Lắng nghe dữ liệu của User để lấy mảng liked_songs
              stream: FirebaseFirestore.instance.collection('users').doc(currentUserUid).snapshots(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<dynamic> likedIds = [];
                if (userSnapshot.hasData && userSnapshot.data!.exists) {
                  var userData = userSnapshot.data!.data() as Map<String, dynamic>;
                  likedIds = userData['liked_songs'] ?? [];
                }

                if (likedIds.isEmpty) {
                  return const Center(
                    child: Text('Bạn chưa thả tim bài hát nào.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  );
                }

                // 2. Nếu có ID thả tim, gọi vào kho nhạc để lấy thông tin chi tiết
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('songs').snapshots(),
                  builder: (context, songSnapshot) {
                    if (!songSnapshot.hasData) return const SizedBox();

                    final allSongs = songSnapshot.data!.docs;

                    // Lọc 1: Lấy các bài hát CÓ ID NẰM TRONG danh sách yêu thích
                    var favoriteSongs = allSongs.where((doc) => likedIds.contains(doc.id)).toList();

                    // Lọc 2: Lọc tiếp theo TỪ KHÓA TÌM KIẾM
                    favoriteSongs = favoriteSongs.where((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      String title = (data['title'] ?? '').toString().toLowerCase();
                      String artist = (data['artist'] ?? '').toString().toLowerCase();
                      return title.contains(searchQuery) || artist.contains(searchQuery);
                    }).toList();

                    if (favoriteSongs.isEmpty) {
                       return Center(child: Text('Không tìm thấy "$searchQuery"', style: const TextStyle(color: Colors.grey)));
                    }

                    return ListView.builder(
                      itemCount: favoriteSongs.length,
                      itemBuilder: (context, index) {
                        var songData = favoriteSongs[index].data() as Map<String, dynamic>;
                        String title = songData['title'] ?? 'Unknown Title';
                        String artist = songData['artist'] ?? 'Unknown Artist';
                        String thumbnailUrl = songData['thumbnailUrl'] ?? '';

                        return Card(
                          color: Colors.grey[900],
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: thumbnailUrl.isNotEmpty 
                                ? Image.network(thumbnailUrl, width: 60, height: 60, fit: BoxFit.cover)
                                : Container(width: 60, height: 60, color: Colors.grey),
                            ),
                            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(artist, style: const TextStyle(color: Colors.grey)),
                            trailing: IconButton(
                              icon: const Icon(Icons.play_circle_fill, color: Colors.redAccent, size: 36),
                              onPressed: () {
                                // 3. Khi bấm play, dồn ĐÚNG CÁC BÀI YÊU THÍCH vào một Playlist để phát nhạc
                                final currentPlaylist = favoriteSongs.map((doc) {
                                  var data = doc.data() as Map<String, dynamic>;
                                  data['id'] = doc.id; // Phải chèn ID vào để màn hình Player còn biết nút tim
                                  return data;
                                }).toList();

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PlayerScreen(
                                      playlist: currentPlaylist,
                                      initialIndex: index,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}