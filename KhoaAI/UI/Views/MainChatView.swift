//
//  MainChatView.swift
//  KhoaAI
//
//  Created by Khoa Dev.
//  Pure Light UI Liquid Glass Chat Interface with Neural AI Vision, Full Markdown, History Drawer, and Image Suggestion Chips.
//

import SwiftUI
import UIKit
import PhotosUI
import Vision
import PDFKit

public struct MainChatView: View {
    @StateObject private var service = DeepSeekService.shared
    @StateObject private var authManager = DeepSeekAuthManager.shared
    @ObservedObject private var conversationManager = ConversationManager.shared

    @State private var inputText: String = ""
    @State private var isMutedAudio: Bool = false
    @State private var showLoginSheet: Bool = false
    @State private var showSettingsSheet: Bool = false
    @State private var showAttachmentDrawer: Bool = false

    // Attachment Picker States
    @State private var showCameraPicker: Bool = false
    @State private var showPhotoPicker: Bool = false
    @State private var showDocPicker: Bool = false
    @State private var pickedImage: UIImage? = nil
    @State private var selectedAttachment: AttachedMedia? = nil
    @State private var isProcessingAttachment: Bool = false

    // History Sidebar Drawer States
    @State private var isDrawerOpen: Bool = false
    @State private var dragOffset: CGFloat = 0.0

    // Scroll States (Matching Image 4)
    @State private var showScrollToBottomButton: Bool = false
    @State private var isScrolledUp: Bool = false

    @FocusState private var isInputFocused: Bool

    private let drawerWidth: CGFloat = min(UIScreen.main.bounds.width * 0.85, 320)

    public init() {}

    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background & Main Chat View
                mainContent
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .offset(x: isDrawerOpen ? drawerWidth : max(0, dragOffset))
                    .disabled(isDrawerOpen)

