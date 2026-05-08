import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'player_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_screen.dart';
import 'liked_songs_screen.dart';
import 'admin_screen.dart';
void main() async {
  // Đặt lưới bắt lỗi ngay từ lúc khởi động
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const MusicApp()); // Nếu không lỗi thì chạy app bình thường
  } catch (e) {
    // NẾU CÓ LỖI: Cấm thoát app! Hiện màn hình thông báo lỗi lên!
    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              "LỖI KHỞI ĐỘNG:\n$e",
              style: const TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    ));
    print("===== LỖI KHỞI ĐỘNG FIREBASE: $e =====");
  }
}

class MusicApp extends StatelessWidget {
  const MusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Music App',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blueAccent,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      // --- PHẦN BẢO VỆ CỬA ---
      home: StreamBuilder<User?>(
        // Lắng nghe trạng thái của hệ thống Auth
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Nếu có dữ liệu trả về (tức là đã đăng nhập)
          if (snapshot.hasData) {
            return const HomeScreen(); // Cho vào màn hình chính
          }
          // Nếu không (chưa đăng nhập hoặc đã đăng xuất)
          return const AuthScreen(); // Đẩy ra màn hình Đăng nhập
        },
      ),
    );
  }
}

// Đã chuyển thành StatefulWidget để xử lý Tìm kiếm
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Biến lưu trữ từ khóa tìm kiếm
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
appBar: AppBar(
        title: const Text('Nhạc của tôi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // 1. KIỂM TRA QUYỀN ADMIN Ở ĐÂY
          if (FirebaseAuth.instance.currentUser?.email == 'admin@gmail.com')
            IconButton(
              icon: const Icon(Icons.upload_file, color: Colors.green),
              tooltip: 'Thêm nhạc (Chỉ Admin)',
              onPressed: () {
                // Bấm vào sẽ mở màn hình AdminScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminScreen()),
                );
              },
            ),
          // Nút đi tới Nhạc Yêu Thích (Thêm nút này)
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.redAccent),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LikedSongsScreen()),
              );
            },
          ),
          // Nút Đăng xuất
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // --- THANH TÌM KIẾM ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm bài hát hoặc ca sĩ...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[850],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                // Cập nhật lại giao diện mỗi khi gõ chữ
                setState(() {
                  searchQuery = value.toLowerCase(); // Chuyển thành chữ thường để dễ so sánh
                });
              },
            ),
          ),
          
          // --- DANH SÁCH BÀI HÁT ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('songs').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Đã xảy ra lỗi khi tải dữ liệu.'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Chưa có bài hát nào trong dữ liệu.'));
                }

                // 1. Lấy toàn bộ danh sách bài hát từ Firebase
                final allSongs = snapshot.data!.docs;

                // 2. Lọc danh sách dựa trên từ khóa tìm kiếm
                final filteredSongs = allSongs.where((doc) {
                  var songData = doc.data() as Map<String, dynamic>;
                  String title = (songData['title'] ?? '').toString().toLowerCase();
                  String artist = (songData['artist'] ?? '').toString().toLowerCase();
                  
                  // Nếu tên bài hát hoặc ca sĩ có chứa từ khóa thì giữ lại
                  return title.contains(searchQuery) || artist.contains(searchQuery);
                }).toList();

                // 3. Hiển thị thông báo nếu tìm không thấy
                if (filteredSongs.isEmpty) {
                  return Center(
                    child: Text('Không tìm thấy "$searchQuery"', 
                      style: const TextStyle(color: Colors.grey, fontSize: 16)
                    ),
                  );
                }

                // 4. Hiển thị danh sách đã lọc
                return ListView.builder(
                  itemCount: filteredSongs.length,
                  itemBuilder: (context, index) {
                    var songData = filteredSongs[index].data() as Map<String, dynamic>;
                    String title = songData['title'] ?? 'Unknown Title';
                    String artist = songData['artist'] ?? 'Unknown Artist';
                    String thumbnailUrl = songData['thumbnailUrl'] ?? '';
                    String audioUrl = songData['audioUrl'] ?? '';

                    return Card(
                      color: Colors.grey[900],
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(8),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: thumbnailUrl.isNotEmpty 
                            ? Image.network(thumbnailUrl, width: 60, height: 60, fit: BoxFit.cover)
                            : Container(width: 60, height: 60, color: Colors.grey),
                        ),
                        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(artist, style: const TextStyle(color: Colors.grey)),
                        trailing: IconButton(
                          icon: const Icon(Icons.play_circle_fill, color: Colors.blueAccent, size: 36),
                          onPressed: () {
                            // 1. Gom tất cả các bài hát đang hiển thị, LẤY THÊM DOCUMENT ID
                            final currentPlaylist = filteredSongs.map((doc) {
                              var data = doc.data() as Map<String, dynamic>;
                              data['id'] = doc.id; // Chèn thêm ID của Firebase vào dữ liệu
                              return data;
                            }).toList();

                            // 2. Gửi danh sách đó sang PlayerScreen, kèm theo thứ tự của bài đang bấm
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlayerScreen(
                                  playlist: currentPlaylist, // Truyền cả danh sách
                                  initialIndex: index,       // Vị trí bài đang bấm (0, 1, 2...)
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
            ),
          ),
        ],
      ),
    );
  }
}