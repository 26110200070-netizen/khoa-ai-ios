# 🏜️ khoa.ai - iOS AI Chat Liquid Glass

<p align="center">
  <b>Trợ lý AI thông minh phong cách Liquid Glass kết hợp chủ đề Sa Mạc & Trí tuệ Nhân tạo</b><br>
  <i>Sáng lập và phát triển bởi <b>Khoa Dev</b></i>
</p>

---

## ✨ Điểm nổi bật

- 💎 **Giao diện Liquid Glass**: Tái hiện chuẩn hiệu ứng kính lỏng với ánh sáng phản xạ, chiều sâu mờ viền, viền kính bóng bẩy và micro-animation mượt mà.
- 🐳 **Logo Sa Mạc & AI**: Biểu tượng độc quyền kết hợp cồn cát hoàng hôn ấm áp và vây cá voi công nghệ phát sáng cyan.
- ⚡ **Chat DeepSeek Streaming thời gian thực**: Trực tiếp sử dụng tài khoản DeepSeek cá nhân mà không cần mua API key trả phí.
- 🛡️ **Hệ thống bảo vệ chống chặn & mute tài khoản**:
  - Đăng nhập trực tiếp bằng WebKit (`WKWebView`), giải quyết captcha AWS WAF tự nhiên như người dùng duyệt web.
  - Tự động duy trì phiên hội thoại tự nhiên lên tới 30 tin nhắn, tránh tình trạng spam tạo phiên mới dẫn đến mute tài khoản.
  - Bộ điều tốc gửi tin (Pacing Delay) ngăn chặn hành vi bot spam.
  - Bộ giải Proof-of-Work (PoW) `DeepSeekHashV1` chạy module WebAssembly nguyên bản nội bộ trong 150ms.
- 🧠 **DeepThink & Web Search**: Tùy chọn bật/tắt chế độ tư duy sâu và tìm kiếm internet trực tiếp ngay trên thanh nhập liệu.
- 📜 **Thiết kế tin nhắn mở (Unbounded AI Chat)**: Phản hồi của AI không bị đóng khung trong các hộp bo kín tù túng, giúp hiển thị văn bản và mã nguồn thoáng đãng, rộng rãi nhưng được căn chỉnh lề hoàn hảo không tràn viền màn hình.

---

## 🛠️ Cấu trúc dự án

```
khoa-ai-ios/
├── KhoaAI/
│   ├── App/
│   │   └── KhoaAIApp.swift                   # Entry point ứng dụng
│   ├── Core/
│   │   ├── DeepSeekAuthManager.swift         # Quản lý phiên, kiểm tra trạng thái mute
│   │   ├── DeepSeekPowSolver.swift           # Giải mã PoW WebAssembly offline
│   │   └── DeepSeekService.swift             # Kết nối SSE stream & tiêm persona khoa.ai
│   ├── UI/
│   │   ├── LiquidGlass/
│   │   │   └── LiquidGlassModifiers.swift    # Hệ thống giao diện kính lỏng Liquid Glass
│   │   ├── Components/
│   │   │   ├── KhoaAILogoView.swift          # Logo Sa mạc & AI
│   │   │   ├── ChatBubbleView.swift          # Hiển thị bong bóng người dùng & tin AI
│   │   │   └── DeepSeekLoginSheet.swift      # Sheet đăng nhập WebKit an toàn
│   │   └── Views/
│   │       ├── MainChatView.swift            # Màn hình chat chính (chuẩn ảnh mẫu)
│   │       └── SettingsSheetView.swift       # Quản lý tài khoản & lá chắn bảo vệ
│   └── Resources/
│       ├── Assets.xcassets/                  # AppIcon & Logo
│       └── sha3_wasm_bg.wasm                 # DeepSeek WebAssembly binary
├── KhoaAI.xcodeproj/                         # Xcode Project (iOS 17.0+)
└── .github/workflows/
    └── build-ipa.yml                         # Tự động đóng gói unsigned IPA cho ESign
```

---

## 📱 Cài đặt qua ESign

1. Vào mục **Releases** hoặc **Actions** của repository này để tải file `khoa_ai.ipa`.
2. Mở ứng dụng **ESign** trên thiết bị iPhone/iPad.
3. Import file `khoa_ai.ipa`.
4. Ký file bằng chứng chỉ của bạn và cài đặt lên máy.

---

*Bản quyền © 2026 Khoa Dev. Phát triển với đam mê.*