                // Scrim Dimming Background Overlay
                if isDrawerOpen || dragOffset > 0 {
                    Color.black.opacity(scrimOpacity)
                        .ignoresSafeArea()
                        .onTapGesture {
                            dismissKeyboard()
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                                isDrawerOpen = false
                                dragOffset = 0
                            }
                        }
                }

                // History Sidebar Drawer (Slides in from Left, respects Safe Area)
                HistorySidebarView(
                    isOpen: $isDrawerOpen,
                    onSelectSession: { session in
                        service.loadSession(session)
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            isDrawerOpen = false
                            dragOffset = 0
                        }
                    },
                    onNewChat: {
                        service.resetConversation()
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            isDrawerOpen = false
                            dragOffset = 0
                        }
                    },
                    onOpenSettings: {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            isDrawerOpen = false
                            dragOffset = 0
                        }
                        showSettingsSheet = true
                    }
                )
                .frame(width: drawerWidth)
                .background(Color(red: 0.98, green: 0.98, blue: 0.99))
                .clipShape(RoundedRectangle(cornerRadius: isDrawerOpen ? 24 : 0, style: .continuous))
                .shadow(color: Color.black.opacity(isDrawerOpen ? 0.25 : 0), radius: 24, x: 12, y: 0)
                .offset(x: drawerCurrentOffset)
                .ignoresSafeArea(edges: .vertical)
            }
            .gesture(
                // Interactive Swipe-to-Open / Swipe-to-Close Gesture matching video
                DragGesture(minimumDistance: 12, coordinateSpace: .local)
                    .onChanged { value in
                        if !isDrawerOpen {
                            if value.startLocation.x < 50 && value.translation.width > 0 {
                                dragOffset = min(value.translation.width, drawerWidth)
                            }
                        } else {
                            if value.translation.width < 0 {
                                dragOffset = max(value.translation.width, -drawerWidth)
                            }
                        }
                    }
                    .onEnded { value in
                        let threshold: CGFloat = 70
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            if !isDrawerOpen {
                                if value.translation.width > threshold || value.predictedEndTranslation.width > threshold {
                                    isDrawerOpen = true
                                }
                            } else {
                                if value.translation.width < -threshold || value.predictedEndTranslation.width < -threshold {
                                    isDrawerOpen = false
                                }
                            }
                            dragOffset = 0
                        }
                    }
            )
        }
        .preferredColorScheme(.light)
        .sheet(isPresented: $showLoginSheet) {
            DeepSeekLoginSheet()
        }
        .sheet(isPresented: $showSettingsSheet) {
            SettingsSheetView()
        }
        .sheet(isPresented: $showCameraPicker) {
            CameraPicker(selectedImage: $pickedImage)
        }
        .sheet(isPresented: $showPhotoPicker) {
            PhotoLibraryPicker(selectedImage: $pickedImage)
        }
        .sheet(isPresented: $showDocPicker) {
            DocumentPicker { url in
                handlePickedDocument(url: url)
            }
        }
        .onChange(of: pickedImage) { newImg in
            if let img = newImg {
                handlePickedImage(img)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openDeepSeekLoginSheet)) { _ in
            showLoginSheet = true
        }
    }

    private var scrimOpacity: Double {
        if isDrawerOpen {
            let progress = 1.0 + Double(dragOffset / drawerWidth)
            return max(0.0, min(0.38, 0.38 * progress))
        } else {
            let progress = Double(dragOffset / drawerWidth)
            return max(0.0, min(0.38, 0.38 * progress))
        }
    }

    private var drawerCurrentOffset: CGFloat {
        if isDrawerOpen {
            return min(0, dragOffset)
        } else {
            return -drawerWidth + max(0, dragOffset)
        }
    }

    private func dismissKeyboard() {
        isInputFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    // MARK: - Main Content View
    private var mainContent: some View {
        ZStack {
            // Crisp White Light Background
            Color.white
                .ignoresSafeArea()

            // Invisible embedded host for WebAssembly Proof-of-Work solver
            PowSolverHostView()
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .allowsHitTesting(false)

            // Content Stack
            VStack(spacing: 0) {
                // Top Navigation Bar
                topBarView
                    .padding(.horizontal, 16)
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

                // Bottom Floating Liquid Glass Input Bar + Attachment Drawer
                bottomInputContainer
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            dismissKeyboard()
            if showAttachmentDrawer {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    showAttachmentDrawer = false
                }
            }
        }
    }

    // MARK: - Top Navigation Bar (Liquid Glass)
    private var topBarView: some View {
        HStack(spacing: 10) {
            // Left menu / drawer button (2 horizontal bars matching image)
            Button {
                dismissKeyboard()
                let haptic = UIImpactFeedbackGenerator(style: .light)
                haptic.impactOccurred()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isDrawerOpen.toggle()
                }
            } label: {
                VStack(spacing: 5) {
                    RoundedRectangle(cornerRadius: 1.5)
                        .frame(width: 18, height: 2.2)
                    RoundedRectangle(cornerRadius: 1.5)
                        .frame(width: 13, height: 2.2)
                }
                .foregroundStyle(Color.black.opacity(0.85))
            }
            .glassCircleButton(diameter: 44)

            // Model Selector Menu: default "expert" (DeepSeek-R1)
            Menu {
                Button {
                    service.selectedModel = "expert"
                    let haptic = UIImpactFeedbackGenerator(style: .light)
                    haptic.impactOccurred()
                } label: {
                    HStack {
                        Text("DeepSeek-R1 (Expert)")
                        if service.selectedModel == "expert" {
                            Image(systemName: "checkmark")
                        }
                    }
                }

                Button {
                    service.selectedModel = "default"
                    let haptic = UIImpactFeedbackGenerator(style: .light)
                    haptic.impactOccurred()
                } label: {
                    HStack {
                        Text("DeepSeek-V3 (Standard)")
                        if service.selectedModel == "default" {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    Text(service.selectedModel == "expert" ? "Expert" : "DeepSeek-V3")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.black.opacity(0.85))

                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.black.opacity(0.6))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background {
                    Capsule()
                        .fill(Color.white.opacity(0.92))
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .overlay(Capsule().strokeBorder(Color.black.opacity(0.08), lineWidth: 1))
                        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                }
            }

            Spacer()

            // Right Action 1: Speaker / Mute Audio
            Button {
                dismissKeyboard()
                let haptic = UIImpactFeedbackGenerator(style: .light)
                haptic.impactOccurred()
                withAnimation { isMutedAudio.toggle() }
            } label: {
                Image(systemName: isMutedAudio ? "speaker.slash" : "speaker.wave.2")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.85))
            }
            .glassCircleButton(diameter: 44)

            // Right Action 2: New Chat / Plus
            Button {
                dismissKeyboard()
                let haptic = UIImpactFeedbackGenerator(style: .light)
                haptic.impactOccurred()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    service.resetConversation()
                    pickedImage = nil
                    selectedAttachment = nil
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.85))
            }
            .glassCircleButton(diameter: 44)
        }
    }

    // MARK: - Center Welcome View (NO LOGO, only clean greeting per user request)
    private var centerWelcomeView: some View {
        VStack(spacing: 12) {
            Text("Xin chào, tôi có thể giúp gì cho bạn?")
                .font(.system(size: 23, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.black)
                .padding(.horizontal, 32)
        }
        .padding(.bottom, 60)
        .contentShape(Rectangle())
        .onTapGesture {
            dismissKeyboard()
        }
    }

    // MARK: - Chat Scroll View with Floating Scroll-To-Bottom Arrow (Matching Image 4)
    private var chatScrollView: some View {
        ScrollViewReader { proxy in
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(service.messages) { msg in
                            ChatBubbleView(message: msg)
                                .id(msg.id)
                        }

                        // Invisible bottom anchor
                        Color.clear
                            .frame(height: 110)
                            .id("BOTTOM_ANCHOR")
                    }
                    .padding(.top, 12)
                }
                .scrollDismissesKeyboard(.interactively)
                .contentShape(Rectangle())
                .onTapGesture {
                    dismissKeyboard()
                }

                // Floating Scroll-To-Bottom Downward Arrow Button (Matching Image 4)
                if service.messages.count > 1 {
                    Button {
                        let haptic = UIImpactFeedbackGenerator(style: .light)
                        haptic.impactOccurred()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            proxy.scrollTo("BOTTOM_ANCHOR", anchor: .bottom)
                        }
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color.black.opacity(0.75))
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.96))
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .overlay(Circle().strokeBorder(Color.black.opacity(0.08), lineWidth: 1))
                            .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 3)
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 12)
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }

    // MARK: - Bottom Floating Liquid Glass Input Bar + Attachment Cards (Matching Image 2)
    private var bottomInputContainer: some View {
        VStack(spacing: 12) {
            // Main Input Capsule Card
            VStack(spacing: 10) {
                // Attachment Thumbnail + Suggestion Chips (Matching Image 2!)
                if let attachment = selectedAttachment {
                    VStack(alignment: .leading, spacing: 10) {
                        // Image Thumbnail with (✕) remove button
                        HStack {
                            ZStack(alignment: .topTrailing) {
                                if let img = attachment.image {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 68, height: 68)
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
                                        )
                                } else {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color(red: 0.94, green: 0.96, blue: 1.0))
                                        .frame(width: 68, height: 68)
                                        .overlay(
                                            Image(systemName: "doc.text.fill")
                                                .font(.system(size: 24))
                                                .foregroundStyle(Color.blue)
                                        )
                                }

                                // Dark (✕) close button
                                Button {
                                    selectedAttachment = nil
                                    pickedImage = nil
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(Color.white)
                                        .frame(width: 20, height: 20)
                                        .background(Color.black.opacity(0.65))
                                        .clipShape(Circle())
                                }
                                .offset(x: 5, y: -5)
                            }

                            if isProcessingAttachment {
                                HStack(spacing: 6) {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                    Text("Đang phân tích...")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color.secondary)
                                }
                                .padding(.leading, 8)
                            }

                            Spacer()
                        }
                        .padding(.top, 4)

                        // 3 Quick Suggestion Chips: [Đây là gì →], [Phân tích →], [Đề xuất giải pháp →]
                        // User rule: "Khi user nhập tin nhắn thì gợi ý mất"
                        if inputText.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    suggestionChip(title: "Đây là gì →") {
                                        sendWithPrompt("Đây là gì")
                                    }

                                    suggestionChip(title: "Phân tích →") {
                                        sendWithPrompt("Phân tích chi tiết hình ảnh này")
                                    }

                                    suggestionChip(title: "Đề xuất giải pháp →") {
                                        sendWithPrompt("Đề xuất giải pháp dựa trên hình ảnh này")
                                    }
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(.horizontal, 4)
                }

                // Upper Input Row: TextField
                HStack(alignment: .center, spacing: 10) {
                    TextField("Nhập tin nhắn", text: $inputText, axis: .vertical)
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundStyle(Color.black)
                        .lineLimit(1...5)
                        .focused($isInputFocused)
                        .padding(.horizontal, 6)
                        .padding(.top, 2)

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

                // Lower Controls Row: [Suy nghĩ] [Tìm kiếm] (+) ((•)) (↑/■)
                HStack(spacing: 8) {
                    // Pill 1: Suy nghĩ (DeepThink) - NOT squished, fixedSize!
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
                    .fixedSize(horizontal: true, vertical: false)

                    // Pill 2: Web Search - DEFAULT ACTIVE PER USER REQUEST!
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
                    .fixedSize(horizontal: true, vertical: false)

                    Spacer()

                    // Plus / Xmark Action Button
                    Button {
                        dismissKeyboard()
                        let haptic = UIImpactFeedbackGenerator(style: .light)
                        haptic.impactOccurred()
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.75)) {
                            showAttachmentDrawer.toggle()
                        }
                    } label: {
                        Image(systemName: showAttachmentDrawer ? "xmark" : "plus")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.black.opacity(0.85))
                    }
                    .glassCircleButton(diameter: 40)

                    // Voice Waveform button
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

                    // Send Button OR Stop Button (Matching video!)
                    if service.isGenerating {
                        // Stop generation button (Blue circle with white square inside)
                        Button {
                            let haptic = UIImpactFeedbackGenerator(style: .medium)
                            haptic.impactOccurred()
                            service.stopStreaming()
                        } label: {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Color.white)
                        }
                        .glassCircleButton(diameter: 40, active: true)
                    } else if !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedAttachment != nil {
                        // Blue Send Button (↑)
                        Button {
                            sendWithPrompt(inputText)
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
                    .fill(Color.white.opacity(0.94))
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

            // Attachment Cards Row: Chụp ảnh, Album, Tệp (Automatically resets after selection)
            if showAttachmentDrawer {
                HStack(spacing: 12) {
                    attachmentCard(icon: "camera", label: "Chụp ảnh") {
                        withAnimation { showAttachmentDrawer = false }
                        showCameraPicker = true
                    }

                    attachmentCard(icon: "photo", label: "Album") {
                        withAnimation { showAttachmentDrawer = false }
                        showPhotoPicker = true
                    }

                    attachmentCard(icon: "paperclip", label: "Tệp") {
                        withAnimation { showAttachmentDrawer = false }
                        showDocPicker = true
                    }
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .bottom)),
                    removal: .opacity.combined(with: .scale(scale: 0.95))
                ))
            }
        }
    }

    // Quick Suggestion Chip Builder (Matching Image 2)
    private func suggestionChip(title: String, action: @escaping () -> Void) -> some View {
        Button {
            let haptic = UIImpactFeedbackGenerator(style: .light)
            haptic.impactOccurred()
            action()
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.85))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
                )
        }
    }

    // Attachment Card Builder
    private func attachmentCard(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button {
            let haptic = UIImpactFeedbackGenerator(style: .light)
            haptic.impactOccurred()
            action()
        } label: {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .regular))
                    .foregroundStyle(Color.black.opacity(0.85))

                Text(label)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.black.opacity(0.85))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.96))
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
            }
        }
        .buttonStyle(.plain)
    }

    // Send Message with Prompt and Attachment Context
    private func sendWithPrompt(_ prompt: String) {
        let msg = prompt
        inputText = ""
        let attachment = selectedAttachment
        let img = pickedImage
        selectedAttachment = nil
        pickedImage = nil
        dismissKeyboard()
        if showAttachmentDrawer {
            withAnimation { showAttachmentDrawer = false }
        }

        Task {
            var attachmentCtx = ""
            if let att = attachment {
                if !att.extractedText.isEmpty {
                    attachmentCtx += "[Văn bản nhận diện từ tài liệu/hình ảnh (\(att.name)):\n\(att.extractedText)]\n\n"
                }
                if !att.imageClassifications.isEmpty {
                    attachmentCtx += "[Thông tin nhận diện hình ảnh từ Apple Vision: \(att.imageClassifications.joined(separator: ", "))]\n\n"
                }
            }
            await service.sendMessage(msg, image: img, attachmentContext: attachmentCtx)
        }
    }

    // Handle Image Selection, OCR and Classification
    private func handlePickedImage(_ image: UIImage) {
        isProcessingAttachment = true
        withAnimation { showAttachmentDrawer = false }
        selectedAttachment = AttachedMedia(
            name: "Hình ảnh",
            image: image,
            extractedText: "",
            imageClassifications: [],
            isPDF: false
        )

        Task {
            async let ocrTask = AttachmentHelper.shared.performOCR(on: image)
            async let classifyTask = AttachmentHelper.shared.classifyImage(image: image)

            let (ocrText, labels) = await (ocrTask, classifyTask)

            await MainActor.run {
                if let current = selectedAttachment {
                    selectedAttachment = AttachedMedia(
                        name: current.name,
                        image: current.image,
                        extractedText: ocrText,
                        imageClassifications: labels,
                        isPDF: false
                    )
                }
                isProcessingAttachment = false
            }
        }
    }

    // Handle Document Selection and Text Extraction
    private func handlePickedDocument(url: URL) {
        isProcessingAttachment = true
        withAnimation { showAttachmentDrawer = false }
        let filename = url.lastPathComponent
        let isPdf = url.pathExtension.lowercased() == "pdf"

        Task {
            var extractedText = ""
            if isPdf {
                extractedText = AttachmentHelper.shared.extractTextFromPDF(url: url)
            } else {
                extractedText = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
            }

            await MainActor.run {
                selectedAttachment = AttachedMedia(
                    name: filename,
                    image: nil,
                    extractedText: extractedText,
                    imageClassifications: [],
                    isPDF: isPdf
                )
                isProcessingAttachment = false
            }
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
