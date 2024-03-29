	//
	//  AddNewItemView.swift
	//  ShoppingList
	//
	//  Created by Jerry on 12/8/21.
	//  Copyright © 2021 Jerry. All rights reserved.
	//

import SwiftUI

/*
the AddNewItemView is opened via a sheet from either the ShoppingListView
or the PurchasedItemTabView, within a NavigationView, to do as it says: add
a new shopping item.  the strategy is simple:
	
 -- create a default set of values for a new shopping item (a StateObject)
 -- the body shows a Form in which the user can edit the default data
 -- we supply buttons in the navigation bar to create a new item from the edited data
      and to dismiss.  note: i have added .interactiveDismissDisabled() to the sheet so
	 no data will be discarded unless the user touches the Cancel button ... i.e., the
	 user cannot simply dismiss the AddNew sheet by pulling down on it.
*/
	
struct AddNewItemView: View {
	
	@Environment(\.dismiss) private var dismiss
	
		// this draftItem object contains all of the information
		// for a new Item that is needed from the User
	@StateObject private var draftItem: DraftItem

		// custom init here to set up a draft for an Item to be added, one having default values
	init(suggestedName: String? = nil, location: Location? = nil) {
		let initialValue = DraftItem(suggestedName: suggestedName, location: location)
		_draftItem = StateObject(wrappedValue: initialValue)
	}
	
		// the body is pretty short -- just call up a Form inside a NavigationStack
		// to edit the fields of data for a new Item, and
		// add Cancel and Save buttons.
	var body: some View {
		NavigationStack {
			DraftItemForm(draftItem: draftItem)
				.navigationBarTitle("Add New Item")
				.navigationBarTitleDisplayMode(.inline)
				.toolbar {
					ToolbarItem(placement: .cancellationAction, content: cancelButton)
					ToolbarItem(placement: .confirmationAction, content: saveButton)
				}
		}
	}
	
		// the cancel button just dismisses us
	func cancelButton() -> some View {
		Button("Cancel") {
			dismiss()
		}
	}
	
		// the save button saves the new item to the persistent store and dismisses ourself
	func saveButton() -> some View {
		Button("Save") {
			Item.updateAndSave(using: draftItem)
			dismiss()
		}
		.disabled(!draftItem.canBeSaved)
	}
	
}


