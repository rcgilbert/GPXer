//
//  GPXLoader.swift
//  GPXer (iOS)
//
//  Created by Ryan Gilbert on 2/11/22.
//

import Foundation
import GPXKit
import Combine

class GPXLoader: ObservableObject {
    @Published var tracks: [GPXTrack] = []
    @Published var error: Error?
    
    private var cancellable: AnyCancellable?
    
    init() {
        
    }
    
    func getTracks(_ urls: [URL]) {
        cancellable = urls
            .publisher
            .flatMap(GPXFileParser.load(from:))
            .collect().sink  { completion in
                switch completion {
                case .failure(let error):
                    self.error = error
                case .finished:
                    break
                }
            } receiveValue: { tracks in
                self.tracks = tracks
            }
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
            self.tracks = [track]
        }
    }
}
