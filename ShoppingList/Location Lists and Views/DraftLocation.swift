	//
	//  DraftLocation.swift
	//  ShoppingList
	//
	//  Created by Jerry on 8/1/20.
	//  Copyright © 2020 Jerry. All rights reserved.
	//

import Foundation
import SwiftUI

	// **** see the more lengthy discussion over in DraftItem.swift as to why we are
	// using a class that's an ObservableObject.

class DraftLocation: ObservableObject {
		// the id of the Location, if any, associated with this data collection
		// (nil if data for a new item that does not yet exist)
	var id: UUID? = nil
		// all of the values here provide suitable defaults for a new Location
	@Published var locationName: String = ""
	@Published var visitationOrder: Int = 50
	@Published var color: Color = .green
	
		// this copies all the editable data from an incoming Location
	init(location: Location? = nil) {
		if let location {
			id = location.id
			locationName = location.name
			visitationOrder = Int(location.visitationOrder)
			color = location.color
		}
	}
	
		// to do a save/commit of an Item, it must have a non-empty name
	var canBeSaved: Bool { locationName.count > 0 }
	
		// the associated location in Core Data, if any
	var associatedLocation: Location? {
		if let id {
			return Location.object(withID: id)
		}
		return nil
	}
}

