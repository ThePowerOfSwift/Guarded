//
//  FirebaseManager.swift
//  Guarded
//
//  Created by Rodrigo Hilkner on 26/10/17.
//  Copyright © 2017 Rodrigo Hilkner. All rights reserved.
//

import Foundation
import FirebaseDatabase
import CoreLocation

class DatabaseManager {
    
    ///FIRDatabaseReference for the root of Guarded's Firebase Database
    static var ref: DatabaseReference = Database.database().reference()
    
    ///Checks connection with Firebase Database backend
    static func checkConnection(completionHandler: @escaping (Bool) -> Void) {
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        
        connectedRef.observeSingleEvent(of: .value) {
            snapshot in
            if let connected = snapshot.value as? Bool, connected {
                print("Connected")
            } else {
                print("Not connected")
            }
        }
    }
    
    ///Adds user object to database
    static func addUser(_ user: MainUser, completionHandler: @escaping (Error?) -> Void) {
        self.fetchUser(userID: user.id) {
            (userFetched) in
            
            if (userFetched != nil) {
                print("User was already included in the DB. Updating his name and email informations.")
            }
            
            let userRef = ref.child("users").child(user.id)
            
            let lastLocationDict: [String : AnyObject] = [
                "latitude": "" as AnyObject,
                "longitude": "" as AnyObject
            ]
            
            let userDict: [String : AnyObject] = [
                "name": user.name as AnyObject,
                "email": user.email as AnyObject,
                "phoneNumber": user.phoneNumber as AnyObject,
                "lastLocation": lastLocationDict as AnyObject,
                "helpButtonOccurrences": "" as AnyObject,
                "places": "" as AnyObject,
                "protectors": "" as AnyObject,
                "protected": "" as AnyObject
            ]
            
            userRef.setValue(userDict) {
                (error, _) in
                
                guard (error == nil) else {
                    completionHandler(error)
                    return
                }
                
                completionHandler(nil)
            }
        }
    }
    
    ///Copies user's parameters (name, email) to his object in database
    static func updateUser(_ user: MainUser, completionHandler: @escaping (Error?) -> Void) {
        
        let userRef = ref.child("users/\(user.id)")
        
        let userDict: [AnyHashable: Any] = [
            "name": user.name,
            "email": user.email,
            "phoneNumber": user.phoneNumber,
            "lastLocation/latitude": user.lastLocation!.latitude as Double,
            "lastLocation/longitude": user.lastLocation!.longitude as Double
        ]
        
        userRef.updateChildValues(userDict) {
            (error, _) in
            
            guard (error == nil) else {
                completionHandler(error)
                return
            }
            
            completionHandler(nil)
        }
    }
    
