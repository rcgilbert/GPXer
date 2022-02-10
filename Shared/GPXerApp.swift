//
//  GPXerApp.swift
//  Shared
//
//  Created by Ryan Gilbert on 2/10/22.
//

import SwiftUI

@main
struct GPXerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
