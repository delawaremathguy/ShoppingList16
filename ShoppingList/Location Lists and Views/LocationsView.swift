//
//  LocationsView.swift
//  ShoppingList
//
//  Created by Jerry on 5/6/20.
//  Copyright © 2020 Jerry. All rights reserved.
//

import SwiftUI

struct LocationsView: View {
	
	@EnvironmentObject private var persistentStore: PersistentStore

		// MARK: - @FetchRequest

		// this is the @FetchRequest that ties this view to CoreData Locations
	@FetchRequest(fetchRequest: Location.allLocationsFR())
	private var locations: FetchedResults<Location>
	
		// MARK: - @State and @StateObject Properties

		// state to trigger a sheet to appear to add a new location
	@State private var isAddNewLocationSheetPresented = false
	
		// NOTE for SL16: this view no longer supports deletion of a Location
		//by swiping in the List.  deletion should be rare ... but is best handled
		// in the context for the ModifyExistingLocation detail view where
		// you can see all the items at the Location ... perhaps you want to
		// move those to other locations before deleting (you don't have to
		// do this, since deletion will just move all the items a this Location
		// into the Unknown Location).
	
		// MARK: - BODY

	var body: some View {
		VStack(spacing: 0) {
			
			Rectangle()
				.frame(height: 1)
			
			List {
				Section(header: Text("Locations Listed: \(locations.count)")) {
					ForEach(locations) { location in
						NavigationLink(value: location) {
							LocationRowView(location: location)
						} // end of NavigationLink
					} // end of ForEach
					.onMove(perform: moveLocations)
				} // end of Section
			} // end of List
			.listStyle(.insetGrouped)
			
			Divider() // keeps list from running through tab bar (!)
		} // end of VStack
		.navigationBarTitle("Locations")
		.navigationDestination(for: Location.self) { location in
			ModifyExistingLocationView(location: location)
		}
		.toolbar {
			ToolbarItem(placement: .navigationBarTrailing, content: addNewButton)
			ToolbarItem(placement: .navigationBarLeading) { EditButton() }
		}
		.sheet(isPresented: $isAddNewLocationSheetPresented) {
			AddNewLocationView()
		}
		.onAppear { handleOnAppear() }
		
	} // end of var body: some View
	
		// this is new to SL16: allowing you to reorder Locations by dragging.
		// we make a copy of the current ordering of the locations array (some
		// type coercion in necessary) and then rewrite all the visitationOrders
		// after the move (except for the unknown location).
	func moveLocations(at offsets: IndexSet, destination: Int) {
		var oldLocations = locations.compactMap({ $0 }) as! [Location]
		oldLocations.move(fromOffsets: offsets, toOffset: destination)
		var position = 0
		for location in oldLocations where !location.isUnknownLocation {
			location.visitationOrder = position
			position += 1
		}
	}
	
	func handleOnAppear() {
			// because the unknown location is created lazily, this will
			// make sure that we'll not be left with an empty screen.
			// however, this could introduce a subtle problem: if you
			// are using NSPersistentCloudKitContainer, you might
			// have a "late delivery" from the cloud of an unknown
			// location from another device (if this is the first time you're
			// using the app) ... but i will ignore that here and leave any
			// fixes to the Location class for later resolution.
		if locations.count == 0 {
			let _ = Location.unknownLocation()
		}
	}
	
	// defines the usual "+" button to add a Location
	func addNewButton() -> some View {
		Button {
			isAddNewLocationSheetPresented = true
		} label: {
			Image(systemName: "plus")
		}
	}
	
}
