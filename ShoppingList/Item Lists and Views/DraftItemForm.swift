	//
	//  DraftItemForm.swift
	//  ShoppingList
	//
	//  Created by Jerry on 12/8/21.
	//  Copyright © 2021 Jerry. All rights reserved.
	//

import SwiftUI

	// the DraftItemForm is a simple Form that allows the user to edit
	// the value of a DraftItem, which can represent either default values
	// for a new Item to create, or an existing Item.  additionally, for
	// an existing Item, we are provided a dismissAction to perform
	// after deleting the Item, which allows the parent view to dismiss
	// itself.
struct DraftItemForm: View {
	
		// incoming data represents either
		// -- default data for an existing Item that we wish to create
		//
		// -- or data for an existing Item that we wish to modify, plus a function
		//      to dismiss ourself should the user confirm they want to delete
		//      this Item ... because we cannot leave this view on screen after
		//      the Item is deleted.

	@ObservedObject var draftItem: DraftItem
	var dismissAction: (() -> Void)?

		// we need all locations so we can populate the Picker.
	@FetchRequest(fetchRequest: Location.allLocationsFR())
	private var locations: FetchedResults<Location>

		// this used to implement confirmation alert process for deleting an Item.
	@State private var alertIsPresented = false
	
		// MARK: - Computed Variables
	
		// a simplification to tell whether this draft represents an existing Item
	private var itemExists: Bool {
		draftItem.associatedItem != nil
	}

	// MARK: - BODY
	
	var body: some View {
		Form {
				// Section 1. Basic Information Fields
			Section(header: Text("Basic Information")) {
				
				HStack(alignment: .firstTextBaseline) {
					SLFormLabelText(labelText: "Name: ")
					TextField("Item name", text: $draftItem.name)
				}
				
				Stepper(value: $draftItem.quantity, in: 1...10) {
					HStack {
						SLFormLabelText(labelText: "Quantity: ")
						Text("\(draftItem.quantity)")
					}
				}
				
				Picker(selection: $draftItem.location, label: SLFormLabelText(labelText: "Location: ")) {
					ForEach(locations) { location in
						Text(location.name).tag(location)
					}
				}
				
				HStack(alignment: .firstTextBaseline) {
					Toggle(isOn: $draftItem.onList) {
						SLFormLabelText(labelText: "On Shopping List: ")
					}
				}
				
				HStack(alignment: .firstTextBaseline) {
					Toggle(isOn: $draftItem.isAvailable) {
						SLFormLabelText(labelText: "Is Available: ")
					}
				}
				
				if itemExists {
					HStack(alignment: .firstTextBaseline) {
						SLFormLabelText(labelText: "Last Purchased: ")
						Text("\(draftItem.dateText)")
					}
				}
				
			} // end of Section 1
			
				// Section 2. Item Management (Delete), if present
			if itemExists {
				Section(header: Text("Shopping Item Management")) {
					Button("Delete This Shopping Item", role: .destructive) {
						alertIsPresented = true
					}
					//.foregroundColor(Color.red)
					.hCentered()
					.confirmationDialog("Delete \'\(draftItem.name)\'?",
															isPresented: $alertIsPresented,
															titleVisibility: .visible) {
						Button("Yes", role: .destructive) {
							if let item = draftItem.associatedItem {
								Item.delete(item)
								dismissAction?()
							}
						}
					} message: {
						Text("Are you sure you want to delete the Item named \'\(draftItem.name)\'? This action cannot be undone.")
					}


				} // end of Section 2
			} // end of if ...
		} // end of Form
	} // end of var body: some View

}
