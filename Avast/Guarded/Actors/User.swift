//
//  User.swift
//  Avast
//
//  Created by Rodrigo Hilkner on 06/10/17.
//  Copyright © 2017 Rodrigo Hilkner. All rights reserved.
//

import Foundation
import CoreLocation

//TODO: abtract class
class User {
    
    var id: String
    var name: String
    var email: String?
    var phoneNumber: String?

    init(id: String, name: String, email: String?, phoneNumber: String?) {
        self.id = id
        self.name = name
        self.email = email
        self.phoneNumber = phoneNumber
    }
    
}