//
//  DraftItem.swift
//  ShoppingList
//
//  Created by Jerry on 6/28/20.
//  Copyright © 2020 Jerry. All rights reserved.
//

import Foundation

// this gives me a way to collect all the data for an Item that i might want to edit
// (or even just display).  it defaults to having values appropriate for a new item upon
// creation, and can be initialized from an existing Item.  this is something
// i can then hand off to an edit view.  at some point, that edit view will
// want to update an Item with this data, so see the class function
// Item.update(using draftItem: DraftItem)

// ADDED 2 FEB 2022: this is now a class object that conforms to ObservableObject, with
// five of its properties marked @Published (these are exactly the properties that can be edited
// in the DraftItemView).  both the AddNewItemView and the ModifyExistingDataView
// will create one of these as a @StateObject.

class DraftItem: ObservableObject {
		
		// the id of the Item, if any, associated with this data collection
		// (nil if data for a new item that does not yet exist)
	var id: UUID? = nil
		// all of the values here provide suitable defaults for a new item
	@Published var name: String = ""
	@Published var quantity: Int = 1
	@Published var location = Location.unknownLocation()
	@Published var onList: Bool = true
	@Published var isAvailable = true
	var dateText = "(Never)" // for display only, not actually editable
	
		// this copies all the editable data from an incoming Item.
	init(item: Item) {
		id = item.id
		name = item.name
		quantity = Int(item.quantity)
		location = item.location
		onList = item.onList
		isAvailable = item.isAvailable
		if let date = item.dateLastPurchased {
			dateText = date.formatted(date: .long, time: .omitted)
		}
	}
	
	init(suggestedName: String? = nil, location: Location? = nil) {
		if let suggestedName, suggestedName.count > 0 {
			name = suggestedName
		}
		if let location = location {
			self.location = location
		} else {
			self.location = Location.unknownLocation()
		}
	}
	
	// to do a save/update of an Item, it must have a non-empty name
	var canBeSaved: Bool { !name.isEmpty }

	// the associated Item in Core Data, if any
	var associatedItem: Item? {
		if let id {
			return Item.object(withID: id)
		}
		return nil
	}

}
