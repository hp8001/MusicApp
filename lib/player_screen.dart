import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PlayerScreen extends StatefulWidget {
  final List<Map<String, dynamic>> playlist;
  final int initialIndex;

  const PlayerScreen({
    super.key,
    required this.playlist,
    required this.initialIndex,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late AudioPlayer _audioPlayer;
  // Lấy UID của user đang đăng nhập hiện tại
  final String? currentUserUid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      final audioSources = widget.playlist.map((song) {
        return AudioSource.uri(
          Uri.parse(song['audioUrl'] ?? ''),
          tag: song, // Lưu toàn bộ thông tin (bao gồm cả 'id' vừa thêm)
        );
      }).toList();

      final playlist = ConcatenatingAudioSource(children: audioSources);
      await _audioPlayer.setAudioSource(playlist, initialIndex: widget.initialIndex);
      _audioPlayer.play();
    } catch (e) {
      debugPrint("Lỗi tải nhạc: $e");
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  // --- HÀM XỬ LÝ THẢ TIM ---
  Future<void> _toggleFavorite(String songId, bool isAlreadyLiked) async {
    if (currentUserUid == null) return; // Chưa đăng nhập thì không làm gì cả
    
    // Trỏ vào thư mục của User này trong Firestore
    final userDocRef = FirebaseFirestore.instance.collection('users').doc(currentUserUid);

    if (isAlreadyLiked) {
      // Nếu đã thích -> Xóa bài hát khỏi mảng
      await userDocRef.set({
        'liked_songs': FieldValue.arrayRemove([songId])
      }, SetOptions(merge: true)); // merge: true giúp tạo document mới nếu user chưa từng có data
    } else {
      // Nếu chưa thích -> Thêm bài hát vào mảng
      await userDocRef.set({
        'liked_songs': FieldValue.arrayUnion([songId])
      }, SetOptions(merge: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đang phát'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: StreamBuilder<SequenceState?>(
          stream: _audioPlayer.sequenceStateStream,
          builder: (context, snapshot) {
            final state = snapshot.data;
            if (state?.sequence.isEmpty ?? true) {
              return const Center(child: CircularProgressIndicator());
            }

            // Lấy thông tin bài hát ĐANG PHÁT
            final metadata = state!.currentSource!.tag as Map<String, dynamic>;
            final songId = metadata['id'] ?? '';
            final title = metadata['title'] ?? 'Unknown Title';
            final artist = metadata['artist'] ?? 'Unknown Artist';
            final thumbnailUrl = metadata['thumbnailUrl'] ?? '';

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: thumbnailUrl.isNotEmpty
                      ? Image.network(thumbnailUrl, height: 300, width: 300, fit: BoxFit.cover)
                      : Container(height: 300, width: 300, color: Colors.grey[800]),
                ),
                const SizedBox(height: 20),
                
                // Tên bài, Ca sĩ & Nút Thả tim
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(artist, style: const TextStyle(fontSize: 18, color: Colors.grey)),
                        ],
                      ),
                    ),
                    
                    // --- NÚT TRÁI TIM REAL-TIME ---
                    StreamBuilder<DocumentSnapshot>(
                      // Lắng nghe dữ liệu của đúng User đang đăng nhập
                      stream: FirebaseFirestore.instance.collection('users').doc(currentUserUid).snapshots(),
                      builder: (context, userSnapshot) {
                        bool isLiked = false;
                        
                        if (userSnapshot.hasData && userSnapshot.data!.exists) {
                          var userData = userSnapshot.data!.data() as Map<String, dynamic>;
                          var likedSongs = userData['liked_songs'] as List<dynamic>? ?? [];
                          // Kiểm tra xem ID bài hát hiện tại có nằm trong danh sách không
                          isLiked = likedSongs.contains(songId);
                        }

                        return IconButton(
                          icon: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.redAccent : Colors.white,
                            size: 32,
                          ),
                          onPressed: () => _toggleFavorite(songId, isLiked),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Thanh Tua Nhạc
                StreamBuilder<Duration>(
                  stream: _audioPlayer.positionStream,
                  builder: (context, posSnap) {
                    final position = posSnap.data ?? Duration.zero;
                    final duration = _audioPlayer.duration ?? Duration.zero;
                    final buffered = _audioPlayer.bufferedPosition;

                    return ProgressBar(
                      progress: position,
                      buffered: buffered,
                      total: duration,
                      progressBarColor: Colors.blueAccent,
                      baseBarColor: Colors.grey[800],
                      bufferedBarColor: Colors.grey[600],
                      thumbColor: Colors.blueAccent,
                      onSeek: (duration) => _audioPlayer.seek(duration),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Cụm nút Play/Pause/Next/Prev
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous),
                      iconSize: 50.0,
                      color: _audioPlayer.hasPrevious ? Colors.white : Colors.grey,
                      onPressed: _audioPlayer.hasPrevious ? _audioPlayer.seekToPrevious : null,
                    ),
                    StreamBuilder<PlayerState>(
                      stream: _audioPlayer.playerStateStream,
                      builder: (context, playerSnap) {
                        final playerState = playerSnap.data;
                        final processingState = playerState?.processingState;
                        final playing = playerState?.playing;

                        if (processingState == ProcessingState.loading || processingState == ProcessingState.buffering) {
                          return Container(margin: EdgeInsets.all(8.0), width: 64.0, height: 64.0, child: CircularProgressIndicator());
                        } else if (playing == true) {
                          return IconButton(icon: const Icon(Icons.pause_circle_filled), iconSize: 80.0, color: Colors.blueAccent, onPressed: _audioPlayer.pause);
                        } else {
                          return IconButton(icon: const Icon(Icons.play_circle_fill), iconSize: 80.0, color: Colors.blueAccent, onPressed: _audioPlayer.play);
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next),
                      iconSize: 50.0,
                      color: _audioPlayer.hasNext ? Colors.white : Colors.grey,
                      onPressed: _audioPlayer.hasNext ? _audioPlayer.seekToNext : null,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}