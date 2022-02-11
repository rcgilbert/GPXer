//
//  GPXDocumentPicker.swift
//  GPXer
//
//  Created by Ryan Gilbert on 2/10/22.
//

import SwiftUI

struct GPXDocumentPicker: UIViewControllerRepresentable {
    public let pickedCompletionHandler: (URL) -> Void
    
    func makeCoordinator() -> DocumentPickerCoordinator {
        DocumentPickerCoordinator(self)
    }
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.init(filenameExtension: "gpx")!], asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
    }
    
    class DocumentPickerCoordinator: NSObject, UIDocumentPickerDelegate {
        var parent: GPXDocumentPicker
        
        init(_ parent: GPXDocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else {
                return
            }
            parent.pickedCompletionHandler(url)
        }
    }
}

