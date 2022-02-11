//
//  GetMileMarkerIntentHandler.swift
//  TrackKit
//
//  Created by Ryan Gilbert on 2/11/22.
//

import Foundation
import CoreLocation
import Intents
import MapKit
import GPXKit
import CoreData

public class GetMileMarkerIntentHandler: NSObject, GetMileMarkerIntentHandling {
    
    public func handle(intent: GetMileMarkerIntent) async -> GetMileMarkerIntentResponse {
        guard let track = GPXTrack(intent: intent),
              let location = intent.currentLocation?.location,
              let distance = track.distance(to: location) else {
            return GetMileMarkerIntentResponse(code: .failure, userActivity: nil)
        }
        
        
        return GetMileMarkerIntentResponse.success(distance: distance)
    }
    
    public func provideTrackOptionsCollection(for intent: GetMileMarkerIntent) async throws -> INObjectCollection<Track> {
        let fetch: NSFetchRequest<GPXTrackManaged> = GPXTrackManaged.fetchRequest()
        let context = PersistenceController.shared.container.viewContext
        let tracks = try context.fetch(fetch)
        return INObjectCollection(items: tracks.map { Track(identifier: $0.name ?? "Track", display: $0.name ?? "Track") })
    }
    
    public func resolveCurrentLocation(for intent: GetMileMarkerIntent) async -> INPlacemarkResolutionResult {
        if let location = intent.currentLocation {
            return INPlacemarkResolutionResult.success(with: location)
        } else {
            return INPlacemarkResolutionResult.needsValue()
        }
    }
    
    
    public func resolveTrack(for intent: GetMileMarkerIntent) async -> TrackResolutionResult {
        if let track = intent.track {
            return TrackResolutionResult.success(with: track)
        } else {
            return TrackResolutionResult.needsValue()
        }
        
    }
}
