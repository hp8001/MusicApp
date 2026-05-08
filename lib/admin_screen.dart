import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  final _audioController = TextEditingController();
  final _thumbnailController = TextEditingController();

  Future<void> _addSong() async {
    if (_titleController.text.isEmpty || _audioController.text.isEmpty) return;

    // Lệnh đẩy data lên Firestore tự động
    await FirebaseFirestore.instance.collection('songs').add({
      'title': _titleController.text.trim(),
      'artist': _artistController.text.trim(),
      'audioUrl': _audioController.text.trim(),
      'thumbnailUrl': _thumbnailController.text.trim(),
    });

    // Hiện thông báo và xóa trắng form để nhập bài tiếp theo
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thêm bài hát thành công!')));
    _titleController.clear();
    _artistController.clear();
    _audioController.clear();
    _thumbnailController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin - Thêm Nhạc')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Tên bài hát')),
            const SizedBox(height: 10),
            TextField(controller: _artistController, decoration: const InputDecoration(labelText: 'Ca sĩ')),
            const SizedBox(height: 10),
            TextField(controller: _audioController, decoration: const InputDecoration(labelText: 'Link nhạc (Audio URL)')),
            const SizedBox(height: 10),
            TextField(controller: _thumbnailController, decoration: const InputDecoration(labelText: 'Link ảnh (Thumbnail URL)')),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _addSong,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.green),
              child: const Text('ĐẨY LÊN FIRESTORE', style: TextStyle(color: Colors.white, fontSize: 18)),
            )
          ],
        ),
      ),
    );
  }
}