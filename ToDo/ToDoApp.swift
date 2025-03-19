//
//  ToDoApp.swift
//  ToDo
//
//  Created by Civan Metin on 2025-01-19.
//

import SwiftUI

@main
struct ToDoApp: App {
    @StateObject private var persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear {
                    NotificationManager.shared.requestAuthorization()
                }
        }
    }
}
