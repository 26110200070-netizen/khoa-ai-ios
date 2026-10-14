//
//  MainChatView.swift
//  KhoaAI
//
//  Created by Khoa Dev.
//  Main UI matching reference design with pure Liquid Glass styling, streaming chat, and Desert AI branding.
//

import SwiftUI

public struct MainChatView: View {
    @StateObject private var service = DeepSeekService.shared
    @StateObject private var authManager = DeepSeekAuthManager.shared

    @State private var inputText: String = ""
    @State private var isMutedAudio: Bool = false
    @State private var showLoginSheet: Bool = false
    @State private var showSettingsSheet: Bool = false
    @State private var showActionMenu: Bool = false
    @FocusState private var isInputFocused: Bool

    public init() {}

    public var body: some View {
        ZStack {
            // Subtle ambient background (clean minimalist canvas with subtle gradient)
            Color(.systemBackground)
                .ignoresSafeArea()

            // Subtle warm ambient light blur for desert vibe
            VStack {
                Circle()
                    .fill(Color(red: 0.98, green: 0.65, blue: 0.15).opacity(0.04))
                    .frame(width: 320, height: 320)
                    .blur(radius: 60)
                    .offset(y: -80)
                Spacer()
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Navigation Bar with Liquid Glass Buttons
                topBarView
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 6)

                // Account health warning if muted
                if authManager.isMuted {
                    mutedWarningBanner
                        .padding(.horizontal, 16)
                        .padding(.vertical, 4)
                }

                // Chat Scroll Area or Center Welcome View
                if service.messages.isEmpty {
                    Spacer()
                    centerWelcomeView
                    Spacer()
                } else {
                    chatScrollView
                }

                // Bottom Floating Liquid Glass Input Bar
                bottomInputContainer
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
            }
        }
        .sheet(isPresented: $showLoginSheet) {
            DeepSeekLoginSheet()
        }
        .sheet(isPresented: $showSettingsSheet) {
            SettingsSheetView()
        }
        .confirmationDialog("Tùy chọn", isPresented: $showActionMenu, titleVisibility: .visible) {
            Button("Đoạn hội thoại mới") {
                withAnimation { service.resetConversation() }
            }
            Button(authManager.isAuthenticated ? "Quản lý tài khoản DeepSeek" : "Đăng nhập DeepSeek") {
                showLoginSheet = true
            }
            Button("Thông tin về khoa.ai", role: .none) {
                showSettingsSheet = true
            }
            Button("Hủy", role: .cancel) {}
        }
        .onAppear {
            if !authManager.isAuthenticated {
                showLoginSheet = true
            }
        }
    }

    // MARK: - Top Navigation Bar
    private var topBarView: some View {
        HStack {
            // Left menu / drawer button (2 horizontal bars matching image)
            Button {
                let haptic = UIImpactFeedbackGenerator(style: .light)
                haptic.impactOccurred()
                showSettingsSheet = true
            } label: {
                VStack(spacing: 5) {
                    RoundedRectangle(cornerRadius: 1.5)
                        .frame(width: 18, height: 2.2)
                    RoundedRectangle(cornerRadius: 1.5)
                        .frame(width: 12, height: 2.2)
                }
                .foregroundStyle(Color.primary.opacity(0.85))
            }
            .glassCircleButton(diameter: 46)

            Spacer()

            // Right Action 1: Speaker / Mute Audio
            Button {
                let haptic = UIImpactFeedbackGenerator(style: .light)
                haptic.impactOccurred()
                withAnimation { isMutedAudio.toggle() }
            } label: {
                Image(systemName: isMutedAudio ? "speaker.slash" : "speaker.wave.2")
                    .font(.system(size: 18, weight: .semibold))
            }
            .glassCircleButton(diameter: 46)

            // Right Action 2: New Chat / Plus
            Button {
                let haptic = UIImpactFeedbackGenerator(style: .light)
                haptic.impactOccurred()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    service.resetConversation()
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
            }
            .glassCircleButton(diameter: 46)
        }
    }

    // MARK: - Center Welcome View (Matches Image 1)
    private var centerWelcomeView: some View {
        VStack(spacing: 24) {
            // Desert & AI Logo for khoa.ai
            KhoaAILogoView(size: 88, showGlow: true)
                .onTapGesture {
                    let haptic = UIImpactFeedbackGenerator(style: .medium)
                    haptic.impactOccurred()
                }

            // Headline Text matching screenshot
            Text("Xin chào, tôi có thể giúp gì cho bạn?")
                .font(.system(size: 21, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.primary)
                .padding(.horizontal, 28)

            // DeepSeek connection badge
            Button {
                showLoginSheet = true
            } label: {
                HStack(spacing: 6) {
                    Circle()
                        .fill(authManager.isAuthenticated ? (authManager.isMuted ? Color.orange : Color.green) : Color.red)
                        .frame(width: 7, height: 7)

                    Text(authManager.isAuthenticated ? (authManager.userEmail.isEmpty ? "Đã kết nối DeepSeek" : authManager.userEmail) : "Chưa đăng nhập DeepSeek • Nhấn để kết nối")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background {
                    Capsule()
                        .fill(Color(.systemGray6).opacity(0.8))
                        .background(.ultraThinMaterial)
                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.5), lineWidth: 0.8))
                }
            }
        }
        .padding(.bottom, 40)
    }

    // MARK: - Chat Scroll View
    private var chatScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(service.messages) { msg in
                        ChatBubbleView(message: msg)
                            .id(msg.id)
                    }

                    // Bottom spacer so messages don't hide behind the floating input container
                    Color.clear
                        .frame(height: 120)
                }
                .padding(.top, 12)
            }
            .onChange(of: service.messages.last?.text) {
                if let lastId = service.messages.last?.id {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }
            .onChange(of: service.messages.count) {
                if let lastId = service.messages.last?.id {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Bottom Floating Liquid Glass Input Bar (Matches Image 1)
    private var bottomInputContainer: some View {
        VStack(spacing: 12) {
            // Upper Input Row
            HStack(alignment: .center, spacing: 10) {
                TextField("Nhắn tin hoặc giữ để nói", text: $inputText, axis: .vertical)
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .lineLimit(1...5)
                    .focused($isInputFocused)
                    .padding(.horizontal, 6)
                    .padding(.top, 4)

                if !inputText.isEmpty {
                    Button {
                        inputText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.secondary.opacity(0.6))
                            .font(.system(size: 16))
                    }
                }
            }

            // Lower Controls Row (Matching screenshot pills + buttons)
            HStack(spacing: 8) {
                // Pill 1: Suy nghĩ (DeepThink)
                Button {
                    let haptic = UIImpactFeedbackGenerator(style: .light)
                    haptic.impactOccurred()
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                        service.isThinkingEnabled.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Suy nghĩ")
                    }
                }
                .glassPill(active: service.isThinkingEnabled, accentColor: Color.blue)

                // Pill 2: Tìm kiếm (Web Search)
                Button {
                    let haptic = UIImpactFeedbackGenerator(style: .light)
                    haptic.impactOccurred()
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                        service.isSearchEnabled.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "globe")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Tìm kiếm")
                    }
                }
                .glassPill(active: service.isSearchEnabled, accentColor: Color(red: 0.15, green: 0.65, blue: 0.95))

                Spacer()

                // Plus action button
                Button {
                    let haptic = UIImpactFeedbackGenerator(style: .light)
                    haptic.impactOccurred()
                    showActionMenu = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.primary.opacity(0.85))
                }
                .glassCircleButton(diameter: 40)

                // Voice Waveform button or Send Button
                if inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button {
                        let haptic = UIImpactFeedbackGenerator(style: .medium)
                        haptic.impactOccurred()
                    } label: {
                        Image(systemName: "waveform")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.primary.opacity(0.85))
                    }
                    .glassCircleButton(diameter: 40)
                } else {
                    Button {
                        let haptic = UIImpactFeedbackGenerator(style: .medium)
                        haptic.impactOccurred()
                        let msg = inputText
                        inputText = ""
                        Task {
                            await service.sendMessage(msg)
                        }
                    } label: {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(Color.white)
                    }
                    .glassCircleButton(diameter: 40, active: true)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .liquidGlass(cornerRadius: 28, tint: .white, opacity: 0.8)
    }

    // MARK: - Muted Warning Banner
    private var mutedWarningBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.orange)
                .font(.system(size: 16))

            Text("Tài khoản DeepSeek bị mute/hạn chế. Vui lòng bấm vào đây để đổi tài khoản khác.")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.primary)
                .lineLimit(2)

            Spacer()

            Button("Đổi") {
                showLoginSheet = true
            }
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(Color.blue)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.orange.opacity(0.12))
                .background(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.orange.opacity(0.3), lineWidth: 1))
        }
        .onTapGesture {
            showLoginSheet = true
        }
    }
}
