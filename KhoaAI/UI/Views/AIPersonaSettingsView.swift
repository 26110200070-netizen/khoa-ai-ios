//
//  AIPersonaSettingsView.swift
//  KhoaAI
//
//  Created by Khoa Dev.
//  Custom AI Persona and User Teaching Instructions screen.
//

import SwiftUI

public struct AIPersonaSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("khoa_ai_custom_instructions") private var customInstructions: String = ""

    @State private var draftInstructions: String = ""
    @State private var showSavedNotification: Bool = false

    public init() {}

    private let suggestions: [(title: String, prompt: String)] = [
        ("Xưng hô thân thiện", "Hãy xưng hô là 'Em' và gọi tôi là 'Anh'. Văn phong lễ phép, ngọt ngào và chu đáo."),
        ("Chuyên gia Lập trình", "Hãy trả lời như một Senior Software Engineer: Code chuẩn tối ưu, phân tích kiến trúc sâu sắc, không nói dài dòng."),
        ("Ngắn gọn & Trọng tâm", "Trả lời siêu ngắn gọn, đi thẳng vào đáp án, không giải thích rườm rà trừ khi tôi yêu cầu."),
        ("Gia sư kiên nhẫn", "Hãy đóng vai một người thầy kiên nhẫn, giải thích các khái niệm phức tạp bằng ví dụ đời sống dễ hiểu."),
        ("Sáng tạo & Hài hước", "Luôn phản hồi với góc nhìn thông minh, hài hước, hóm hỉnh và truyền cảm hứng tích cực.")
    ]

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header card with AI brain icon
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 50, height: 50)

                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 24))
                                .foregroundStyle(Color.white)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Dạy khoa.ai tính cách riêng")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(Color.black.opacity(0.9))

                            Text("Mọi điều bạn nhập tại đây sẽ được AI ghi nhớ và áp dụng trong mọi câu trả lời.")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.secondary)
                        }
                    }
                    .padding(14)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 3)

                    // Text Editor Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("YÊU CẦU / KIẾN THỨC DẠY AI:")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.secondary)

                        ZStack(alignment: .topLeading) {
                            if draftInstructions.isEmpty {
                                Text("Ví dụ: 'Hãy luôn xưng hô em và gọi tôi là anh', 'Tôi là lập trình viên iOS, hãy ưu tiên viết code bằng Swift', 'Tôi ăn chay, hãy chỉ gợi ý món chay'...")
                                    .font(.system(size: 15))
                                    .foregroundStyle(Color.secondary.opacity(0.6))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 14)
                                    .allowsHitTesting(false)
                            }

                            TextEditor(text: $draftInstructions)
                                .font(.system(size: 15, weight: .regular))
                                .frame(minHeight: 160)
                                .padding(10)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                        }
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
                        )
                    }

                    // Suggestions Chips
                    VStack(alignment: .leading, spacing: 10) {
                        Text("GỢI Ý TÍNH CÁCH NHANH:")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(suggestions, id: \.title) { item in
                                    Button {
                                        let haptic = UIImpactFeedbackGenerator(style: .light)
                                        haptic.impactOccurred()
                                        if !draftInstructions.isEmpty {
                                            draftInstructions += "\n" + item.prompt
                                        } else {
                                            draftInstructions = item.prompt
                                        }
                                    } label: {
                                        HStack(spacing: 5) {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.system(size: 12))
                                            Text(item.title)
                                                .font(.system(size: 13, weight: .medium))
                                        }
                                        .foregroundStyle(Color(red: 0.12, green: 0.45, blue: 0.95))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color(red: 0.12, green: 0.45, blue: 0.95).opacity(0.08))
                                        .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }

                    // Action Buttons
                    VStack(spacing: 12) {
                        Button {
                            let haptic = UIImpactFeedbackGenerator(style: .medium)
                            haptic.impactOccurred()
                            customInstructions = draftInstructions.trimmingCharacters(in: .whitespacesAndNewlines)
                            withAnimation { showSavedNotification = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                dismiss()
                            }
                        } label: {
                            HStack {
                                if showSavedNotification {
                                    Image(systemName: "checkmark")
                                    Text("Đã lưu chỉ dẫn thành công!")
                                } else {
                                    Image(systemName: "square.and.arrow.down.fill")
                                    Text("Lưu chỉ dẫn tính cách")
                                }
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                LinearGradient(
                                    colors: [Color.blue, Color(red: 0.4, green: 0.2, blue: 0.9)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        }

                        if !draftInstructions.isEmpty {
                            Button(role: .destructive) {
                                let haptic = UIImpactFeedbackGenerator(style: .light)
                                haptic.impactOccurred()
                                draftInstructions = ""
                                customInstructions = ""
                            } label: {
                                Text("Xóa & Trở về mặc định")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color.red.opacity(0.85))
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.top, 10)
                }
                .padding(20)
            }
            .background(Color(red: 0.97, green: 0.97, blue: 0.98).ignoresSafeArea())
            .navigationTitle("Tính cách & Dạy AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                draftInstructions = customInstructions
            }
        }
    }
}
