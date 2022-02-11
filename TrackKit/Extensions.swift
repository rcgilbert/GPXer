//
//  Extensions.swift
//  GPXer
//
//  Created by Ryan Gilbert on 2/10/22.
//

import Foundation
import GPXKit
import MapKit
import SwiftUI

public extension GPXTrackManaged {
    enum GPXTrackManagedError: Error {
        case missingXML
    }
    
    var track: GPXTrack {
        get throws {
            guard let xmlString = xmlString else {
                throw GPXTrackManagedError.missingXML
            }
            
            switch GPXFileParser(xmlString: xmlString).parse() {
            case .failure(let error):
                throw error
            case .success(let track):
                return track
            }
        }
    }
}

public extension GPXTrack {
    var coordinateRegion: MKCoordinateRegion {
        let minCoordinate = CLLocationCoordinate2D(latitude: bounds.minLatitude, longitude: bounds.minLongitude)
        let maxCoordinate = CLLocationCoordinate2D(latitude: bounds.maxLatitude, longitude: bounds.maxLongitude)
        let p1 = MKMapPoint(minCoordinate)
        let p2 = MKMapPoint(maxCoordinate)
        let mapRect = MKMapRect(x: fmin(p1.x,p2.x),
                                y: fmin(p1.y,p2.y),
                                width: fabs(p1.x-p2.x),
                                height: fabs(p1.y-p2.y))
        return MKCoordinateRegion(mapRect)
    }
    
    
    init?(intent: GetMileMarkerIntent) {
        guard let trackId = intent.track?.identifier else {
            return nil
        }
        let request = GPXTrackManaged.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "name LIKE %@", trackId)
        
        guard let track = try? PersistenceController.shared.container.viewContext.fetch(request).first?.track else {
            return nil
        }
        
        self.init(date: track.date, title: track.title, description: track.description, trackPoints: track.trackPoints, keywords: track.keywords)
    }
    
    
    func distance(to: CLLocation) -> Measurement<UnitLength>? {
        guard let closestPoint = closetPoint(to: to),
              let index = trackPoints.firstIndex(of: closestPoint) else {
            return nil
        }
        
        let trackDistance = trackPoints[0...index].reduce((0.0, nil)) {
            ($0.0 + $1.distance(to: $0.1 ?? $1), $1)
        }.0
        
        let totalDistance = closestPoint.location.distance(from: to) + trackDistance
        
        return Measurement<UnitLength>(value: totalDistance, unit: .meters)
    }
    
    func closetPoint(to: CLLocation) -> TrackPoint? {
        trackPoints
            .map { ($0, distance: $0.location.distance(from: to)) }
            .min { c1, c2 in c1.distance < c2.distance }?.0
    }
}

extension TrackPoint {
    var location: CLLocation {
        CLLocation(coordinate: CLLocationCoordinate2D(coordinate),
                   altitude: coordinate.elevation,
                   horizontalAccuracy: 0,
                   verticalAccuracy: 0,
                   timestamp: date ?? Date())
    }
}

public extension URL {
    /// Returns a URL for the given app group and database pointing to the sqlite database.
    static func storeURL(for appGroup: String, databaseName: String) -> URL {
        guard let fileContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
            fatalError("Shared file container could not be created.")
        }

        return fileContainer.appendingPathComponent("\(databaseName).sqlite")
    }
}