    ///Adds protector to user's protectors list and also adds user as protector's protected list
    static func addProtector(_ protector: Protector, completionHandler: @escaping (Error?) -> Void) {
        
        let usersRef = ref.child("users")
        let dispatchGroup = DispatchGroup()
        
        //TODO: transaction block without downloading the whole "users" json
        
        dispatchGroup.enter()
        
        usersRef.child(AppSettings.mainUser!.id).child("protectors").child(protector.id).setValue(true) {
            (error, _) in
            
            guard (error == nil) else {
                completionHandler(error)
                return
            }
            
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        
        usersRef.child(protector.id).child("protected").child(AppSettings.mainUser!.id).setValue(true) {
            (error, _) in
            
            guard (error == nil) else {
                completionHandler(error)
                return
            }
            
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            completionHandler(nil)
        }
    }

	///Deactivate the protector turning its value false
	static func deactivateProtector(_ protector: Protector, completionHandler: @escaping (Error?) -> Void) {

		let usersRef = ref.child("users")

		//TODO: transaction block without downloading the whole "users" json

        usersRef.child(AppSettings.mainUser!.id).child("protectors").child(protector.id).setValue(false) {
            (error, _) in
            
            guard (error == nil) else {
                completionHandler(error)
                return
            }
            
            completionHandler(nil)
        }
        
        usersRef.child(protector.id).child("protected").child(AppSettings.mainUser!.id).setValue(false) {
            (error, _) in
            
            guard (error == nil) else {
                completionHandler(error)
                return
            }
            
            completionHandler(nil)
        }
	}
    
    ///Removes protector to user's protectors list and also removes user as protector's protected list
    static func removeProtector(_ protector: Protector, completionHandler: @escaping (Error?) -> Void) {
        
        let usersRef = ref.child("users")
        
        let valuesToSet: [String : Any] = [
            "\(AppSettings.mainUser!.id)/protectors/\(protector.id)": NSNull(),
            "\(protector.id)/protected/\(AppSettings.mainUser!.id)": NSNull()
        ]
        
        usersRef.setValue(valuesToSet) {
            (error, _) in
            
            guard (error == nil) else {
                completionHandler(error)
                return
            }
            
            completionHandler(nil)
        }
    }
    
    ///Adds place to user's places list
    static func addPlace(_ place: Place, completionHandler: @escaping (Error?) -> Void) {
        
        let placeRef = ref.child("users").child(AppSettings.mainUser!.id).child("places").child(place.name)

        let placeDict: [String : Any] = [
            "address": place.address,
            "coordinates": [
                "latitude": place.coordinate.latitude,
                "longitude": place.coordinate.longitude
            ]
        ]
        
        placeRef.setValue(placeDict) {
            (error, _) in
            
            guard (error == nil) else {
                completionHandler(error)
                return
            }
            
            completionHandler(nil)
        }
    }
    
    ///Removes place from user's places list
    static func removePlace(_ place: Place, completionHandler: @escaping (Error?) -> Void) {
        
        let placeRef = ref.child("users/\(AppSettings.mainUser!.id)/places/\(place.name)")
        
        placeRef.removeValue {
            (error, _) in
            guard (error == nil) else {
                completionHandler(error)
                return
            }
            
            completionHandler(nil)
        }
    }
    
    ///Fetches user's basic profile information (id, name, email, phone number) from dictionary built by database snapshot.
    static func fetchUserBasicInfo(userDictionary: [String : AnyObject]) -> User? {
        
        guard let userID = userDictionary["id"] as? String else {
            print("Fetching user's id from DB returns nil.")
            return nil
        }
        
        guard let userName = userDictionary["name"] as? String else {
            print("Fetching user's name from DB returns nil.")
            return nil
        }
        
        guard let userEmail = userDictionary["email"] as? String else {
            print("Fetching user's email from DB returns nil.")
            return nil
        }
        
        guard let userPhoneNumber = userDictionary["phoneNumber"] as? String else {
            print("Fetching user's phone number from DB returns nil.")
            return nil
        }
        
        let user = User(id: userID, name: userName, email: userEmail, phoneNumber: userPhoneNumber, status: userStatus.safe)
        print("User (\(user.name)) fetched successfully.")
		return User(id: userID, name: userName, email: userEmail, phoneNumber: userPhoneNumber, status: userStatus.safe)
    }
    
    
    
    ///Fetches user's detailed profile information (places, protectors, protected) from dictionary built by database snapshot.
    ///Returns true if successfull and false otherwise.
    static func fetchUserDetailedInfo(user: MainUser, userDictionary: [String : AnyObject], completionHandler: @escaping (Bool) -> Void) {
        
        let placesDict = userDictionary["places"] as? [String : AnyObject] ?? [:]

        //Reading user's places
        
        guard let userPlaces = readPlaces(placesDict: placesDict) else {
            print("Fetching user's places from DB returns nil.")
            completionHandler(false)
            return
        }

        //Reading user's protectors
        
        let protectorsDict = userDictionary["protectors"] as? [String : AnyObject] ?? [:]
        
        var userProtectors: [Protector] = []
        
        let dispatchGroup = DispatchGroup()
        
        for protectorDict in protectorsDict {
            let protectorID = protectorDict.key

			guard let protectorStatus = protectorDict.value as? Bool else {
				print("Fetching user's protectors' status (on/off) from DB returns nil.")
				completionHandler(false)
				return
			}
            
            dispatchGroup.enter()
                        
            fetchProtector(protectorID: protectorID) {
                (protector) in
                
                guard let protector = protector else {
                    print("Error on fetching protector with id: \(protectorID).")
                    completionHandler(false)
                    return
                }

				protector.protectingYou = protectorStatus

                userProtectors.append(protector)
                
                dispatchGroup.leave()
            }
        }
        
        //Reading user's protecteds
        
        let protectedsDict = userDictionary["protected"] as? [String : AnyObject] ?? [:]
        
        var userProtecteds: [Protected] = []
        
        for protectedDict in protectedsDict {
            let protectedID = protectedDict.key
            
            guard let protectedStatus = protectedDict.value as? Bool else {
                print("Fetching user's protecteds' status (on/off) from DB returns nil.")
                completionHandler(false)
                return
            }

            dispatchGroup.enter()
            
            fetchProtected(protectedID: protectedID) {
                (protected) in
                
                guard let protected = protected else {
                    print("Error on fetching protector with id: \(protectedID).")
                    completionHandler(false)
                    return
                }
                
                protected.allowedToFollow = protectedStatus
                
                userProtecteds.append(protected)

				
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            user.places = userPlaces
            user.protectors = userProtectors
            user.protecteds = userProtecteds
            
            completionHandler(true)
        }
    }
    
    static func fetchUserPlaces(completionHandler: @escaping ([Place]?) -> Void) {
        
        let userRef = ref.child("users/\(String(describing: AppSettings.mainUser?.id))")
        
        userRef.observeSingleEvent(of: .value) {
            (userSnapshot) in
            
            //Getting user's information dictionary
            guard var userDictionary = userSnapshot.value as? [String: AnyObject] else {
                print("User ID fetched returned a nil snapshot from DB.")
                completionHandler(nil)
                return
            }
            
            let placesDict = userDictionary["places"] as? [String : AnyObject] ?? [:]
            
            //Reading user's places
            
            guard let userPlaces = readPlaces(placesDict: placesDict) else {
                print("Fetching user's places from DB returns nil.")
                completionHandler(nil)
                return
            }
            
            completionHandler(userPlaces)
        }
    }
    
    ///Builds main user object from users' database information
    static func fetchUser(userID: String, completionHandler: @escaping (MainUser?) -> Void) {
        
        let userRef = ref.child("users/\(userID)")
        
        userRef.observeSingleEvent(of: .value) {
            (userSnapshot) in
            
            //Getting user's information dictionary
            guard var userDictionary = userSnapshot.value as? [String: AnyObject] else {
                print("User ID fetched returned a nil snapshot from DB.")
                completionHandler(nil)
                return
            }
            
            userDictionary["id"] = userID as AnyObject
            
            //Fetching user's basic information
            
            guard let user = fetchUserBasicInfo(userDictionary: userDictionary) else {
                print("Error on fetching user's (\(userID)) basic profile information.")
                completionHandler(nil)
                return
            }
            
            //TODO: why cant I polymorph User -> MainUser?
            
			let mainUser = MainUser(id: user.id, name: user.name, email: user.email, phoneNumber: user.phoneNumber, status: userStatus.safe)
            
            fetchUserDetailedInfo(user: mainUser, userDictionary: userDictionary) {
                (success) in
                
                guard (success == true) else {
                    print("Error on fetching user's detailed profile information.")
                    completionHandler(nil)
                    return
                }
                
                print("aaaaaaaa \(mainUser.protecteds.count)")
                
                completionHandler(mainUser)
            }
        }
    }
    
    ///Fetches protector information from users' database from his/her ID and returns its object on completionHandler
    static func fetchProtector(protectorID: String, completionHandler: @escaping (Protector?) -> Void) {
        
        let protectorRef = ref.child("users/\(protectorID)")
        
        protectorRef.observeSingleEvent(of: .value) {
            (protectorSnapshot) in
            
            //Getting protector's information dictionary
            guard var protectorDictionary = protectorSnapshot.value as? [String: AnyObject] else {
                print("User ID fetched returned a nil snapshot from DB.")
                completionHandler(nil)
                return
            }
            
            protectorDictionary["id"] = protectorID as AnyObject
            
            //Fetching protector's basic information
            
            guard let user = fetchUserBasicInfo(userDictionary: protectorDictionary) else {
                print("Error on fetching user's (id: \(protectorID)) basic profile information.")
                completionHandler(nil)
                return
            }
            
			let protector = Protector(id: user.id, name: user.name, email: user.email, phoneNumber: user.phoneNumber, status: userStatus.safe)
            
            completionHandler(protector)
        }
    }


    
    ///Fetches protector information from users' database from his/her name and returns its object on completionHandler
    static func fetchProtector(protectorName: String, completionHandler: @escaping (Protector?) -> Void) {
        
        let usersRef = ref.child("users")
        
        usersRef.queryOrdered(byChild: "name").queryEqual(toValue: protectorName).observeSingleEvent(of: .value) {
            (protectorsSnapshot) in
            
            if let protectorsSnapList = protectorsSnapshot.children.allObjects as? [DataSnapshot] {
                
                if (protectorsSnapList.count == 0) {
                    print("No user with this name found on DB.")
                    completionHandler(nil)
                    return
                } else if (protectorsSnapList.count != 1) {
                    print("Found more than one user with this name on DB.")
                    completionHandler(nil)
                    return
                }
                
                let protectorSnap = protectorsSnapList[0]
                
                //Getting protector's information dictionary
                guard var protectedDictionary = protectorSnap.value as? [String: AnyObject] else {
                    print("User ID fetched returned a nil snapshot from DB.")
                    completionHandler(nil)
                    return
                }
                
                protectedDictionary["id"] = protectorSnap.key as AnyObject
                
                //Fetching protector's basic information
                
                guard let user = fetchUserBasicInfo(userDictionary: protectedDictionary) else {
                    print("Error on fetching user's (\(protectorName)) basic profile information.")
                    completionHandler(nil)
                    return
                }
                
				let protector = Protector(id: user.id, name: user.name, email: user.email, phoneNumber: user.phoneNumber, status: userStatus.safe)
                
                completionHandler(protector)
            }
        }
    }
    
    ///Fetches protected information from users' database from his/her ID and returns its object on completionHandler
    static func fetchProtected(protectedID: String, completionHandler: @escaping (Protected?) -> Void) {
        
        let protectedRef = ref.child("users/\(protectedID)")
        
        protectedRef.observeSingleEvent(of: .value) {
            (protectedSnapshot) in
            
            //Getting protector's information dictionary
            guard var protectedDictionary = protectedSnapshot.value as? [String : AnyObject] else {
                print("User ID fetched returned a nil snapshot from DB.")
                return
            }
            
            protectedDictionary["id"] = protectedSnapshot.key as AnyObject
            
            //Fetching protected's basic information
            
            guard let user = fetchUserBasicInfo(userDictionary: protectedDictionary) else {
                print("Error on fetching user's (\(protectedID)) basic profile information.")
                completionHandler(nil)
                return
            }
            
			let protected = Protected(id: user.id, name: user.name, email: user.email, phoneNumber: user.phoneNumber, status: userStatus.safe)
            
            //Fetching protected's last location
            
            guard let lastLocationDict = protectedDictionary["lastLocation"] as? [String : Double] else {
                print("User ID fetched returned last location nil from DB.")
                completionHandler(nil)
                return
            }
            
            guard let protectedLastLocation = fetchLastLocation(lastLocationDict: lastLocationDict) else {
                print("Error on fetching user's (\(protectedID)) last location.")
                completionHandler(nil)
                return
            }
            
            protected.lastLocation = protectedLastLocation
            
            completionHandler(protected)
        }
    }
    
    ///Fetches protected information from users' database from his/her name and returns its object on completionHandler
    static func fetchProtected(protectedName: String, completionHandler: @escaping (Protected?) -> Void) {
        
        let usersRef = ref.child("users")
        
        usersRef.queryEqual(toValue: protectedName, childKey: "name").observeSingleEvent(of: .value) {
            (protectedsSnapshot) in
            
            if let protectedSnapList = protectedsSnapshot.children.allObjects as? [DataSnapshot] {
                
                if (protectedSnapList.count == 0) {
                    print("No user with this name found on DB.")
                    completionHandler(nil)
                    return
                } else if (protectedSnapList.count != 1) {
                    print("Found more than one user with this name on DB.")
                    completionHandler(nil)
                    return
                }
                
                let protectedSnap = protectedSnapList[0]
                
                //Getting protected's information dictionary
                guard var protectedDict = protectedSnap.value as? [String : AnyObject] else {
                    print("User ID fetched returned a nil snapshot from DB.")
                    return
                }
                
                protectedDict["id"] = protectedSnap.key as AnyObject
                
                //Fetching protector's basic information
                guard let protected = fetchUserBasicInfo(userDictionary: protectedDict) as? Protected else {
                    print("Error on fetching user's (\(protectedName)) basic profile information.")
                    completionHandler(nil)
                    return
                }
                
                //Fetching protected's last location
                guard let lastLocationDict = protectedDict["lastLocation"] as? [String : Double] else {
                    print("User ID fetched returned last location nil from DB.")
                    completionHandler(nil)
                    return
                }
                
                
                if let protectedLastLocation = fetchLastLocation(lastLocationDict: lastLocationDict) {
                    protected.lastLocation = protectedLastLocation
                } else {
                    print("Error on fetching user's (\(protectedName)) last location.")
                }
                
                completionHandler(protected)
            }
        }
    }
    
    static func readPlaces(placesDict: [String : AnyObject]) -> [Place]? {
        var userPlaces: [Place] = []
        
        for placeDict in placesDict {
            let placeName: String = placeDict.key
            
            guard let placeAddress = placeDict.value["address"] as? String else {
                print("Fetching user's places from DB returns a place with address nil.")
                return nil
            }
            
            /*  guard let placeCity = placeDict.value["city"] as? String else {
             print("Fetching user's places from DB returns a place with city nil.")
             completionHandler(false)
             return
             } */
            
            guard let placeCoordinatesDict = placeDict.value["coordinates"] as? [String : AnyObject] else {
                print("Fetching user's places from DB returns a place with coordinates nil.")
                return nil
            }
            
            guard let placeLatitude = placeCoordinatesDict["latitude"] as? Double else {
                print("Fetching user's places from DB returns a place with latitude nil.")
                return nil
            }
            
            guard let placeLongitude = placeCoordinatesDict["longitude"] as? Double else {
                print("Fetching user's places from DB returns a place with longitude nil.")
                return nil
            }
            
            let placeCoordinates = Coordinate(latitude: placeLatitude, longitude: placeLongitude)
            
            let place = Place(name: placeName, address: placeAddress, coordinate: placeCoordinates)
            
            userPlaces.append(place)
        }
        
        return userPlaces
    }
    
    ///Fetches user's protecteds last location
    static func fetchLastLocation(lastLocationDict: [String : Double]) -> Coordinate? {
        
        guard let latitude = lastLocationDict["latitude"] else {
            print("Error on fetching latitude from given last location dictionary.")
            return nil
        }
        
        guard let longitude = lastLocationDict["longitude"] else {
            print("Error on fetching longitude from given last location dictionary.")
            return nil
        }
        
        return Coordinate(latitude: latitude, longitude: longitude)
    }

	static func addHelpOccurrence(location: Coordinate, date: Int, completionHandler: @escaping (Error?) -> Void){

		let helpRef = ref.child("users").child(AppSettings.mainUser!.id).child("helpButtonOccurences")

		let helpDict: [String : Any] = [
			"\(date)": [
				"latitude": location.latitude,
				"longitude": location.longitude
				]
		]

		helpRef.setValue(helpDict) {
			(error, _) in

			guard (error == nil) else {
				completionHandler(error)
				return
			}

			completionHandler(nil)
		}
	}

	static func addObserverToProtectedsHelpOccurrences(completionHandler: @escaping (Coordinate?) -> Void){

		//print("hmm: \(AppSettings.mainUser!.protecteds.count)")
		for protected in AppSettings.mainUser!.protecteds {
			let protectedHelpButtonOccurrencesRef = ref.child("users/\(protected.id)/helpButtonOccurences")

			protectedHelpButtonOccurrencesRef.observe(.childAdded){
				(helpButtonOccurrencesSnap) in

				guard let helpOccurrenceDict = helpButtonOccurrencesSnap.value as? [String:Double] else {
					print("Add observer returned help occurencces nil snapshot from DB.")
					completionHandler(nil)
					return
				}

				let coordinate = Coordinate(latitude: helpOccurrenceDict["latitude"]!, longitude: helpOccurrenceDict["longitude"]!)

				completionHandler(coordinate)
			}
		}



	}
    
    ///Adds observer to all of the main user's protecteds' last location
    static func addObserverToProtectedsLocations(completionHandler: @escaping (Protected?) -> Void) {
        print("Number of protecteds: \(AppSettings.mainUser!.protecteds.count)")
        for protected in AppSettings.mainUser!.protecteds {
            let protectedLastLocationRef = ref.child("users/\(protected.id)/lastLocation")
            
            protectedLastLocationRef.observe(.value) {
                (lastLocationSnap) in
                
                //Getting protected's information dictionary
                guard let lastLocationDict = lastLocationSnap.value as? [String : Double] else {
                    print("User fetched returned last location nil snapshot from DB.")
                    completionHandler(nil)
                    return
                }
                
                let protectedLocation = fetchLastLocation(lastLocationDict: lastLocationDict)
                
                protected.lastLocation = protectedLocation
                
                completionHandler(protected)
                print("Protected [\(protected.name)] new location: \(protected.lastLocation!).")
            }
        }
    }
    
    ///Adds observer of all of the main user's protecteds' last location
    static func removeObserverFromProtectedsLocations() {
        for protected in AppSettings.mainUser!.protecteds {
            let protectedLastLocationRef = ref.child("users/\(protected.id)/lastLocation")
            
            protectedLastLocationRef.removeAllObservers()
        }
    }
    
    ///Updates the latitude and longitude values of DB's last location.
    static func updateLastLocation(_ location: Coordinate, completionHandler: @escaping (Error?) -> Void) {
        
        let lastLocationRef = ref.child("users/\(AppSettings.mainUser!.id)/lastLocation")
        
        let lastLocationDict = [
            "latitude": AppSettings.mainUser!.lastLocation?.latitude,
            "longitude": AppSettings.mainUser!.lastLocation?.longitude
        ]
        
        lastLocationRef.setValue(lastLocationDict) {
            (error, _) in
            guard (error == nil) else {
                completionHandler(error)
                return
            }
            
            completionHandler(nil)
        }
    }
    
    
    ///Fetches user's last location from DB.
    static func getLastLocation(user: User, completionHandler: @escaping (Coordinate?) -> Void) {
        
        let lastLocationRef = ref.child(user.id).child("lastLocation")
        
        lastLocationRef.observeSingleEvent(of: .value) {
            (snapshot) in
            
            let latitude = snapshot.childSnapshot(forPath: "latitude").value! as! CLLocationDegrees
            let longitude = snapshot.childSnapshot(forPath: "longitude").value! as! CLLocationDegrees
            
            let userLocation = Coordinate(latitude: latitude, longitude: longitude)
            completionHandler(userLocation)
        }
    }
    
}
