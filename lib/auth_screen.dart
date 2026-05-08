import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true; // Biến xác định đang ở chế độ Đăng nhập hay Đăng ký
  bool _isLoading = false; // Biến xoay vòng chờ tải

  // Hàm xử lý Đăng nhập / Đăng ký
Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      print("===== 1. BẮT ĐẦU BẤM NÚT =====");
      
      if (_isLogin) {
        print("===== 2. GỌI LỆNH ĐĂNG NHẬP FIREBASE =====");
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        print("===== 3. ĐĂNG NHẬP THÀNH CÔNG =====");
      } else {
        print("===== 2. GỌI LỆNH ĐĂNG KÝ FIREBASE =====");
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        print("===== 3. ĐĂNG KÝ THÀNH CÔNG =====");
      }
    } catch (e) {
      print("===== LỖI RỒI: $e =====");
    } finally {
      setState(() => _isLoading = false);
      print("===== 4. KẾT THÚC HÀM =====");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo hoặc Icon trang trí
              const Icon(Icons.music_note, size: 100, color: Colors.blueAccent),
              const SizedBox(height: 20),
              Text(
                _isLogin ? 'Chào mừng trở lại!' : 'Tạo tài khoản mới',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),

              // Ô nhập Email
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Ô nhập Password
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                obscureText: true, // Che mật khẩu
              ),
              const SizedBox(height: 24),

              // Nút Submit
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_isLogin ? 'Đăng nhập' : 'Đăng ký', style: const TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),

              // Nút chuyển đổi giữa Đăng nhập / Đăng ký
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin; // Đảo ngược trạng thái
                  });
                },
                child: Text(
                  _isLogin ? 'Chưa có tài khoản? Đăng ký ngay' : 'Đã có tài khoản? Đăng nhập',
                  style: const TextStyle(color: Colors.blueAccent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}