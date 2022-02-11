//
//  ContentView.swift
//  Shared
//
//  Created by Ryan Gilbert on 2/10/22.
//

import SwiftUI
import CoreData
import GPXKit
import Combine
import TrackKit

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \GPXTrackManaged.date, ascending: true)],
        animation: .default)
    private var tracks: FetchedResults<GPXTrackManaged>
    
    @State var fileURL: URL?
    @State var showDocumentPicker = false
    @State var error: Error? {
        didSet {
            showError = error != nil
        }
    }
    @State var showError = false
    
    @StateObject var gpxLoader: GPXLoader = GPXLoader()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(tracks) { track in
                    NavigationLink {
                        if let track = try? track.track {
                            TrackDetails(track: track)
                        }
                    } label: {
                        VStack(alignment: .leading) {
                            Text(track.name!)
                            if let desc = track.trackDescription {
                                Text(desc)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .navigationTitle("Tracks")
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
#endif
                ToolbarItem {
                    Button {
                        showDocumentPicker.toggle()
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            Text("Select an item")
        }
        .onReceive(gpxLoader.$track) {
            if let track = $0 {
                addTrack(track)
            }
        }
        .onReceive(gpxLoader.$error) {
            error = $0
        }
        .sheet(isPresented: $showDocumentPicker) {
            GPXDocumentPicker { url in
                gpxLoader.getTrack(url)
            }
        }.alert(error?.localizedDescription ?? "Error Occured", isPresented: $showError) {
            
        }
    }

    private func addTrack(_ track: GPXTrack) {
        withAnimation {
            let newItem = GPXTrackManaged(context: viewContext)
            newItem.name = track.title
            newItem.date = track.date ?? Date()
            newItem.trackDescription = track.description
            newItem.xmlString = GPXExporter(track: track).xmlString
            
            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { tracks[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}


class GPXLoader: ObservableObject {
    @Published var track: GPXTrack?
    @Published var error: Error?
    
    private var cancellable: AnyCancellable?
    
    init() {
        
    }
    
    func getTrack(_ url: URL) {
        cancellable = GPXFileParser.load(from: url).sink { completion in
            switch completion {
            case .failure(let error):
                self.error = error
            case .finished:
                break
            }
        } receiveValue: { track in
            self.track = track
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
