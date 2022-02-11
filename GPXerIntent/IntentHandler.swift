//
//  IntentHandler.swift
//  GPXerIntent
//
//  Created by Ryan Gilbert on 2/10/22.
//

import Intents
import TrackKit

class IntentHandler: INExtension {
    override func handler(for intent: INIntent) -> Any {
        if intent is GetMileMarkerIntent {
            return GetMileMarkerIntentHandler()
        }
        
        fatalError("Unhandled intent type: \(intent)")
    }
}
