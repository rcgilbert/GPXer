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
import CoreData
import Combine

public extension GPXTrackManaged {
    enum GPXTrackManagedError: Error {
        case missingXML
    }
    
    var track: GPXTrack {
        get throws {
            guard let xmlString = xml?.stringValue else {
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
    
    var orderedChildren: [GPXTrackManaged]? {
        (children?.allObjects as? [GPXTrackManaged])?.sorted {
            $0.orderIndex < $1.orderIndex
        }
    }
    
    var trackPublisher: AnyPublisher<GPXTrack?, Never> {
        guard let xmlString = xml?.stringValue else {
            return Just(nil).eraseToAnyPublisher()
        }
        
        return GPXFileParser(xmlString: xmlString)
            .publisher
            .subscribe(on: DispatchQueue.global(qos: .userInitiated))
            .map(Optional.some)
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    var childTracksPublisher: AnyPublisher<[GPXTrack], Never> {
        children
            .publisher
            .subscribe(on: DispatchQueue.global(qos: .userInitiated))
            .compactMap {
                ($0.allObjects as? [GPXTrackManaged])?.sorted { $0.orderIndex < $1.orderIndex }
            }
            .compactMap {
                $0.compactMap { try? $0.track }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    var isCompoundTrack: Bool {
        parent == nil && xml?.stringValue?.isEmpty ?? true
    }
    
    convenience init(_ track: GPXTrack, context: NSManagedObjectContext) {
        self.init(context: context)
        name = track.title
        date = track.date ?? Date()
        trackDescription = track.description
        xml = XML(GPXExporter(track: track).xmlString, context: context)
    }
}

public extension XML {
    convenience init(_ xmlString: String, context: NSManagedObjectContext) {
        self.init(context: context)
        stringValue = xmlString
    }
}

public extension GPXTrack {
    var mapRect: MKMapRect {
        let minCoordinate = CLLocationCoordinate2D(latitude: bounds.minLatitude, longitude: bounds.minLongitude)
        let maxCoordinate = CLLocationCoordinate2D(latitude: bounds.maxLatitude, longitude: bounds.maxLongitude)
        let p1 = MKMapPoint(minCoordinate)
        let p2 = MKMapPoint(maxCoordinate)
        return MKMapRect(x: fmin(p1.x,p2.x),
                         y: fmin(p1.y,p2.y),
                         width: fabs(p1.x-p2.x),
                         height: fabs(p1.y-p2.y))
            .insetBy(dx: -graph.distance/4, dy: -graph.distance/4)
    }
    
    var coordinateRegion: MKCoordinateRegion {
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

public extension Collection where Element == GPXTrack {
    var totalDistance: CLLocationDistance {
        reduce(0) { $0 + $1.graph.distance }
    }
    
    var totalElevationGain: CLLocationDistance {
        reduce(0) { $0 + $1.graph.elevationGain }
    }
    
    var coordinateRegion: MKCoordinateRegion {
        let mapRect = map { $0.mapRect }.reduce(MKMapRect.null) { $1.union($0) }
        return MKCoordinateRegion(mapRect)
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


public extension UIColor {
    private static var colors = [UIColor.systemBlue,
                                 UIColor.systemRed,
                                 UIColor.systemCyan,
                                 UIColor.systemPink,
                                 UIColor.systemMint,
                                 UIColor.systemYellow,
                                 UIColor.systemTeal,
                                 UIColor.systemOrange,
                                 UIColor.systemIndigo]
    
    static func color(for index: Int) -> UIColor {
        colors[index%colors.count]
    }
}

public extension MKCoordinateRegion {
    var isValid: Bool {
        CLLocationCoordinate2DIsValid(center)
    }
}
