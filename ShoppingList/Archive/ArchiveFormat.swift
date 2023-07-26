//
//  ArchiveFormat.swift
//  ShoppingList
//
//  Created by Jerry on 7/25/23.
//  Copyright © 2023 Jerry. All rights reserved.
//

import Foundation

	// a simple struct representation of an Item that we use to
	// save to/restore from disk.
struct ItemRepresentation: Codable {
	var id: UUID
	var name: String
	var onList: Bool
	var isAvailable: Bool
	var quantity: Int
	
	init(from item: Item) {
		id = item.id!
		name = item.name
		onList = item.onList
		isAvailable = item.isAvailable
		quantity = item.quantity
	}
}

	// a simple struct representation of a Location that we use to
	// save to/restore from disk.  note that this includes an array
	// representing associated Items.
struct LocationRepresentation: Codable {
	var id: UUID
	var name: String
	var visitationOrder: Int
	var red: Double
	var green: Double
	var blue: Double
	var opacity: Double
	var items: [ItemRepresentation]
	
	init(from location: Location) {
		id = location.id!
		name = location.name
		visitationOrder = location.visitationOrder
		red = location.red_
		green = location.green_
		blue = location.blue_
		opacity = location.opacity_
		items = []
		for item in location.items {
			items.append(ItemRepresentation(from: item))
		}
	}
}
