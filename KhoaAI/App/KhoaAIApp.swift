//
//  KhoaAIApp.swift
//  KhoaAI
//
//  Created by Khoa Dev.
//  App Entry point for khoa.ai.
//

import SwiftUI

@main
struct KhoaAIApp: App {
    init() {
        // Warm up WebAssembly PoW solver in background
        Task { @MainActor in
            _ = await DeepSeekPowSolver.shared.ensureReady()
        }
    }

    var body: some Scene {
        WindowGroup {
            MainChatView()
        }
    }
}
