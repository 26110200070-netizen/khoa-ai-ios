//
//  ChatBubbleView.swift
//  KhoaAI
//
//  Created by Khoa Dev.
//  Rich Markdown message renderer with Code Blocks, Tables matching Image 2,
//  proper paragraph line-spacing matching modern AI apps, animated 3-dot thinking loader,
//  and image previews.
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
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 10) {
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
            // Attached Image Preview
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
                    .lineSpacing(4)
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
        VStack(alignment: .leading, spacing: 14) {
            // State A: Initial 3-dots Bouncing Loader
            if message.text.isEmpty && message.thinkingText.isEmpty && message.isStreaming {
                ThreeBouncingDotsView()
                    .padding(.vertical, 8)
            }

            // State B: DeepSeek-R1 Thinking Block
            if !message.thinkingText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
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

                    if isThinkingExpanded {
                        HStack(alignment: .top, spacing: 12) {
                            Rectangle()
                                .fill(Color.secondary.opacity(0.25))
                                .frame(width: 2)
                                .clipShape(Capsule())

                            Text(message.thinkingText)
                                .font(.system(size: 13.5, weight: .regular, design: .default))
                                .foregroundStyle(Color.secondary.opacity(0.88))
                                .lineSpacing(5)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 2)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }

            // State C: Full Markdown Answer Content
            if !message.text.isEmpty {
                RichMarkdownView(content: message.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // State D: Bottom Action Toolbar
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
        .padding(.top, 6)
    }
}

// MARK: - Animated 3-Dots Bouncing Loader
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

// MARK: - Full Rich Markdown Renderer with Generous Line Spacing
struct RichMarkdownView: View {
    let content: String

    var body: some View {
        let blocks = parseMarkdownBlocks(content)
        VStack(alignment: .leading, spacing: 14) {
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
                        .font(.system(size: 16.5, weight: .regular, design: .default))
                        .lineSpacing(6.5)
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
            .padding(.bottom, 2)
    }
}

// MARK: - Markdown White Code Card with Copy Button & Syntax Highlighting
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

            // Code Content: Smaller font size (11.5pt), Syntax Highlighting, scrollable horizontally
            ScrollView(.horizontal, showsIndicators: false) {
                HighlightedCodeView(code: code)
                    .padding(14)
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

// MARK: - Syntax Highlighting Code View
struct HighlightedCodeView: View {
    let code: String

    var body: some View {
        highlightedText(for: code)
            .lineSpacing(3.5)
            .textSelection(.enabled)
    }

    private func highlightedText(for code: String) -> Text {
        let lines = code.components(separatedBy: "\n")
        var result = Text("")

        for (i, line) in lines.enumerated() {
            result = result + highlightLine(line)
            if i < lines.count - 1 {
                result = result + Text("\n")
            }
        }
        return result
    }

    private func highlightLine(_ line: String) -> Text {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        // Full line comment
        if trimmed.hasPrefix("//") || trimmed.hasPrefix("#") {
            return Text(line)
                .font(.system(size: 11.5, weight: .regular, design: .monospaced))
                .foregroundColor(Color(red: 0.55, green: 0.58, blue: 0.62))
        }

        let keywords: Set<String> = [
            "import", "func", "let", "var", "if", "else", "return", "guard", "switch", "case",
            "default", "for", "in", "while", "class", "struct", "enum", "protocol", "extension",
            "public", "private", "fileprivate", "internal", "open", "static", "override",
            "self", "Self", "true", "false", "nil", "null", "def", "from", "as",
            "try", "catch", "throw", "throws", "async", "await", "const", "function"
        ]

        let tokens = splitLineIntoTokens(line)
        var lineText = Text("")

        for token in tokens {
            if keywords.contains(token) {
                lineText = lineText + Text(token)
                    .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(red: 0.65, green: 0.15, blue: 0.75)) // Purple
            } else if (token.hasPrefix("\"") && token.hasSuffix("\"") && token.count >= 2) ||
                      (token.hasPrefix("'") && token.hasSuffix("'") && token.count >= 2) {
                lineText = lineText + Text(token)
                    .font(.system(size: 11.5, weight: .regular, design: .monospaced))
                    .foregroundColor(Color(red: 0.18, green: 0.58, blue: 0.32)) // Green string
            } else if Double(token) != nil {
                lineText = lineText + Text(token)
                    .font(.system(size: 11.5, weight: .regular, design: .monospaced))
                    .foregroundColor(Color(red: 0.85, green: 0.45, blue: 0.12)) // Orange number
            } else if token.first?.isUppercase == true && token.count > 1 {
                lineText = lineText + Text(token)
                    .font(.system(size: 11.5, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color(red: 0.12, green: 0.45, blue: 0.85)) // Blue type
            } else {
                lineText = lineText + Text(token)
                    .font(.system(size: 11.5, weight: .regular, design: .monospaced))
                    .foregroundColor(Color.black.opacity(0.88))
            }
        }

        return lineText
    }

    private func splitLineIntoTokens(_ line: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        var inString = false
        var quoteChar: Character? = nil

        for char in line {
            if inString {
                current.append(char)
                if char == quoteChar {
                    inString = false
                    quoteChar = nil
                    tokens.append(current)
                    current = ""
                }
            } else if char == "\"" || char == "'" {
                if !current.isEmpty {
                    tokens.append(current)
                    current = ""
                }
                inString = true
                quoteChar = char
                current.append(char)
            } else if char.isLetter || char.isNumber || char == "_" {
                current.append(char)
            } else {
                if !current.isEmpty {
                    tokens.append(current)
                    current = ""
                }
                tokens.append(String(char))
            }
        }

        if !current.isEmpty {
            tokens.append(current)
        }

        return tokens
    }
}

// MARK: - Markdown Table View Matching Image 2 (ChatGPT Style 100%)
// Clean, seamless, borderless design with thin horizontal dividers and airy row spacing.
struct MarkdownTableView: View {
    let headers: [String]
    let rows: [[String]]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Header Row
                HStack(alignment: .top, spacing: 16) {
                    ForEach(headers.indices, id: \.self) { cIdx in
                        Text(cleanCell(headers[cIdx]))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.black.opacity(0.9))
                            .frame(minWidth: columnMinWidth(for: cIdx), alignment: .leading)
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 2)

                Divider()
                    .background(Color.black.opacity(0.12))

                // Data Rows
                ForEach(rows.indices, id: \.self) { rIdx in
                    let row = rows[rIdx]
                    HStack(alignment: .top, spacing: 16) {
                        ForEach(headers.indices, id: \.self) { cIdx in
                            let rawCell = cIdx < row.count ? row[cIdx] : ""
                            Text(cleanCell(rawCell))
                                .font(.system(size: 14.5, weight: .regular))
                                .foregroundStyle(Color.black.opacity(0.86))
                                .lineSpacing(3)
                                .frame(minWidth: columnMinWidth(for: cIdx), alignment: .leading)
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 2)

                    if rIdx < rows.count - 1 {
                        Divider()
                            .background(Color.black.opacity(0.06))
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }

    private func columnMinWidth(for colIndex: Int) -> CGFloat {
        if colIndex == 0 {
            return 85
        } else if colIndex == 1 {
            return 125
        } else {
            return 115
        }
    }

    private func cleanCell(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "*", with: "")
            .replacingOccurrences(of: "`", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
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

    func splitCells(_ line: String) -> [String] {
        var trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("|") { trimmed.removeFirst() }
        if trimmed.hasSuffix("|") { trimmed.removeLast() }
        return trimmed.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
    }

    func isSeparatorRow(_ line: String) -> Bool {
        let cleaned = line.replacingOccurrences(of: "|", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: ":", with: "")
            .trimmingCharacters(in: .whitespaces)
        return cleaned.isEmpty && line.contains("-")
    }

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

        // 2. Table detection (starts with | or contains | with dashes in next line)
        if line.contains("|") && idx + 1 < lines.count && isSeparatorRow(lines[idx + 1]) {
            let headerCells = splitCells(line).filter { !$0.isEmpty }
            idx += 2 // skip header and separator row
            var tableRows: [[String]] = []
            while idx < lines.count && lines[idx].contains("|") {
                let rowCells = splitCells(lines[idx])
                if !rowCells.isEmpty && !isSeparatorRow(lines[idx]) {
                    tableRows.append(rowCells)
                }
                idx += 1
            }
            if !headerCells.isEmpty {
                blocks.append(.table(headers: headerCells, rows: tableRows))
                continue
            }
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

        // 4. Regular Paragraphs
        var paraLines: [String] = []
        while idx < lines.count {
            let cur = lines[idx]
            if cur.trimmingCharacters(in: .whitespaces).hasPrefix("```") ||
               (cur.contains("|") && idx + 1 < lines.count && isSeparatorRow(lines[idx + 1])) ||
               cur.hasPrefix("# ") || cur.hasPrefix("## ") || cur.hasPrefix("### ") {
                break
            }
            if cur.trimmingCharacters(in: .whitespaces).isEmpty && !paraLines.isEmpty {
                idx += 1
                break
            }
            paraLines.append(cur)
            idx += 1
        }

        let combined = paraLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        if !combined.isEmpty {
            blocks.append(.paragraph(text: combined))
        }
    }

    return blocks
}
