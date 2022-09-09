//
//  TrackingAnnotation.swift
//  iTrackerMap
//
//  Created by Danny Tsang on 9/9/22.
//

import CoreLocation
import MapKit
import UIKit

class TrackingAnnotation:NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subTitle: String?

    init(coordinate: CLLocationCoordinate2D, title: String?, subTitle: String?) {
        self.coordinate = coordinate
        self.title = title
        self.subTitle = subTitle

        super.init()
    }
}
