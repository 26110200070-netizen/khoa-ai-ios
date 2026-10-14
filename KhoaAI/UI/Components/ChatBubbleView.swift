//
//  ChatBubbleView.swift
//  KhoaAI
//
//  Created by Khoa Dev.
//  Rich Markdown message renderer with Code Blocks (copyable white cards), Tables, Headings,
//  Animated 3-dot thinking loader, and image previews matching user design.
//

import SwiftUI
import UIKit

public struct ChatBubbleView: View {
    public let message: ChatMessage
    @State private var isThinkingExpanded: Bool = true
    @State private var copied: Bool = false
    @State private var liked: Bool? = nil

    public init(message: ChatMessage) {
        self.message = message
    }

    public var body: some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8) {
            if message.isUser {
                userBubble
            } else {
                aiResponseView
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }

    // MARK: - User Message Bubble
    private var userBubble: some View {
        VStack(alignment: .trailing, spacing: 6) {
            // Attached Image Preview (Matching Image 3)
            if let image = message.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 240, maxHeight: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
            }

            // User Text Query Bubble
            if !message.text.isEmpty {
                Text(message.text)
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundStyle(Color.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                    .background {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color(red: 0.94, green: 0.96, blue: 1.0))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .strokeBorder(Color.blue.opacity(0.12), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    // MARK: - AI Response View
    private var aiResponseView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // State A: Initial 3-dots Bouncing Loader (Matching video think_72.png)
            if message.text.isEmpty && message.thinkingText.isEmpty && message.isStreaming {
                ThreeBouncingDotsView()
                    .padding(.vertical, 8)
            }

            // State B: DeepSeek-R1 Thinking Block (Matching Image 3 & Video)
            if !message.thinkingText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    // Header toggle: "Suy nghĩ ᨈ" or "Đã suy nghĩ xong ›"
                    Button {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                            isThinkingExpanded.toggle()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(message.isThinking ? "Suy nghĩ" : "Đã suy nghĩ xong")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.secondary)

                            Image(systemName: isThinkingExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color.secondary.opacity(0.8))

                            if message.isThinking {
                                ProgressView()
                                    .scaleEffect(0.6)
                                    .padding(.leading, 2)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    // Indented Thinking Content with Left Gray Accent Border
                    if isThinkingExpanded {
                        HStack(alignment: .top, spacing: 12) {
                            Rectangle()
                                .fill(Color.secondary.opacity(0.25))
                                .frame(width: 2)
                                .clipShape(Capsule())

                            Text(message.thinkingText)
                                .font(.system(size: 13.5, weight: .regular, design: .default))
                                .foregroundStyle(Color.secondary.opacity(0.88))
                                .lineSpacing(4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 2)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }

            // State C: Full Markdown Answer Content (Headings, Tables, White Code Cards)
            if !message.text.isEmpty {
                RichMarkdownView(content: message.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // State D: Bottom Action Toolbar (Copy, Thumbs Up/Down, TTS, Share)
            if !message.text.isEmpty && !message.isStreaming {
                aiActionToolbar
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Action Toolbar
    private var aiActionToolbar: some View {
        HStack(spacing: 16) {
            // Copy
            Button {
                UIPasteboard.general.string = message.text
                let haptic = UIImpactFeedbackGenerator(style: .light)
                haptic.impactOccurred()
                withAnimation { copied = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    withAnimation { copied = false }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 13))
                    if copied {
                        Text("Đã chép")
                            .font(.system(size: 11, weight: .medium))
                    }
                }
                .foregroundStyle(copied ? Color.green : Color.secondary.opacity(0.7))
            }

            // Like / Thumbs Up
            Button {
                let haptic = UIImpactFeedbackGenerator(style: .light)
                haptic.impactOccurred()
                liked = (liked == true) ? nil : true
            } label: {
                Image(systemName: liked == true ? "hand.thumbsup.fill" : "hand.thumbsup")
                    .font(.system(size: 13))
                    .foregroundStyle(liked == true ? Color.blue : Color.secondary.opacity(0.7))
            }

            // Dislike / Thumbs Down
            Button {
                let haptic = UIImpactFeedbackGenerator(style: .light)
                haptic.impactOccurred()
                liked = (liked == false) ? nil : false
            } label: {
                Image(systemName: liked == false ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                    .font(.system(size: 13))
                    .foregroundStyle(liked == false ? Color.red : Color.secondary.opacity(0.7))
            }

            // Share
            ShareLink(item: message.text) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.secondary.opacity(0.7))
            }

            Spacer()
        }
        .padding(.top, 4)
    }
}

// MARK: - Animated 3-Dots Bouncing Loader (Matching think_72.png)
struct ThreeBouncingDotsView: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.secondary.opacity(0.45))
                    .frame(width: 7, height: 7)
                    .offset(y: phase == CGFloat(index) ? -4 : 0)
            }
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 0.35)
                .repeatForever(autoreverses: true)
            ) {
                phase = 2
            }
        }
    }
}

// MARK: - Full Rich Markdown Renderer
struct RichMarkdownView: View {
    let content: String

