//
//  CreateCompoundGPXView.swift
//  GPXer (iOS)
//
//  Created by Ryan Gilbert on 2/15/22.
//

import SwiftUI
import GPXKit
import TrackKit

struct CreateCompoundGPXView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    @State var trackTitle: String = ""
    @State var tracks: [GPXTrack] = []
    @State var error: Error?
    @State var showDocumentPicker = false
    
    @StateObject var gpxLoader: GPXLoader = GPXLoader()
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        TextField("Track Name", text: $trackTitle)
                            .font(.title2)
                        Spacer()
                    }
                }
                Section {
                    ForEach(tracks, id: \.hashValue) { track in
                        Text(track.title)
                    }
                    .onMove { source, destination in
                        tracks.move(fromOffsets: source,
                                    toOffset: destination)
                    }
                    .onDelete { index in
                        index.forEach {
                            tracks.remove(at: $0)
                        }
                    }
                } footer: {
                    HStack {
                        Spacer()
                        Button {
                            showDocumentPicker.toggle()
                        } label: {
                            Text("Add Tracks")
                                .font(.body)
                                .fontWeight(.medium)
                                .frame(minWidth: 200)
                                .padding(4)
                        }
                        .buttonStyle(.borderedProminent)
                        Spacer()
                    }
                   
                }
            }
            .safeAreaInset(edge: .top) {
                Spacer()
                    .frame(height: 16)
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Create Track")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        presentationMode
                            .wrappedValue
                            .dismiss()
                    } label: {
                        Text("Close")
                    }
                }
                ToolbarItem {
                    EditButton()
                }
                ToolbarItem(placement:
                                    .navigationBarTrailing) {
                    Button("Save") {
                        save()
                    }
                }
                
            }
            .onReceive(gpxLoader.$tracks) { tracks in
                self.tracks = tracks
            }
            .onReceive(gpxLoader.$error) {
                error = $0
            }
            .sheet(isPresented: $showDocumentPicker) {
                GPXDocumentPicker { urls in
                    gpxLoader.getTracks(urls)
                }
            }
        }
    }
    
    private func save() {
        let parent = GPXTrackManaged(context: viewContext)
        parent.name = trackTitle
        let children: [GPXTrackManaged] = tracks.enumerated().map {
            let track = GPXTrackManaged($0.element, context: viewContext)
            track.orderIndex = Int32($0.offset)
            track.parent = parent
            return track
        }
        parent.children = NSSet(array: children)
        
        do {
            try viewContext.save()
            presentationMode
                .wrappedValue.dismiss()
        } catch {
            self.error = error
        }
    }
}

struct CreateCompoundGPXView_Previews: PreviewProvider {
    static var previews: some View {
        CreateCompoundGPXView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        
    }
}
