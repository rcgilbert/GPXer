//
//  TrackDetails.swift
//  GPXer
//
//  Created by Ryan Gilbert on 2/10/22.
//

import SwiftUI
import GPXKit
import MapKit
import TrackKit

struct TrackDetailsView: View {
    @Environment(\.editMode) var mode
    @Environment(\.managedObjectContext) private var viewContext
    
    @Namespace var namespace
    
    @State var trackManaged: GPXTrackManaged
    @State var region: MKCoordinateRegion = MKCoordinateRegion()
    @State var trackTitle: String = ""
    @State var showDocumentPicker = false
    @State var allTracks: [GPXTrack] = []
    @State var isMapExpanded = false
    @State var shareFiles: [URL]?
    
    @StateObject var locationManager = LocationManager()
    @StateObject var gpxLoader: GPXLoader = GPXLoader()
    
    var body: some View {
        ZStack {
            List {
                Section {
                    ZStack {
                        MapView(region: $region,
                                tracks: $allTracks)
                            .frame(minHeight: 300)
                            
                        VStack {
                            Spacer()
                            HStack(spacing: 16) {
                                Spacer()
                                Button {
                                    withAnimation {
                                        isMapExpanded.toggle()
                                    }
                                } label: {
                                    Image(systemName: isMapExpanded ? "arrow.down.forward.and.arrow.up.backward": "arrow.up.left.and.arrow.down.right")
                                        .padding(8)
                                        .foregroundColor(Color(uiColor: UIColor.label))
                                        .background(.ultraThinMaterial)
                                        .cornerRadius(5)
                                        .offset(CGSize(width: -8, height: -8))
                                }
                            }
                        }
                    }.matchedGeometryEffect(id: "map", in: namespace)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowSeparator(.hidden)
                }
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 16) {
                            if mode?.wrappedValue.isEditing ?? false {
                                TextField(trackTitle, text: $trackTitle)
                                    .font(.largeTitle)
                                    .textFieldStyle(.roundedBorder)
                            } else {
                                Text(trackTitle)
                                    .font(.largeTitle)
                            }
                            if !allTracks.isEmpty {
                                HStack(spacing: 16) {
                                    HStack {
                                        Image(systemName: "mappin")
                                            .frame(width: 30, height: 30, alignment: .center)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Total Distance")
                                                .fontWeight(.medium)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text(Measurement(value: allTracks.totalDistance,
                                                             unit: UnitLength.meters),
                                                 formatter: measurementFormatter)
                                        }
                                    }
                                    HStack {
                                        Image(systemName: "chart.line.uptrend.xyaxis")
                                            .frame(width: 30, height: 30, alignment: .center)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Elevation Gain")
                                                .fontWeight(.medium)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text(Measurement(value: allTracks.totalElevationGain,
                                                             unit: UnitLength.meters),
                                                 formatter: measurementFormatter)
                                        }
                                    }
                                    Spacer()
                                }
                            }
                        }.padding()
                        Spacer()
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowSeparator(.hidden)
                    .background { Color(UIColor.systemBackground) }
                }
                Section {
                    if trackManaged.isCompoundTrack {
                        TrackChildrenList(parent: trackManaged)
                    }
                }
            }
            .listStyle(.plain)
            if isMapExpanded {
                ExpandedMapView(region: $region, allTracks: $allTracks, isMapExpanded: $isMapExpanded)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .matchedGeometryEffect(id: "map", in: namespace)
                    .transition(.scale)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task {
                        do {
                            self.shareFiles = try await trackManaged.getFiles()
                        } catch {
                            // TODO: Error handling
                        }
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
#if os(iOS)
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
#endif
            ToolbarItem {
                if trackManaged.isCompoundTrack {
                    Button {
                        showDocumentPicker.toggle()
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                } else {
                    EmptyView()
                }
            }
            
            
        }
        .onChange(of: mode!.wrappedValue.isEditing) { isEditing in
            if !isEditing && trackTitle != trackManaged.name {
                update(title: trackTitle)
            }
        }
        .onReceive(trackManaged.trackPublisher) { track in
            guard let track = track else {
                return
            }
            
            withAnimation {
                allTracks = [track]
                region = allTracks.coordinateRegion
            }
        }
        .onReceive(trackManaged.childTracksPublisher) { tracks in
            guard !tracks.isEmpty else {
                return
            }
            withAnimation {
                allTracks = tracks
                region = tracks.coordinateRegion
            }
        }
        .onChange(of: trackManaged) {
            trackTitle = $0.name ?? "Track"
        }
        .onReceive(gpxLoader.$tracks) { tracks in
            tracks.forEach { addTrack($0) }
        }
        .sheet(isPresented: $showDocumentPicker) {
            GPXDocumentPicker { urls in
                gpxLoader.getTracks(urls)
            }
        }
        .sheet(item: $shareFiles) { files in
            ShareSheet(activityItems: files)
        }
        .onAppear {
            region = allTracks.coordinateRegion
            trackTitle = trackManaged.name ?? "Track"
            locationManager.requestPermission()
        }
    }
    
    private func update(title: String) {
        trackManaged.name = title
        do {
            try viewContext.save()
        } catch {
            fatalError("Unabled to save name! \(error)")
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.compactMap {
                trackManaged.orderedChildren?[$0]
            }.forEach(viewContext.delete)
            
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
    
    private func addTrack(_ track: GPXTrack) {
        withAnimation {
            let newItem = GPXTrackManaged(track, context: viewContext)
            newItem.orderIndex = Int32(trackManaged.children?.count ?? 0)
            
            newItem.parent = trackManaged
            trackManaged.children = trackManaged.children?.adding(newItem) as NSSet?
            
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

struct TrackChildrenList: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest var tracks: FetchedResults<GPXTrackManaged>
    
    var parent: GPXTrackManaged
    
    init(parent: GPXTrackManaged) {
        _tracks = FetchRequest<GPXTrackManaged>(sortDescriptors:  [NSSortDescriptor(keyPath: \GPXTrackManaged.orderIndex,
                                                                                    ascending: true),
                                                                   NSSortDescriptor(keyPath:\GPXTrackManaged.date,
                                                                                    ascending: true),
                                                                   NSSortDescriptor(keyPath:\GPXTrackManaged.name,
                                                                                    ascending: true)],
                                                predicate: NSPredicate(format: "parent == %@", parent),
                                                animation: .default)
        self.parent = parent
    }
    
    var body: some View {
        ForEach(Array(tracks.enumerated()), id: \.offset) { index, track in
            NavigationLink {
                TrackDetailsView(trackManaged: track)
            } label: {
                HStack {
                    Circle()
                        .foregroundColor(Color(UIColor.color(for: index)))
                        .frame(width: 16)
                        .shadow(radius: 1, x: 1, y: 1)
    
                    Text(track.name ?? "Track")
                }
            }
        }
        .onDelete { indexSet in
            deleteItems(offsets: indexSet)
        }
        .onMove(perform: move)
    }
    
    func move(from source: IndexSet, to destination: Int) {
        // Make an array of items from fetched results
        var revisedItems = tracks.map { $0 }
        
        // change the order of the items in the array
        revisedItems.move(fromOffsets: source, toOffset: destination )
        
        // update the userOrder attribute in revisedItems to
        // persist the new order. This is done in reverse order
        // to minimize changes to the indices.
        for reverseIndex in stride(from: revisedItems.count - 1,
                                   through: 0,
                                   by: -1) {
            revisedItems[reverseIndex].orderIndex = Int32(reverseIndex)
        }
        
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
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

struct ExpandedMapView: View {
    @Namespace var namespace
    
    @Binding var region: MKCoordinateRegion
    @Binding var allTracks: [GPXTrack]
    @Binding var isMapExpanded: Bool
    
    var body: some View {
        ZStack {
            MapView(region: $region,
                    tracks: $allTracks)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .edgesIgnoringSafeArea([.bottom, .leading, .trailing])
            VStack {
                Spacer()
                HStack(spacing: 16) {
                    Spacer()
                    Button {
                        withAnimation {
                            isMapExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: isMapExpanded ? "arrow.down.forward.and.arrow.up.backward": "arrow.up.left.and.arrow.down.right")
                            .padding(8)
                            .foregroundColor(Color(uiColor: UIColor.label))
                            .background(.ultraThinMaterial)
                            .cornerRadius(5)
                            .offset(CGSize(width: -8, height: -8))
                    }
                }
            }
        }
    }
}

private var measurementFormatter: MeasurementFormatter = {
    let formatter = MeasurementFormatter()
    formatter.locale = .current
    formatter.unitOptions = [.naturalScale]
    return formatter
}()

struct TrackDetails_Previews: PreviewProvider {
    static var context = PersistenceController.preview.container.viewContext
    @State static var mode: EditMode = .inactive
    
    static var previews: some View {
        guard let trackURL = Bundle.main.url(forResource: "CA_Sec_A_tracks", withExtension: "gpx") else {
            fatalError("Missing file")
        }
        
        switch GPXFileParser(url: trackURL)?.parse() {
        case .failure(let error):
            fatalError("\(error)")
        case .success(let track):
            
            return NavigationView {
                TrackDetailsView(trackManaged: GPXTrackManaged(track,
                                                                      context: context))
                    .environment(\.managedObjectContext, context)
                    .environment(\.editMode, $mode)
            }
        case .none:
            fatalError("Missing file")
        }
    }
}


extension Array: Identifiable where Element: Hashable {
    public var id: Self {
        self
    }
}
