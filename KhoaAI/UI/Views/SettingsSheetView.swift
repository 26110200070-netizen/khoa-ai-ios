//
//  SettingsSheetView.swift
//  KhoaAI
//
//  Created by Khoa Dev.
//  Account management, anti-ban safeguards dashboard, and app identity info.
//

import SwiftUI

public struct SettingsSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var authManager = DeepSeekAuthManager.shared
    @ObservedObject private var service = DeepSeekService.shared

    @State private var showLoginSheet: Bool = false

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                // Section 1: khoa.ai identity
                Section {
                    HStack(spacing: 16) {
                        KhoaAILogoView(size: 64, showGlow: false)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("khoa.ai")
                                .font(.system(size: 20, weight: .bold, design: .rounded))

                            Text("Tạo và phát triển bởi Khoa Dev")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color.secondary)

                            Text("Phong cách Liquid Glass • Mạng thần kinh AI")
                                .font(.system(size: 12))
                                .foregroundStyle(Color(red: 0.12, green: 0.45, blue: 0.95))
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Section 2: DeepSeek Account Status
                Section(header: Text("Tài khoản DeepSeek kết nối")) {
                    if authManager.isAuthenticated {
                        HStack {
                            Text("Email:")
                            Spacer()
                            Text(authManager.userEmail.isEmpty ? "Đã đăng nhập" : authManager.userEmail)
                                .foregroundStyle(Color.secondary)
                        }

                        HStack {
                            Text("Trạng thái:")
                            Spacer()
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(authManager.isMuted ? Color.orange : Color.green)
                                    .frame(width: 8, height: 8)
                                Text(authManager.isMuted ? "Bị hạn chế (Muted)" : "Hoạt động bình thường")
                                    .foregroundStyle(authManager.isMuted ? Color.orange : Color.green)
                                    .font(.system(size: 14, weight: .medium))
                            }
                        }

                        Button {
                            showLoginSheet = true
                        } label: {
                            Label("Đổi tài khoản / Đăng nhập lại", systemImage: "arrow.triangle.2.circlepath")
                                .foregroundStyle(Color.blue)
                        }

                        Button(role: .destructive) {
                            authManager.logout()
                            service.resetConversation()
                        } label: {
                            Label("Đăng xuất tài khoản", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Bạn chưa đăng nhập tài khoản DeepSeek.")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.secondary)

                            Button {
                                showLoginSheet = true
                            } label: {
                                Text("Đăng nhập DeepSeek ngay")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(Color.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color.blue)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Section 3: Anti-Ban Safeguards Status
                Section(header: Text("Lá chắn bảo vệ chống chặn & mute")) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Trình duyệt Safari WebKit nguyên bản")
                                .font(.system(size: 14, weight: .medium))
                            Text("Đăng nhập thực qua WKWebView, vượt AWS WAF tự nhiên.")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.secondary)
                        }
                    } icon: {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundStyle(Color.green)
                    }

                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Giải PoW WebAssembly trực tiếp")
                                .font(.system(size: 14, weight: .medium))
                            Text("Mã hóa DeepSeekHashV1 xử lý trong 150ms trên máy.")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.secondary)
                        }
                    } icon: {
                        Image(systemName: "cpu")
                            .foregroundStyle(Color.blue)
                    }

                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Tái sử dụng phiên hội thoại tự nhiên")
                                .font(.system(size: 14, weight: .medium))
                            Text("Giữ session lên tới 30 tin nhắn, tránh spam tạo mới.")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.secondary)
                        }
                    } icon: {
                        Image(systemName: "arrow.triangle.capsulepath")
                            .foregroundStyle(Color.purple)
                    }

                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Khoảng cách gửi người dùng (Pacing)")
                                .font(.system(size: 14, weight: .medium))
                            Text("Tự động giãn cách tối thiểu 1.5s mô phỏng thao tác người thật.")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.secondary)
                        }
                    } icon: {
                        Image(systemName: "timer")
                            .foregroundStyle(Color.orange)
                    }
                }

                // Section 4: Data & Actions
                Section {
                    Button(role: .destructive) {
                        service.resetConversation()
                        dismiss()
                    } label: {
                        Label("Xóa lịch sử tin nhắn hiện tại", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Cài đặt khoa.ai")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Xong") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showLoginSheet) {
                DeepSeekLoginSheet()
            }
        }
    }
}
