//
//  Location.swift
//  Guarded
//
//  Created by Rodrigo Hilkner on 26/10/17.
//  Copyright © 2017 Rodrigo Hilkner. All rights reserved.
//

import Foundation
import CoreLocation

class Place {
    
    var name: String
    var address: String
    var city: String
    var coordinate: Coordinate
    
    init(name: String, address: String, city: String, coordinate: Coordinate) {
        self.name = name
        self.address = address
        self.city = city
        self.coordinate = coordinate
    }
    
}
