//
//  TrackingLog.swift
//  iTrackerMap
//
//  Created by Danny Tsang on 9/9/22.
//

import Foundation

struct TrackingLog: Codable {
    var log: [TrackPoint]
}

struct TrackPoint: Codable, Identifiable {
    var id = UUID()
    let latitude: Double
    let longitude: Double
    let timestamp: Date

    let title: String?
    let subTitle: String?
    let address: String?
}
