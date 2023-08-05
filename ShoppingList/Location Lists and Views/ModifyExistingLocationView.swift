	//
	//  ModifyExistingLocationView.swift
	//  ShoppingList
	//
	//  Created by Jerry on 12/11/21.
	//  Copyright © 2021 Jerry. All rights reserved.
	//

import SwiftUI

struct ModifyExistingLocationView: View {
	
	@Environment(\.dismiss) var dismiss: DismissAction
	@EnvironmentObject private var persistentStore: PersistentStore

		// draftLocation will be initialized from the incoming DraftLocation
	@StateObject private var draftLocation: DraftLocation
	
	init(location: Location) {
		_draftLocation = StateObject(wrappedValue: DraftLocation(location: location))
	}
	
	var body: some View {
			// the trailing closure provides the DraftLocationView with what to do after the user has
			// chosen to delete the Location, namely to dismiss this view,"
			// so we "go back" up the navigation stack
		DraftLocationForm(draftLocation: draftLocation) { 
			dismiss()
		}
			.navigationBarTitle("Modify Location")
			.navigationBarTitleDisplayMode(.inline)
			.navigationBarBackButtonHidden(true)
			.toolbar {
				ToolbarItem(placement: .navigationBarLeading, content: customBackButton)
			}
	}
	
	func customBackButton() -> some View {
			//...  see comments in ModifyExistingItemView about using
			// our own back button.
		Button {
			if draftLocation.associatedLocation != nil {
				Location.updateAndSave(using: draftLocation)
			}
			persistentStore.save()
			dismiss()
		} label: {
			HStack(spacing: 5) {
				Image(systemName: "chevron.backward")
				Text("Back")
			}
		}
	}

	
}

