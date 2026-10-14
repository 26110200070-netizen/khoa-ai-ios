//
//  AttachmentHelper.swift
//  KhoaAI
//
//  Created by Khoa Dev.
//  Attachment handling with on-device Apple Neural Vision OCR and PDF text extraction.
//

import SwiftUI
import UIKit
import PhotosUI
import Vision
import PDFKit
import UniformTypeIdentifiers

public struct AttachedMedia: Identifiable, Equatable {
    public let id: String = UUID().uuidString
    public let name: String
    public let image: UIImage?
    public let extractedText: String
    public let imageClassifications: [String]
    public let isPDF: Bool

    public init(
        name: String,
        image: UIImage? = nil,
        extractedText: String = "",
        imageClassifications: [String] = [],
        isPDF: Bool = false
    ) {
        self.name = name
        self.image = image
        self.extractedText = extractedText
        self.imageClassifications = imageClassifications
        self.isPDF = isPDF
    }

    public static func == (lhs: AttachedMedia, rhs: AttachedMedia) -> Bool {
        lhs.id == rhs.id
    }
}

public class AttachmentHelper {
    public static let shared = AttachmentHelper()

    // On-device Apple Vision Optical Character Recognition (OCR)
    public func performOCR(on image: UIImage) async -> String {
        guard let cgImage = image.cgImage else { return "" }

        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard error == nil,
                      let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }

                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }

                let fullText = recognizedStrings.joined(separator: "\n")
                continuation.resume(returning: fullText)
            }

            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["vi-VN", "en-US"]
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                try? handler.perform([request])
            }
        }
    }

    // On-device Apple Vision Scene & Subject Classification
    public func classifyImage(image: UIImage) async -> [String] {
        guard let cgImage = image.cgImage else { return [] }

        return await withCheckedContinuation { continuation in
            let request = VNClassifyImageRequest { request, error in
                guard error == nil,
                      let observations = request.results as? [VNClassificationObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                let topLabels = observations
                    .filter { $0.confidence > 0.15 }
                    .prefix(8)
                    .map { $0.identifier.replacingOccurrences(of: "_", with: " ") }

                continuation.resume(returning: Array(topLabels))
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                try? handler.perform([request])
            }
        }
    }

    // Extract text from PDF document
    public func extractTextFromPDF(url: URL) -> String {
        guard let doc = PDFDocument(url: url) else { return "" }
        var fullText = ""
        for i in 0..<doc.pageCount {
            if let page = doc.page(at: i), let pageContent = page.string {
                fullText += "--- Trang \(i + 1) ---\n" + pageContent + "\n"
            }
        }
        return fullText
    }
}

// SwiftUI Image Picker (Camera & Gallery)
public struct CameraPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    public init(selectedImage: Binding<UIImage?>) {
        self._selectedImage = selectedImage
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
        } else {
            picker.sourceType = .photoLibrary
        }
        return picker
    }

    public func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    public class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker

        init(_ parent: CameraPicker) {
            self.parent = parent
        }

        public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let img = info[.originalImage] as? UIImage {
                parent.selectedImage = img
            }
            parent.dismiss()
        }

        public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// Photo Library Picker via PHPicker
public struct PhotoLibraryPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    public init(selectedImage: Binding<UIImage?>) {
        self._selectedImage = selectedImage
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    public func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    public class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoLibraryPicker

        init(_ parent: PhotoLibraryPicker) {
            self.parent = parent
        }

        public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            guard let item = results.first?.itemProvider, item.canLoadObject(ofClass: UIImage.self) else { return }

            item.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
                if let uiImage = image as? UIImage {
                    DispatchQueue.main.async {
                        self?.parent.selectedImage = uiImage
                    }
                }
            }
        }
    }
}

// Document Picker for PDF, TXT, DOCX, Code
public struct DocumentPicker: UIViewControllerRepresentable {
    var onDocumentPicked: (URL) -> Void
    @Environment(\.dismiss) private var dismiss

    public init(onDocumentPicked: @escaping (URL) -> Void) {
        self.onDocumentPicked = onDocumentPicked
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let types: [UTType] = [.pdf, .plainText, .text, .json, .commaSeparatedText]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    public func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    public class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker

        init(_ parent: DocumentPicker) {
            self.parent = parent
        }

        public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let firstUrl = urls.first {
                parent.onDocumentPicked(firstUrl)
            }
            parent.dismiss()
        }

        public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.dismiss()
        }
    }
}
