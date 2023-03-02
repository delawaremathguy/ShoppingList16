//
//  Location+Extensions.swift
//  ShoppingList
//
//  Created by Jerry on 5/6/20.
//  Copyright © 2020 Jerry. All rights reserved.
//

import CoreData
import SwiftUI	// because we reference Color

// constants
let kUnknownLocationName = "Unknown Location"
let kUnknownLocationVisitationOrder: Int32 = INT32_MAX

extension Location: Comparable {
	
	// add Comparable conformance: sort by visitation order
	public static func < (lhs: Location, rhs: Location) -> Bool {
		lhs.visitationOrder_ < rhs.visitationOrder_
	}
	
		// MARK: - Fronting Properties

	// ** please see the associated discussion over in Item+Extensions.swift **
	
	// name: fronts Core Data attribute name_ that is optional
	// if you change a location's name, its associated items may want to
	// know that some of their computed locationName properties have been invalidated
	var name: String {
		get { name_ ?? "Unknown Name" }
		set {
			name_ = newValue
			items.forEach({ $0.objectWillChange.send() })
		}
	}
	
	// visitationOrder: fronts Core Data attribute visitationOrder_ that is Int32
	var visitationOrder: Int {
		get { Int(visitationOrder_) }
		set { visitationOrder_ = Int32(newValue) }
	}
	
		// MARK: - Computed Properties

	// items: fronts Core Data attribute items_ that is an NSSet, and turns it into
	// a Swift array
	var items: [Item] {
		if let items = items_ as? Set<Item> {
			return items.sorted(by: \.name)
		}
		return []
	}
	
		// itemCount: computed property from Core Data items
	var itemCount: Int { items_?.count ?? 0 }
	
		// simplified test of "is the unknown location"
	var isUnknownLocation: Bool { visitationOrder_ == kUnknownLocationVisitationOrder }
		
	var color: Color {
		get {
			Color(red: red_, green: green_, blue: blue_, opacity: opacity_)
		}
		set {
			if let components = newValue.cgColor?.components {
				items.forEach({ $0.objectWillChange.send() })
				red_ = components[0]
				green_ = components[1]
				blue_ = components[2]
				opacity_ = components[3]
			}
		}
	}
	
	var hasItemsOnShoppingList: Bool {
		items.count(where: { $0.onList }) > 0
	}

	// MARK: - Useful Fetch Request
	
	// a fetch request we can use in views to get all locations, sorted in visitation order.
	// by default, you get all locations; setting onList = true returns only locations that
	// have at least one of its shopping items currently on the shopping list
	class func allLocationsFR() -> NSFetchRequest<Location> {
		let request: NSFetchRequest<Location> = Location.fetchRequest()
		request.sortDescriptors = [NSSortDescriptor(key: "visitationOrder_", ascending: true)]
		return request
	}

	// MARK: - Class Functions
	
		// this class variable must be set up when the app begins so that as a class,
		// we can find the persistent store and its context.
		// it has the type PersistentStore! which means that when it comes time to
		// actually use it, it will have been set and will be non-nil.
	static var persistentStore: PersistentStore!

	class func count() -> Int {
		return count(context: persistentStore.context)
	}

	// return a list of all user-defined locations, excluding the unknown location
	class func allUserLocations() -> [Location] {
		var allLocations = allObjects(context: persistentStore.context) as! [Location]
		allLocations.removeAll(where: { $0.isUnknownLocation })
		return allLocations
	}

	// creates a new Location having an id, but then it's the user's responsibility
	// to fill in the field values (and eventually save)
	class func addNewLocation() -> Location {
		let newLocation = Location(context: persistentStore.context)
		newLocation.id = UUID()
		return newLocation
	}
	
	// parameters for the Unknown Location.  this is called only if we try to fetch the
	// unknown location and it is not present.
	private class func createUnknownLocation() -> Location {
		let unknownLocation = addNewLocation()
		unknownLocation.name_ = kUnknownLocationName
		unknownLocation.red_ = 0.5
		unknownLocation.green_ = 0.5
		unknownLocation.blue_ = 0.5
		unknownLocation.opacity_ = 0.5
		unknownLocation.visitationOrder_ = kUnknownLocationVisitationOrder
		return unknownLocation
	}

	class func unknownLocation() -> Location {
		// we only keep one "UnknownLocation" in the data store.  you can find it because its
		// visitationOrder is the largest 32-bit integer. to make the app work, however, we need this
		// default location to exist!
		//
		// so if we ever need to get the unknown location from the database, we will fetch it;
		// and if it's not there, we will create it then.
		let fetchRequest: NSFetchRequest<Location> = Location.fetchRequest()
		fetchRequest.predicate = NSPredicate(format: "visitationOrder_ == %d", kUnknownLocationVisitationOrder)
		do {
			let locations = try persistentStore.context.fetch(fetchRequest)
			if locations.count >= 1 { // there should be no more than one
				return locations[0]
			} else {
				return createUnknownLocation()
			}
		} catch let error as NSError {
			fatalError("Error fetching unknown location: \(error.localizedDescription), \(error.userInfo)")
		}
	}
	
	class func delete(_ location: Location) {
		// you cannot delete the unknownLocation
		let theUnknownLocation = Location.unknownLocation()
		guard location != theUnknownLocation else { return }

		// get a list of all items for this location so we can work with them
		let itemsAtThisLocation = location.items
		
		// reset location associated with each of these to the unknownLocation
		// (which in turn, removes the current association with location). additionally,
		// this could affect each item's computed properties
		itemsAtThisLocation.forEach({ $0.location = theUnknownLocation })
		
		// now finish the deletion and save
		persistentStore.context.delete(location)
		persistentStore.save()
	}
	
	class func updateAndSave(using draftLocation: DraftLocation) {
			// if the incoming location data represents an existing Location, this is just
			// a straight update.  otherwise, we must create the new Location here and add it
			// before updating it with the new values
		if let location = draftLocation.associatedLocation {
			location.updateValues(from: draftLocation)
		} else {
			let newLocation = Location(context: persistentStore.context)
			newLocation.id = UUID()
				// this places the new Location at the start of the list,
				// so you can see it right away upon return to the LocationsView
			newLocation.visitationOrder_ = -1
			newLocation.updateValues(from: draftLocation)
		}
		persistentStore.save()
	}
	
	class func object(withID id: UUID) -> Location? {
		return object(id: id, context: persistentStore.context) as Location?
	}
	
	// MARK: - Object Methods
	
	func updateValues(from draftLocation: DraftLocation) {
		
			// before we update: items associated with this location may want to know about
			// (some of) these changes.  reason: items rely on knowing some computed
			// properties such as color, locationName, and visitationOrder.
			// this makes sure that anyone who is observing an Item at this Location
			// as an @ObservedObject will know something's about to change.:
		items.forEach({ $0.objectWillChange.send() })

		// we make changes directly in Core Data
		name_ = draftLocation.locationName
		// visitationOrder no longer editable in Draft code
		//visitationOrder_ = Int32(draftLocation.visitationOrder)
		if let components = draftLocation.color.cgColor?.components {
			red_ = Double(components[0])
			green_ = Double(components[1])
			blue_ = Double(components[2])
			opacity_ = Double(components[3])
		} else {
			red_ = 0.0
			green_ = 1.0
			blue_ = 0.0
			opacity_ = 0.5
		}
		
	}
	
} // end of extension Location
