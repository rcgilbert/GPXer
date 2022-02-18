//
//  ShareSheet.swift
//  GPXer (iOS)
//
//  Created by Ryan Gilbert on 2/18/22.
//

import Foundation
import SwiftUI

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    let excludedActivityTypes: [UIActivity.ActivityType]? = nil
    let callback: UIActivityViewController.CompletionWithItemsHandler? = nil
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let share = UIActivityViewController(activityItems: activityItems,
                                             applicationActivities: applicationActivities)
        share.completionWithItemsHandler = callback
        share.excludedActivityTypes = excludedActivityTypes
        return share
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
}
