	//
	//  ShoppingListView.swift
	//  ShoppingList
	//
	//  Created by Jerry on 4/22/20.
	//  Copyright © 2020 Jerry. All rights reserved.
	//

import MessageUI
import SwiftUI

struct ShoppingListView: View {
	
	@EnvironmentObject private var persistentStore: PersistentStore
	
		// MARK: - @FetchRequests
	
		// this is the @FetchRequest that ties this view to CoreData Items
		// on the shopping list.  note that i use an Item class function
		// to provide the details of the underlying fetch request:  this hides
		// all the details about key paths and sort descriptors in the Item
		// class, keeping those details out of this View, with the result being
		// that we do not have to import CoreData.
	@FetchRequest(fetchRequest: Item.allItemsFR(onList: true))
	private var items: FetchedResults<Item>
	
		// this is the @FetchRequest that ties this view to CoreData Locations
		// and is new to SL16. you might think this unusual in a view that primarily
		// shows a list of Items; but in fact, the presentation of the list is being sectioned
		// according to Location visitation order.  so when a visitationOrder is changed,
		// this view needs to be redrawn.
		// see the discussion below in the computed var itemSections: [ItemSection].
	@FetchRequest(fetchRequest: Location.allLocationsFR())
	private var locations: FetchedResults<Location>
	
		// MARK: - @State and @AppStorage Properties
	
		// trigger to confirm moving all items off the shopping list
	@State private var confirmMoveAllOffListIsPresented = false
	
		// control to bring up a sheet used to add a new item
	@State private var isAddNewItemSheetPresented = false
	
		// user default for whether we are a multi-section display or not.
	@AppStorage(kShoppingListIsMultiSectionKey)
	private var multiSectionDisplay: Bool = kShoppingListIsMultiSectionDefaultValue
	
		// MARK: - BODY

	var body: some View {
		VStack(spacing: 0) {
			
			Rectangle()
				.frame(height: 1)
			
/* ---------
 we display either a "List is Empty" view, a single-section shopping list view
 or multi-section shopping list view.  the list display has some complexity to it because
 of the sectioning, so we push it off to a specialized subview.
 ---------- */
			
			if items.count == 0 {
				EmptyListView(listName: "Shopping")
			} else {
				ItemListView(itemSections: itemSections,
										 sfSymbolName: "purchased",
										 multiSectionDisplay: $multiSectionDisplay)
			}
			
/* ---------
 and for non-empty lists, we have a few buttons at the bottom for bulk operations
 ---------- */
			
			if items.count > 0 {
				Divider()
				ShoppingListBottomButtons()
			} //end of if items.count > 0
			
		} // end of VStack
		.navigationBarTitle("Shopping List")
		.toolbar {
			ToolbarItem(placement: .navigationBarTrailing, content: trailingButtons)
		}
		.sheet(isPresented: $isAddNewItemSheetPresented) {
			AddNewItemView()
		}
		.onDisappear(perform: handleDisappear)
		
	} // end of body: some View
	
		// MARK: - Subviews
	
	private func trailingButtons() -> some View {
		HStack(spacing: 12) {
			ShareLink("", item: shareContent())
				.disabled(items.count == 0)
			
			NavBarImageButton("plus") {
				isAddNewItemSheetPresented = true
			}
		} // end of HStack
	}
	
	private func ShoppingListBottomButtons() -> some View {
		HStack {
			Spacer()
			
			Button("Move All Off List") {
				confirmMoveAllOffListIsPresented = true
			}
			.confirmationDialog("Move All Off List?",
													isPresented: $confirmMoveAllOffListIsPresented,
													titleVisibility: .visible) {
				Button("Yes", role: .destructive,
							 action: Item.moveAllItemsOffShoppingList)
			}

			
			if !items.allSatisfy({ $0.isAvailable })  {
				Spacer()
				Button("Mark All Available") {
					items.forEach { $0.markAvailable() }
				}
			}
			
			Spacer()
		} // end of HStack
		.padding(.vertical, 6)
	}

	// MARK: - Helper Functions
	
	private func handleDisappear() {
			// we save when this view goes off-screen.  we could use a more aggressive
			// strategy for saving data out to persistent storage, but saving here should
			// get the job done.
		persistentStore.save()
	}
	
	private var itemSections: [ItemSection] {
		// the code in this section has been restructured in SL16 so that the
		// view becomes responsive to any change in the order of Locations
		// that might take place in the Locations tab.
		// the key element is that we must use the  `locations` @FetchRequest
		// definition in this code to determine the visitation order of items
		// so that sectioning is done correctly.  if we relied solely on an item's
		// visitationOrder property, SwiftUI would never update this view based
		// on a change made in the Locations tab. (changing a visitation order
		// in SL15 and earlier sent an objectWillChange() message to all associated
		// Items, which will update any view that holds one of those objects as an
		// @ObservedObject, but it won't trigger a @FetchRequest -- i.e., SL15
		// did not handle this at all).
		
		// note that for a little more clarity, i have removed the use of a dictionary
		// to group items on the list by location ... for SL16, let's keep it simple.
		
		// the first step is to construct pairs of the form (location: Location, items: [Item]) for
		// items on the shopping list, where we match each location with its items on the list.
		// (locations with no items on the list will be ignored, and we sort by visitationOrder).
		// however, we do this based on the values in the `locations` @FetchRequest
		// property and not the item's properties (e.g., location).
		let locationItemPairs: [(location: Location, items: [Item])] = locations
			.map({ location in
				( location, location.items.filter({ $0.onList }) )
			})
			.filter({ !$0.items.isEmpty })
			.sorted(by: { $0.location.visitationOrder < $1.location.visitationOrder })

			// if we have nothing on the list, there's nothing for ItemListView to show
		guard items.count > 0 else { return [] }

		// now restructure from (Location, [Item]) to [ItemSection].
		// for a single section, just lump all the items of all the pairs
		// into a single list with flatMap.
		if !multiSectionDisplay {
			return [ItemSection(index: 1,
													title: "Items Remaining: \(items.count)",
													items: locationItemPairs.flatMap{( $0.items )})
			]
		}
		// for multiple sections, we mostly have what we need, but must add an indexing
		// (by agreement with ItemListView), so we'll handle that using .enumerated
		return locationItemPairs.enumerated().map({ (index, pair) in
			ItemSection(index: index + 1, title: pair.location.name, items: pair.items)
		})

	} // end of var itemSections: [ItemSection]
		
		// MARK: - Sharing support
	
	private func shareContent() -> String {
			// we share a straight-forward text description of the
			// shopping list.  note: in SL16, we'll leverage the itemSections variable (!)
		var message = "Items on your Shopping List: \n"
		for section in itemSections {
			message += "\n\(section.title)"
			if !multiSectionDisplay {
				message += ", \(section.items.count) item(s)"
			}
			message += "\n\n"
			for item in section.items {
				message += "  \(item.name)\n"
			}
		}
		return message
	}
	
} // end of ShoppingListBottomButtons