    var body: some View {
        let blocks = parseMarkdownBlocks(content)
        VStack(alignment: .leading, spacing: 12) {
            ForEach(blocks.indices, id: \.self) { idx in
                switch blocks[idx] {
                case .codeBlock(let lang, let code):
                    MarkdownCodeCard(language: lang, code: code)

                case .table(let headers, let rows):
                    MarkdownTableView(headers: headers, rows: rows)

                case .heading(let level, let text):
                    MarkdownHeadingView(level: level, text: text)

                case .paragraph(let text):
                    Text(LocalizedStringKey(text))
                        .font(.system(size: 17, weight: .regular, design: .default))
                        .lineSpacing(5)
                        .foregroundStyle(Color.black.opacity(0.92))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

// MARK: - Markdown Headings (# ## ###)
struct MarkdownHeadingView: View {
    let level: Int
    let text: String

    var body: some View {
        Text(LocalizedStringKey(text))
            .font(.system(
                size: level == 1 ? 22 : (level == 2 ? 19 : 17.5),
                weight: .bold,
                design: .rounded
            ))
            .foregroundStyle(Color.black)
            .padding(.top, level == 1 ? 8 : 4)
    }
}

// MARK: - Markdown White Code Card with Copy Button
struct MarkdownCodeCard: View {
    let language: String
    let code: String
    @State private var copied: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Code Card Header: Language Tag + Copy Button
            HStack {
                Text(language.isEmpty ? "CODE" : language.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.secondary)

                Spacer()

                Button {
                    UIPasteboard.general.string = code
                    let haptic = UIImpactFeedbackGenerator(style: .light)
                    haptic.impactOccurred()
                    withAnimation { copied = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                        withAnimation { copied = false }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 11))
                        Text(copied ? "Đã sao chép" : "Sao chép")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(copied ? Color.green : Color.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color(.systemGray6).opacity(0.6))

            Divider()

            // Code Content: Smaller font size, scrollable horizontally
            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.black.opacity(0.9))
                    .lineSpacing(3)
                    .padding(14)
                    .textSelection(.enabled)
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        .padding(.vertical, 4)
    }
}

// MARK: - Markdown Table Grid View
struct MarkdownTableView: View {
    let headers: [String]
    let rows: [[String]]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Header Row
                HStack(spacing: 0) {
                    ForEach(headers.indices, id: \.self) { idx in
                        Text(headers[idx])
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .frame(minWidth: 90, alignment: .leading)
                            .background(Color(.systemGray6))

                        if idx < headers.count - 1 {
                            Divider()
                        }
                    }
                }
                .border(Color.black.opacity(0.08), width: 1)

                // Data Rows
                ForEach(rows.indices, id: \.self) { rIdx in
                    let row = rows[rIdx]
                    HStack(spacing: 0) {
                        ForEach(headers.indices, id: \.self) { cIdx in
                            let cell = cIdx < row.count ? row[cIdx] : ""
                            Text(cell)
                                .font(.system(size: 13))
                                .foregroundStyle(Color.black.opacity(0.88))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .frame(minWidth: 90, alignment: .leading)
                                .background(rIdx % 2 == 0 ? Color.white : Color(.systemGray6).opacity(0.3))

                            if cIdx < headers.count - 1 {
                                Divider()
                            }
                        }
                    }
                    .border(Color.black.opacity(0.06), width: 0.5)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.black.opacity(0.1), lineWidth: 1)
            )
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Markdown Block Parsing Helper
enum MarkdownBlock {
    case heading(level: Int, text: String)
    case codeBlock(lang: String, code: String)
    case table(headers: [String], rows: [[String]])
    case paragraph(text: String)
}

func parseMarkdownBlocks(_ raw: String) -> [MarkdownBlock] {
    var blocks: [MarkdownBlock] = []
    let lines = raw.components(separatedBy: "\n")
    var idx = 0

    while idx < lines.count {
        let line = lines[idx]

        // 1. Code Block detection
        if line.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
            let lang = String(line.trimmingCharacters(in: .whitespaces).dropFirst(3)).trimmingCharacters(in: .whitespaces)
            var codeLines: [String] = []
            idx += 1
            while idx < lines.count {
                let codeLine = lines[idx]
                if codeLine.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                    idx += 1
                    break
                }
                codeLines.append(codeLine)
                idx += 1
            }
            blocks.append(.codeBlock(lang: lang, code: codeLines.joined(separator: "\n")))
            continue
        }

        // 2. Table detection (starts with | and followed by separator | --- |)
        if line.contains("|") && idx + 1 < lines.count && lines[idx + 1].contains("|") && lines[idx + 1].contains("-") {
            let headerCells = line.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            idx += 2 // skip header and separator row
            var tableRows: [[String]] = []
            while idx < lines.count && lines[idx].contains("|") {
                let rowCells = lines[idx].split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }
                if !rowCells.isEmpty {
                    tableRows.append(rowCells)
                }
                idx += 1
            }
            blocks.append(.table(headers: headerCells, rows: tableRows))
            continue
        }

        // 3. Headings
        if line.hasPrefix("# ") {
            blocks.append(.heading(level: 1, text: String(line.dropFirst(2))))
            idx += 1
            continue
        } else if line.hasPrefix("## ") {
            blocks.append(.heading(level: 2, text: String(line.dropFirst(3))))
            idx += 1
            continue
        } else if line.hasPrefix("### ") {
            blocks.append(.heading(level: 3, text: String(line.dropFirst(4))))
            idx += 1
            continue
        }

        // 4. Regular Paragraph / Bullet list (accumulate until empty line or code/table)
        var paraLines: [String] = []
        while idx < lines.count {
            let cur = lines[idx]
            if cur.trimmingCharacters(in: .whitespaces).hasPrefix("```") ||
               (cur.contains("|") && idx + 1 < lines.count && lines[idx + 1].contains("-")) ||
               cur.hasPrefix("# ") || cur.hasPrefix("## ") || cur.hasPrefix("### ") {
                break
            }
            paraLines.append(cur)
            idx += 1
            if cur.trimmingCharacters(in: .whitespaces).isEmpty && paraLines.count > 1 {
                break
            }
        }

        let combined = paraLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        if !combined.isEmpty {
            blocks.append(.paragraph(text: combined))
        }
    }

    return blocks
}
