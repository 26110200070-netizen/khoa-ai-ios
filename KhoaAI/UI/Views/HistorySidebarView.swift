//
//  HistorySidebarView.swift
//  KhoaAI
//
//  Created by Khoa Dev.
//  Chat history sidebar drawer matching Image 1 100%:
//  - Capsule search pill "Tìm kiếm nội dung trò chu..."
//  - Section header "Hôm nay" with slider filter icon
//  - Soft blue session card with blue title "Chào hỏi" and ellipsis
//  - Bottom profile bar with purple circular avatar [A], "Alo khoa", and ellipsis.
//

import SwiftUI

public struct HistorySidebarView: View {
    @ObservedObject private var conversationManager = ConversationManager.shared
    @ObservedObject private var authManager = DeepSeekAuthManager.shared
    @ObservedObject private var service = DeepSeekService.shared

    @Binding var isOpen: Bool
    var onSelectSession: (ConversationSession) -> Void
    var onNewChat: () -> Void
    var onOpenSettings: () -> Void

    @State private var searchText: String = ""

    public init(
        isOpen: Binding<Bool>,
        onSelectSession: @escaping (ConversationSession) -> Void,
        onNewChat: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void
    ) {
        self._isOpen = isOpen
        self.onSelectSession = onSelectSession
        self.onNewChat = onNewChat
        self.onOpenSettings = onOpenSettings
    }

    private var filteredSessions: [ConversationSession] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return conversationManager.sessions
        }
        return conversationManager.sessions.filter { $0.title.localizedCaseInsensitiveContains(trimmed) }
    }

    public var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                // Top Safe Area Spacer (Moved down a bit per user request)
                Color.clear
                    .frame(height: max(proxy.safeAreaInsets.top, 50) + 18)

                // Top Capsule Search Bar (Matching Image 1 100%)
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color.secondary.opacity(0.8))
                        .font(.system(size: 15))

                    TextField("Tìm kiếm nội dung trò chu...", text: $searchText)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(Color.black.opacity(0.85))

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Color.secondary.opacity(0.6))
                                .font(.system(size: 14))
                        }
                    }
                }
                .padding(.horizontal, 14)
                .frame(height: 44)
                .background(Color.white)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 16)

                // Section Header: "Hôm nay" with slider icon (Matching Image 1)
                HStack {
                    Text("Hôm nay")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.black.opacity(0.65))

                    Spacer()

                    Button {
                        let haptic = UIImpactFeedbackGenerator(style: .light)
                        haptic.impactOccurred()
                    } label: {
                        Image(systemName: "slider.horizontal.2")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.black.opacity(0.6))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 10)

                // Middle Section: Chat Sessions List
                ScrollView {
                    LazyVStack(spacing: 8) {
                        if filteredSessions.isEmpty {
                            // Default item matching Image 1
                            sessionCard(
                                title: "Chào hỏi",
                                isSelected: true,
                                onSelect: {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                        isOpen = false
                                    }
                                },
                                onDelete: {}
                            )
                        } else {
                            ForEach(filteredSessions) { session in
                                sessionCard(
                                    title: session.title.isEmpty ? "Chào hỏi" : session.title,
                                    isSelected: session.id == service.activeChatSessionId,
                                    onSelect: {
                                        let haptic = UIImpactFeedbackGenerator(style: .light)
                                        haptic.impactOccurred()
                                        onSelectSession(session)
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                            isOpen = false
                                        }
                                    },
                                    onDelete: {
                                        let haptic = UIImpactFeedbackGenerator(style: .medium)
                                        haptic.impactOccurred()
                                        conversationManager.deleteSession(session)
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 2)
                }

                Spacer()

                // Bottom Profile Bar (Matching Image 1 100%: Purple [A] circle + "Alo khoa" + "...")
                HStack(spacing: 12) {
                    // Purple circle avatar with white "A"
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.52, green: 0.16, blue: 0.67))
                            .frame(width: 36, height: 36)

                        Text("A")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(Color.white)
                    }

                    Text("Alo khoa")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(Color.black.opacity(0.9))

                    Spacer()

                    // Trailing "..." button
                    Button {
                        onOpenSettings()
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.black.opacity(0.45))
                            .padding(8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, max(proxy.safeAreaInsets.bottom, 18))
                .background(Color(red: 0.99, green: 0.99, blue: 0.99))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.99, green: 0.99, blue: 0.99))
        .ignoresSafeArea(.all, edges: .vertical)
    }

    // Single Session Card (Matching Image 1)
    private func sessionCard(
        title: String,
        isSelected: Bool,
        onSelect: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) -> some View {
        HStack {
            Button {
                onSelect()
            } label: {
                Text(title)
                    .font(.system(size: 15.5, weight: .semibold))
                    .foregroundStyle(Color(red: 0.22, green: 0.45, blue: 0.98))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Menu {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Xóa cuộc trò chuyện", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.black.opacity(0.35))
                    .padding(6)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(red: 0.93, green: 0.95, blue: 1.0))
        )
    }
}
