	//
	//  ModifyExistingItemView.swift
	//  ShoppingList
	//
	//  Created by Jerry on 12/8/21.
	//  Copyright © 2021 Jerry. All rights reserved.
	//

import SwiftUI

	// the ModifyExistingItemView is opened via a navigation link from the ShoppingListView
	// or the PurchasedItemTabView to do as it says: edit an existing shopping item.
	//
	// this will be an "almost live edit," in the sense that when the user touches the <Back button,
	// we update the values of the Item with the edited values.  however, because we have to intercept
	// when the user taps the Back button, we'll use our own Back button.  (we don't really need
	// this ... we could handle the update in an .onDisappear modifier as we do over in
	// ModifyExistingLocationView.  you can decide!  the downside of handling this in .onDisappear is
	// that we'll return to the previous screen on the navigation stack, see the old presentation, and
	// then see it update for the edit.  also, we never really know when .onDisappear will be called --
	// or even if it could be called more than once).
	//
	// the strategy is simple:
	//
	// -- create an editable representation of values for the item (a StateObject)
	// -- the body shows a Form in which the user can edit the values
	// -- and update the Item's values from the editable representation when finished.
	//
struct ModifyExistingItemView: View {
	
	@Environment(\.dismiss) private var dismiss: DismissAction
	
		// an editable copy of the Item's data -- a "draft," if you will
	@StateObject private var draftItem: DraftItem

		// custom init here to set up the draftItem object
	init(item: Item) {
		_draftItem = StateObject(wrappedValue: DraftItem(item: item))
	}
		
	var body: some View {
			// the dismissAction function provides the DraftItemView with a way to dismiss
			// us, which is necessary should the item be deleted.  we could write this using
			// a trailing closure, but it's nice to know we can just pass the function's name
			// which is not "dismiss," but for syntax reasons with type DismissAction, we
			// must use its callAsFunction property.
		DraftItemForm(draftItem: draftItem, dismissAction: dismiss.callAsFunction)
			.navigationBarTitle("Modify Item")
			.navigationBarTitleDisplayMode(.inline)
			.navigationBarBackButtonHidden(true)
			.toolbar {
				ToolbarItem(placement: .navigationBarLeading, content: customBackButton)
			}
		
	} // end of var body: some View
	
		// i have never liked the idea of using a custom Back button ... it does not
		// really look all that good.  it has to be localized, but should actually point
		// in the right direction for all languages because of the use of the
		// SFSymbol "chevron.backward."
		// however, i do not know of a way to detect when the user taps the
		// system-generated Back button.  also see discussion above.
	func customBackButton() -> some View {
		Button {
				// we need to ask if the draft "still" represents an existing Item.  it
				// certainly did when we opened this View, but if we hit the delete button
				// and confirmed the deletion, then this draft no longer represents a
				// real Item and we would not want to put the item back into Core Data.
			if draftItem.associatedItem != nil {
				Item.updateAndSave(using: draftItem)
			}
			dismiss()
		} label: {
			HStack(spacing: 5) {
				Image(systemName: "chevron.backward")
				Text("Back")
			}
		}
	}
	
}

