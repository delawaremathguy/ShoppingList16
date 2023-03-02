	//
	//  DraftLocationForm.swift
	//  ShoppingList
	//
	//  Created by Jerry on 12/10/21.
	//  Copyright © 2021 Jerry. All rights reserved.
	//

import SwiftUI

	// the DraftLocationView is a simple Form that allows the user to edit
	// the fields of a DraftLocation, which in turn stands as an editable "draft"
	// of the values either associated with an existing Location, or the default
	// values to use in creating a new Location.
struct DraftLocationForm: View {
	
		// incoming data:
		// -- a DraftLocation (editable values for a Location)
		// -- an optional action to execute if the user decides to delete
		//      a draft in the case that it represents an existing Location
	@ObservedObject var draftLocation: DraftLocation
	var dismissAction: (() -> Void)?
	
		// trigger for adding a new item at this Location
	@State private var isAddNewItemSheetPresented = false
		// trigger for confirming deletion of the associated Location (if the
		// draft represents an existing Location that is not the Unknown Location)
	@State private var isConfirmDeleteLocationPresented = false

		// definition of whether we can offer a deletion option in this view
		// (it's a real location that's not the unknown location)
	private var locationCanBeDeleted: Bool {
		guard let associatedLocation = draftLocation.associatedLocation else {
			return false
		}
		return !associatedLocation.isUnknownLocation
	}
	
	var body: some View {
		Form {
				// 1: Name (Visitation Order) and Colors.  These are shown for both an existing
				// location and a potential new Location about to be created.
			Section(header: Text("Basic Information")) {
				HStack {
					SLFormLabelText(labelText: "Name: ")
					TextField("Location name", text: $draftLocation.locationName)
				}
				ColorPicker("Location Color", selection: $draftLocation.color)
			} // end of Section 1
			
				// Section 2: Delete button, if the data is associated with an existing Location
			if locationCanBeDeleted {
				Section(header: Text("Location Management")) {
					Button("Delete This Location")  {
						isConfirmDeleteLocationPresented = true // trigger confirmation dialog
					}
					.foregroundColor(Color.red)
					.hCentered()
					.confirmationDialog("Delete \'\(draftLocation.locationName)\'?",
															isPresented: $isConfirmDeleteLocationPresented,
															titleVisibility: .visible) {
						Button("Yes", role: .destructive) {
							if let location = draftLocation.associatedLocation {
								Location.delete(location)
								dismissAction?()
							}
						}
					} message: {
						Text("Are you sure you want to delete the Location named \'\(draftLocation.locationName)\'? All items at this location will be moved to the Unknown Location.  This action cannot be undone.")
					}

				}
			} // end of Section 2
			
				// Section 3: Items assigned to this Location, if we are editing a Location
			if let associatedLocation = draftLocation.associatedLocation {
				Section(header: ItemsListHeader()) {
					SimpleItemsList(location: associatedLocation)
				}
			}
			
		} // end of Form
		.sheet(isPresented: $isAddNewItemSheetPresented) {
			AddNewItemView(location: draftLocation.associatedLocation)
		}

	} // end of var body: some View
	
	var locationItemCount: Int {
		if let location = draftLocation.associatedLocation {
			return location.items.count
		}
		return 0
	}
		
	func ItemsListHeader() -> some View {
		HStack {
			Text("At this Location: \(locationItemCount) items")
			Spacer()
			Button {
				isAddNewItemSheetPresented = true
			} label: {
				Image(systemName: "plus")
			}
		}
	}
	
}

// this is a quick way to see a list of items associated
// with a given location that we're editing.
struct SimpleItemsList: View {
	
	@ObservedObject var location: Location
	
	var body: some View {
		ForEach(location.items) { item in
			NavigationLink {
				ModifyExistingItemView(item: item)
			} label: {
				HStack {
					Text(item.name)
					if item.onList {
						Spacer()
						Image(systemName: "cart")
							.foregroundColor(.green)
					}
				}
				.contextMenu {
					ItemContextMenu(item: item)
				}
			}
		}
	}
	
	@ViewBuilder
	func ItemContextMenu(item: Item) -> some View {
		Button(action: { item.toggleOnListStatus() }) {
			Text(item.onList ? "Move to Purchased" : "Move to ShoppingList")
			Image(systemName: item.onList ? "purchased" : "cart")
		}
	}

}
