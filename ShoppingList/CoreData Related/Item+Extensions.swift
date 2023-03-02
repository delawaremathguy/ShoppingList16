//
//  Item+Extensions.swift
//  ShoppingList
//
//  Created by Jerry on 4/23/20.
//  Copyright © 2020 Jerry. All rights reserved.
//

import CoreData
import Foundation
import SwiftUI	// because we reference Color

extension Item {
	
/* Discussion

 (1) Fronting of Core Data Attributes
 
 Notice that (almost) all of the Core Data attributes on an Item in the
 CD model appear with an underscore (_) at the end of their name. i then
 choose to "front" each of them in this file, as well as perhaps provide
 other computed properties of interest.
 
 I do this so it's always clear to me whether i am working directly with
 an Item's Core Data attribute, or working with a massaged version of it
 (e.g., nil-coalesced) ... this helps smooth out the awkwardness of
 nil-coalescing (we don't want SwiftUI views continually writing
 
	 item.name_ ?? "Unknown"
 
 all over the place); and in the case of an item's quantity, "fronting"
 its quantity_ attribute smooths the transition between Int32 to Int.
 indeed, in SwiftUI views, these Core Data objects should appear just as
 objects, without any knowledge that they come from Core Data.  this
 will make the code more readable at the consumer's end.
 
 in fact, my general theory of the case is that no one outside of this
 class (and its Core Data based brethren, found in
 Location+Extensions.swift and PersistentStore.swift) should really be
 touching these attributes directly -- and certainly no SwiftUI views
 should ever touch these attributes directly.
 
 we do allow SwiftUI views to write to these fronted properties; and
 because we front them, we can appropriately act on the Core Data side.
 for example if we move an item off the shopping list, we can take the
 opportunity then to timestamp the item as purchased.
 
 (2) Computed Properties Based on Relationships
 
 the situation for SwiftUI becomes more complicated when one CD object
 has a computed property based on something that's not a direct attribute
 of the object.  examples:
 
 -- an Item has a `locationName` computed property = the name of its
 associated Location
 
 -- a Location has an `itemCount` computed property = the count of
 its associated Items.
 
 however, if a view holds on to (is a subscriber of) an Item as an
 @ObservedObject, and if we change, say, the name of its associated
 Location, the view will not see this change because it is subscribed to
 changes on the Item (not the Location).
 
 assuming the view displays the name of the associated location using the
 item's locationName, we must have the location tell all of its items
 that the locationName computed property is now invalid and some views
 may need to be updated, in order to keep such a view in-sync.  thus the
 location must execute
 
	 items.forEach({ $0.objectWillChange.send() })
 
 the same holds true for a view that holds on to (is a subscriber of) a
 Location as an @ObservedObject.  if that view displays the number of
 items for the location, based on the computed property `itemCount`, then
 when an Item is edited to change its location, the item must tell both
 its previous and new locations about the change by executing
 objectWillChange.send() for those locations:
 
 (see the computed var location: Location setter below)
 
 as a result, you may see some code below (and also in
 Location+Extensions.swift) where, when a SwiftUI view writes to one of
 the fronted properties of the Item, we also execute
 location_?.objectWillChange.send().
 
 (3) @ObservedObject References to Items
 
 only the SelectableItemRowView has an @ObservedObject reference to an
 Item, and only the SimpleItemsList has an @ObservedObject reference to a
 Location.
 
 in early development (think 2020), one of these views (or whatever the
 view was during development) had a serious problem:
 
 if a SwiftUI view holds an Item as an @ObservedObject and that
 object is deleted while the view is still alive, the view is then
 holding on to a zombie object. (Core Data does not immediately save
 out its data to disk and update its in-memory object graph for a
 deletion.)
 
 Apple's phrase for what happens with such a zombie object is that
 "The object’s attributes, including scalars, nullable, and mandatory
 attributes are all set to nil or 0." thus, depending on how the
 view's code accesses that object, your program may crash.
 
 when you front all your Core Data attributes as i do below, especially
 if you nil-coalesce optional values, the crashing problem above
 disappears ... but it's really still there. the code just doesn't crash.
 
 anyway, it's something to think about.  in this app, if you show a list
 of items on the shopping list, navigate to an item's detail view, and
 press "Delete this Item," the row view for the item in the shopping list
 is still alive and has a dead reference to the item.  SwiftUI may/will
 try to use that.   if you had a reference to that item, you should
 expect that every attribute will be 0 (e.g., nil for a Date, 0 for an
 Integer 32, and nil for every optional attribute).

*/
	
		// MARK: - Fronting Properties
	
		// the name.  this fronts a Core Data optional attribute
	var name: String {
		get { name_ ?? "No Name" }
		set { name_ = newValue }
	}
	
		// whether the item is available.  this fronts a Core Data boolean
	var isAvailable: Bool {
		get { isAvailable_ }
		set { isAvailable_ = newValue }
	}
	
		// whether the item is on the list.  this fronts a Core Data boolean,
		// but when changed from true to false, it signals a purchase, so update
		// the lastDatePurchased
	var onList: Bool {
		get { onList_ }
		set {
				// we need to let the associated location know about this change ... for example,
				// the ShoppingListView and the DraftLocationView depend on knowing
				// whether an item is on- or off-list and must be updated
			location.objectWillChange.send()
			onList_ = newValue
			if !onList_ { // just moved off list, so record date
				dateLastPurchased_ = Date()
			}
		}
	}
	
