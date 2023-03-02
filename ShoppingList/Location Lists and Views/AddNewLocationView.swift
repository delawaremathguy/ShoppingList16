//
//  AddNewLocationView.swift
//  ShoppingList
//
//  Created by Jerry on 12/10/21.
//  Copyright © 2021 Jerry. All rights reserved.
//

import SwiftUI

// see AddNewItemView.swift for similar comments and explanation of how this works
struct AddNewLocationView: View {
	
	@Environment(\.dismiss) var dismiss
	@EnvironmentObject private var persistentStore: PersistentStore
	
		// a draftLocation is initialized here, holding default values for
		// a new Location.
	@StateObject private var draftLocation = DraftLocation()
	
	var body: some View {
		NavigationStack {
			DraftLocationForm(draftLocation: draftLocation)
				.navigationBarTitle("Add New Location")
				.navigationBarTitleDisplayMode(.inline)
				//.navigationBarBackButtonHidden(true)
				.toolbar {
					ToolbarItem(placement: .cancellationAction, content: cancelButton)
					ToolbarItem(placement: .confirmationAction) { saveButton().disabled(!draftLocation.canBeSaved) }
				}
				.onDisappear { persistentStore.save() }
		}
	}
	
		// the cancel button
	func cancelButton() -> some View {
		Button {
			dismiss()
		} label: {
			Text("Cancel")
		}
	}
	
		// the save button
	func saveButton() -> some View {
		Button {
			dismiss()
			Location.updateAndSave(using: draftLocation)
		} label: {
			Text("Save")
		}
	}
	
}

