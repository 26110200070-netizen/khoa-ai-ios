//
//  MainChatView.swift
//  KhoaAI
//
//  Created by Khoa Dev.
//  Pure Light UI Liquid Glass Chat Interface with instant keyboard dismissal on tap.
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
            // Pure Crisp White Light Background
            Color.white
                .ignoresSafeArea()

            // Invisible embedded host for WebAssembly Proof-of-Work solver
            PowSolverHostView()
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .allowsHitTesting(false)

            // Subtle warm ambient light glow at top for desert aesthetic
            VStack {
                RadialGradient(
                    colors: [
                        Color(red: 0.98, green: 0.75, blue: 0.35).opacity(0.08),
                        Color.clear
                    ],
                    center: .top,
                    startRadius: 20,
                    endRadius: 260
                )
                .frame(height: 280)
                Spacer()
            }
            .ignoresSafeArea()

            // Main Content
            VStack(spacing: 0) {
                // Top Navigation Bar
                topBarView
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 6)

                // Warning banner if account is muted
                if authManager.isMuted {
                    mutedWarningBanner
                        .padding(.horizontal, 16)
                        .padding(.vertical, 4)
                }

                // Middle: Welcome View (when empty) or Chat Messages List
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
        .preferredColorScheme(.light) // Pure Light UI
        .contentShape(Rectangle())
        .onTapGesture {
            dismissKeyboard()
        }
        .sheet(isPresented: $showLoginSheet) {
            DeepSeekLoginSheet()
        }
        .sheet(isPresented: $showSettingsSheet) {
            SettingsSheetView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openDeepSeekLoginSheet)) { _ in
            showLoginSheet = true
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
    }

    private func dismissKeyboard() {
        isInputFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    // MARK: - Top Navigation Bar (Liquid Glass)
    private var topBarView: some View {
        HStack {
            // Left menu / drawer button (2 horizontal bars matching image)
            Button {
                dismissKeyboard()
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
                .foregroundStyle(Color.black.opacity(0.85))
            }
            .glassCircleButton(diameter: 46)

            Spacer()

            // Right Action 1: Speaker / Mute Audio
            Button {
                dismissKeyboard()
                let haptic = UIImpactFeedbackGenerator(style: .light)
                haptic.impactOccurred()
                withAnimation { isMutedAudio.toggle() }
            } label: {
                Image(systemName: isMutedAudio ? "speaker.slash" : "speaker.wave.2")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.85))
            }
            .glassCircleButton(diameter: 46)

            // Right Action 2: New Chat / Plus
            Button {
                dismissKeyboard()
                let haptic = UIImpactFeedbackGenerator(style: .light)
                haptic.impactOccurred()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    service.resetConversation()
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.85))
            }
            .glassCircleButton(diameter: 46)
        }
    }

    // MARK: - Center Welcome View (Matches Image 1)
    private var centerWelcomeView: some View {
        VStack(spacing: 24) {
            // Desert & AI Logo for khoa.ai
            KhoaAILogoView(size: 92, showGlow: true)
                .onTapGesture {
                    dismissKeyboard()
                    let haptic = UIImpactFeedbackGenerator(style: .medium)
                    haptic.impactOccurred()
                }

            // Headline Text matching screenshot
            Text("Xin chào, tôi có thể giúp gì cho bạn?")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.black)
                .padding(.horizontal, 28)

            // DeepSeek connection badge
            Button {
                dismissKeyboard()
                showLoginSheet = true
            } label: {
                HStack(spacing: 6) {
                    Circle()
                        .fill(authManager.isAuthenticated ? (authManager.isMuted ? Color.orange : Color.green) : Color.red)
                        .frame(width: 8, height: 8)

                    Text(authManager.isAuthenticated ? (authManager.userEmail.isEmpty ? "Đã kết nối DeepSeek" : authManager.userEmail) : "Chưa kết nối DeepSeek • Chạm để nạp phiên")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.black.opacity(0.75))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background {
                    Capsule()
                        .fill(Color.white.opacity(0.85))
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .overlay(Capsule().strokeBorder(Color.black.opacity(0.08), lineWidth: 1))
                        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
                }
            }
        }
        .padding(.bottom, 40)
        .contentShape(Rectangle())
        .onTapGesture {
            dismissKeyboard()
        }
    }

    // MARK: - Chat Scroll View
    private var chatScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 18) {
                    ForEach(service.messages) { msg in
                        ChatBubbleView(message: msg)
                            .id(msg.id)
                    }

                    Color.clear
                        .frame(height: 120)
                }
                .padding(.top, 12)
            }
            .scrollDismissesKeyboard(.interactively)
            .contentShape(Rectangle())
            .onTapGesture {
                dismissKeyboard()
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
                    .foregroundStyle(Color.black)
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
                .glassPill(active: service.isThinkingEnabled, accentColor: Color(red: 0.12, green: 0.45, blue: 0.95))

                // Pill 2: Tìm kiếm (Web Search) - Matches blue style in Image 1
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
                .modifier(WebSearchPillModifier(active: service.isSearchEnabled))

                Spacer()

                // Plus action button
                Button {
                    dismissKeyboard()
                    let haptic = UIImpactFeedbackGenerator(style: .light)
                    haptic.impactOccurred()
                    showActionMenu = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.85))
                }
                .glassCircleButton(diameter: 40)

                // Voice Waveform button or Send Button
                if inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button {
                        dismissKeyboard()
                        let haptic = UIImpactFeedbackGenerator(style: .medium)
                        haptic.impactOccurred()
                    } label: {
                        Image(systemName: "waveform")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.black.opacity(0.85))
                    }
                    .glassCircleButton(diameter: 40)
                } else {
                    Button {
                        let haptic = UIImpactFeedbackGenerator(style: .medium)
                        haptic.impactOccurred()
                        let msg = inputText
                        inputText = ""
                        dismissKeyboard()
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
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.white, Color.black.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.0
                        )
                }
                .shadow(color: Color.black.opacity(0.08), radius: 18, x: 0, y: 8)
                .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 1)
        }
    }

    // MARK: - Muted Warning Banner
    private var mutedWarningBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.orange)
                .font(.system(size: 16))

            Text("Tài khoản DeepSeek bị mute/hạn chế. Chạm vào đây để đổi tài khoản khác.")
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

// Custom Pill Modifier matching Image 1 for Web Search
struct WebSearchPillModifier: ViewModifier {
    var active: Bool

    func body(content: Content) -> some View {
        content
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundStyle(Color(red: 0.12, green: 0.45, blue: 0.95))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background {
                Capsule()
                    .fill(Color(red: 0.93, green: 0.96, blue: 1.0))
                    .overlay(
                        Capsule().strokeBorder(
                            active ? Color(red: 0.12, green: 0.45, blue: 0.95).opacity(0.5) : Color(red: 0.85, green: 0.90, blue: 0.98),
                            lineWidth: active ? 1.4 : 0.8
                        )
                    )
            }
    }
}
