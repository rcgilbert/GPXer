//
//  MapView.swift
//  GPXer
//
//  Created by Ryan Gilbert on 2/10/22.
//

import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @State var lineCoordinates: [CLLocationCoordinate2D]
    
    func makeUIView(context: Context) -> some UIView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.region = region
        let polyLine = MKPolyline(coordinates: lineCoordinates, count: lineCoordinates.count)
        map.addOverlay(polyLine)
        return map
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        (uiView as? MKMapView)?.region = region
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
            if let routePolyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: routePolyline)
                renderer.strokeColor = UIColor.systemBlue
                renderer.lineWidth = 5
                return renderer
              }
              return MKOverlayRenderer()
        }
    }
    
}