		// quantity of the item.   this fronts a Core Data optional attribute
		// but we need to do an Int <--> Int32 conversion
	var quantity: Int {
		get { Int(quantity_) }
		set { quantity_ = Int32(newValue) }
	}
	
		// an item's associated location.  this fronts a Core Data optional attribute.
		// if you change an item's location, the old and the new Location may want to
		// know that some of their computed properties could be invalidated.
		//
		// [new] just in case: if the location is not set for an item, this will self-correct
		// and set it to the unknown location.  this should not really happen on device, but
		// i have found that when you load the app onto a second device on your
		// iCloud account, data will start arriving from the cloud as an initial download
		// and ... it could be the case that we try to access an Item that's been downloaded
		// before its associated Location has been brought down to the device.
	var location: Location {
		get {
			if let location = location_ {
				return location
			}
			location_ = Location.unknownLocation()
			return location_!
		}
		set {
			location_?.objectWillChange.send()
			location_ = newValue
			location_?.objectWillChange.send()
		}
	}
		
		// MARK: - Computed Properties
	
		// the date last purchased.  this fronts a Core Data optional attribute
		// when no date is available, we'll set the date to ReferenceDate, for purposes of
		// always having one for comparisons ("today" versus "earlier")
	var dateLastPurchased: Date {
		dateLastPurchased_ ?? Date(timeIntervalSinceReferenceDate: 1)
	}
	
	var hasBeenPurchased: Bool { dateLastPurchased_ != nil }
	
	// the name of its associated location
	var locationName: String { location_?.name_ ?? "Not Available" }
	
	// the color of its association location
	var color: Color {
		location_?.color ?? Color(uiColor: UIColor(displayP3Red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5))
	}
			
	// MARK: - Fetch Request Definition
	
		// returns a Fetch Request (FR) that fetches Items that are either
		// ON the shopping list (used by the ShoppingListView) or OFF the
		// shopping list (used by the PurchasedItemsView).
		// results are sorted by item name.
	class func allItemsFR(onList: Bool) -> NSFetchRequest<Item> {
		let request: NSFetchRequest<Item> = Item.fetchRequest()
		request.predicate = NSPredicate(format: "onList_ == %d", onList)
		request.sortDescriptors = [NSSortDescriptor(key: "name_", ascending: true)]
		return request
	}
	
	// MARK: - Class variable and functions for CRUD operations
	
		// this class variable must be set up when the app begins so that as a class,
		// we can find the persistent store and its context.
		// it has the type PersistentStore! which means that when it comes time to
		// actually use it, it will have been set and be non-nil.
	static var persistentStore: PersistentStore!
	
	class func count() -> Int {
		return count(context: persistentStore.context)
	}

	class func allItems() -> [Item] {
		return allObjects(context: persistentStore.context) as! [Item]
	}
	
	class func object(withID id: UUID) -> Item? {
		return object(id: id, context: persistentStore.context) as Item?
	}
	
	// addNewItem is the user-facing add of a new entity.  since these are Identifiable objects, this
	// makes sure we give the entity a unique id plus default data, then hand it back so the user
	// can fill in what they want
	class func addNewItem() -> Item {
		let context = persistentStore.context
		let newItem = Item(context: context)
		newItem.name_ = ""
		newItem.quantity_ = 1
		newItem.isAvailable_ = true
		newItem.onList_ = true
		newItem.id = UUID()
		newItem.location_ = Location.unknownLocation()
		return newItem
	}
	
	// updates data for an Item that the user has directed from an Add or Modify View.
	// if the incoming data is not associated with an item, we need to create it first
	class func updateAndSave(using draftItem: DraftItem) {
		// if we can find an Item with the given id, use it, else create one
		if let id = draftItem.id,
			let item = Item.object(id: id, context: persistentStore.context) {
			item.updateValues(from: draftItem)
		} else {
			let newItem = Item.addNewItem()
			newItem.updateValues(from: draftItem)
		}
		persistentStore.save()
	}

	class func delete(_ item: Item) {
		// remove the reference to this item from its associated location
		// that location will need to know (for SwiftUI display) that some
		// computed properties (e.g., its itemCount) may change with this deletion.
		item.location_?.objectWillChange.send()
		item.location_ = nil
		
		// now delete and save
		persistentStore.context.delete(item)
		persistentStore.save()
	}
	
	class func moveAllItemsOffShoppingList() {
		for item in allItems().filter({ $0.onList }) {
			item.onList = false
		}
	}
	
	// MARK: - Object Methods
	
	func toggleAvailableStatus() {
		isAvailable.toggle()
		Self.persistentStore.save()
	}

	func toggleOnListStatus() {
		onList = !onList
		Self.persistentStore.save()
	}

	func markAvailable() {
		isAvailable_ = true
		Self.persistentStore.save()
	}
	
	private func updateValues(from draftItem: DraftItem) {
		name_ = draftItem.name
		quantity_ = Int32(draftItem.quantity)
		onList_ = draftItem.onList
		isAvailable_ = draftItem.isAvailable
		location = draftItem.location
	}
	
}

