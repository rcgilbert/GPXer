//
//  MapView.swift
//  GPXer
//
//  Created by Ryan Gilbert on 2/10/22.
//

import SwiftUI
import MapKit
import GPXKit

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var tracks: [GPXTrack]
    
    func makeUIView(context: Context) -> some UIView {
        let map = MKMapView()
        map.delegate = context.coordinator
        if region.isValid {
            map.region = region
        }
        map.showsUserLocation = true
        
        tracks.map {
            $0.trackPoints.map { CLLocationCoordinate2D($0) }
        }.enumerated().forEach {
            let polyLine = ColorPolyLine(coordinates: $0.element, count: $0.element.count)
            polyLine.color = UIColor.color(for: $0.offset)
            map.addOverlay(polyLine)
        }
        
        return map
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        let map = uiView as? MKMapView
        if region.isValid {
            map?.setRegion(region, animated: true)
        }
        
        map?.removeOverlays(map?.overlays ?? [])
        let overlays: [MKOverlay] = tracks.map {
            $0.trackPoints.map { CLLocationCoordinate2D($0) }
        }.enumerated().map {
            let polyLine = ColorPolyLine(coordinates: $0.element, count: $0.element.count)
            polyLine.color = UIColor.color(for: $0.offset)
            return polyLine
        }
        map?.addOverlays(overlays)
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        
        init(_ parent: MapView) {
            self.parent = parent
            super.init()
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let routePolyline = overlay as? ColorPolyLine {
                let renderer = MKPolylineRenderer(polyline: routePolyline)
                renderer.strokeColor = routePolyline.color
                renderer.lineWidth = 5
                return renderer
              }
              return MKOverlayRenderer()
        }
    }
    
}

class ColorPolyLine: MKPolyline {
    var color: UIColor?
}
