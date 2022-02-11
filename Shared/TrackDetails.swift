//
//  TrackDetails.swift
//  GPXer
//
//  Created by Ryan Gilbert on 2/10/22.
//

import SwiftUI
import GPXKit
import MapKit

struct TrackDetails: View {
    @State var track: GPXTrack
    @State var region: MKCoordinateRegion = MKCoordinateRegion()
    
    var body: some View {
        ScrollView {
            VStack {
                MapView(region: $region,
                        lineCoordinates: track.trackPoints
                            .map { CLLocationCoordinate2D($0) })
                    .aspectRatio(4/3, contentMode: .fit)
                HStack {
                    VStack(spacing: 16) {
                        HStack(spacing: 8) {
                            Image(systemName: "mappin")
                                .frame(width: 30, height: 30, alignment: .center)
                            Text("Total Distance:")
                                .fontWeight(.medium)
                            Text(Measurement(value: track.graph.distance,
                                             unit: UnitLength.meters),
                                 formatter: measurementFormatter)
                            Spacer()
                        }
                        HStack(spacing: 8) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .frame(width: 30, height: 30, alignment: .center)
                            Text("Elevation Gain:")
                                .fontWeight(.medium)
                            Text(Measurement(value: track.graph.elevationGain,
                                             unit: UnitLength.meters),
                                 formatter: measurementFormatter)
                            Spacer()
                        }
                    }.padding()
                    Spacer()
                }.background { Color.white }
            }
        }
        .navigationTitle(track.title)
        .onAppear {
            region = track.coordinateRegion
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
    static var previews: some View {
        let trackURL = Bundle.main.url(forResource: "CA_Sec_A_tracks", withExtension: "gpx")
        switch GPXFileParser(url: trackURL!)?.parse() {
        case .failure(let error):
            fatalError("\(error)")
        case .success(let track):
            return TrackDetails(track: track)
        case .none:
            fatalError("Missing file")
        }
    }
}


