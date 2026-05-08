# Music App

Ứng dụng phát nhạc đơn giản viết bằng Flutter, sử dụng Firebase làm backend (Auth, Firestore, Storage).

**Nội dung README này bao gồm:** cài đặt, cấu hình Firebase, các màn hình chính, cách chạy và đóng góp.

**File chính:** [lib/main.dart](lib/main.dart#L1)

## Tính năng
- Đăng nhập / Đăng ký bằng Firebase Auth ([lib/auth_screen.dart](lib/auth_screen.dart#L1)).
- Danh sách bài hát lấy từ Firestore (collection `songs`).
- Phát nhạc với `just_audio`, playlist liên tục và điều khiển phát/tạm/danh sách ([lib/player_screen.dart](lib/player_screen.dart#L1)).
- Thả tim / danh sách yêu thích lưu trong document `users/{uid}.liked_songs` ([lib/liked_songs_screen.dart](lib/liked_songs_screen.dart#L1)).
- Giao diện thêm nhạc cho admin, đẩy metadata lên Firestore ([lib/admin_screen.dart](lib/admin_screen.dart#L1)).
- Cấu hình Firebase đã được sinh bằng FlutterFire CLI ([lib/firebase_options.dart](lib/firebase_options.dart#L1)).

## Yêu cầu trước khi chạy
- Flutter SDK (ứng dụng dùng Dart SDK >= 3.9.x). Cài đặt theo: https://flutter.dev
- Android SDK / Xcode (nếu build cho Android / iOS)
- Một project Firebase với `google-services.json` cho Android (đã có trong `android/app/`) và/hoặc `GoogleService-Info.plist` cho iOS nếu cần.

## Cấu hình Firebase
1. File cấu hình Android: [android/app/google-services.json](android/app/google-services.json)
2. File cấu hình iOS: thêm `GoogleService-Info.plist` vào Xcode nếu build iOS.
3. `lib/firebase_options.dart` đã chứa các `FirebaseOptions` cho các nền tảng — nếu bạn cấu hình Firebase khác, hãy chạy `flutterfire configure` hoặc cập nhật file này.

## Cài đặt phụ thuộc
Trong thư mục gốc dự án, chạy:

```bash
flutter pub get
```

Phụ thuộc chính có trong `pubspec.yaml`:
- firebase_core, firebase_auth, cloud_firestore, firebase_storage
- just_audio, just_audio_windows
- provider, audio_video_progress_bar

## Chạy ứng dụng
- Chạy debug trên thiết bị Android:

```bash
flutter run -d android
```

- Build APK release:

```bash
flutter build apk --release
```

- Chạy web (nếu muốn):

```bash
flutter run -d chrome
```

Lưu ý: iOS chỉ build được trên macOS với Xcode cài sẵn.

## Cấu trúc chính của mã nguồn
- `lib/main.dart`: Entry point, quản lý trạng thái đăng nhập và HomeScreen.
- `lib/auth_screen.dart`: Màn hình đăng nhập/đăng ký.
- `lib/player_screen.dart`: Màn hình trình phát, sử dụng `just_audio`.
- `lib/liked_songs_screen.dart`: Hiển thị và phát danh sách bài thích của user.
- `lib/admin_screen.dart`: Form để admin thêm bài vào Firestore.
- `lib/firebase_options.dart`: Cấu hình Firebase cho các nền tảng (được sinh tự động).

## Firestore - Mô hình dữ liệu (từ code)
- Collection `songs`: mỗi document là một bài hát, các trường chính: `title`, `artist`, `audioUrl`, `thumbnailUrl`.
- Collection `users`: mỗi document id là `uid` của user, có trường `liked_songs` (mảng chứa `songId`).

## Ghi chú về hoạt động
- Màn hình chính thực hiện tìm kiếm cục bộ trên dữ liệu lấy từ `songs`.
- Khi nhấn Play trên một danh sách (từ Home hoặc Liked), app tạo playlist hiện tại và chuyển sang `PlayerScreen` với `initialIndex`.
- Nút Thả tim thao tác bằng `FieldValue.arrayUnion` / `arrayRemove` để cập nhật `users/{uid}.liked_songs`.

## Kiểm tra & định dạng
- Phân tích mã: `flutter analyze`
- Chạy test: `flutter test` (nếu có test viết sẵn)
- Định dạng mã: `flutter format .`

## Đóng góp
- Fork repo, mở PR với mô tả rõ ràng.
- Trước khi gửi PR, chạy `flutter analyze` và đảm bảo không có lỗi.

