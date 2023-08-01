	//
	//  PurchasedItemsView.swift
	//  ShoppingList
	//
	//  Created by Jerry on 5/14/20.
	//  Copyright © 2020 Jerry. All rights reserved.
	//

import SwiftUI

	// a simple list of items that are not on the current shopping list
	// these are the items that were on the shopping list at some time and
	// were later removed -- items we purchased.  you could also call it a
	// catalog, of sorts, although we only show items that we know about
	// that are not already on the shopping list.

struct PurchasedItemsView: View {
	
		// MARK: - @Environment Properties

		// link in to what is the start of today
	@EnvironmentObject var today: Today
	@EnvironmentObject private var persistentStore: PersistentStore
		// the value of Calendar.current is in the environment
	@Environment(\.calendar) private var calendar
	
		// MARK: - @FetchRequest
	
		// this is the @FetchRequest that ties this view to CoreData
	@FetchRequest(fetchRequest: Item.allItemsFR(onList: false))
	private var items: FetchedResults<Item>
	
		// MARK: - @State and @AppStorage Properties

		// the usual @State variables to handle the Search field
	@State private var searchText: String = ""
	
		// trigger for sheet used to add a new shopping item
	@State private var isAddNewItemSheetPresented = false

		// items currently checked, on their way to the shopping list
	@State private var itemsChecked = [Item]()
	
		// number of days in the past for the first section when using sections
	@AppStorage(kPurchasedMostRecentlyKey)
	private var historyMarker = kPurchasedMostRecentlyDefaultValue
	
	@AppStorage(kPurchasedListIsMultiSectionKey)
	private var multiSectionDisplay: Bool = kPurchasedListIsMultiSectionDefaultValue

		// MARK: - BODY

	var body: some View {
		VStack(spacing: 0) {
			
			Rectangle()
				.frame(height: 1)
			
				// display either a "List is Empty" view, or the sectioned list of purchased items.
			if items.count == 0 {
				EmptyListView(listName: "Purchased")
			} else {
				ItemListView(itemSections: itemSections,
										 sfSymbolName: "cart",
										 multiSectionDisplay: $multiSectionDisplay)
			} // end of if-else
			
			Divider() // keeps list from overrunning the tab bar in iOS 15
		} // end of VStack
		.searchable(text: $searchText)
		.onAppear(perform: handleOnAppear)
		.onDisappear(perform: handleDisappear)
		.navigationBarTitle("Purchased List")
		.toolbar {
			ToolbarItem(placement: .navigationBarTrailing, content: addNewButton)
		}
		.sheet(isPresented: $isAddNewItemSheetPresented) {
			AddNewItemView()
		}
	} // end of var body: some View

		// MARK: - Subviews

		// makes a simple "+" to add a new item.  yapping on the button triggers a sheet to add a new item.
	func addNewButton() -> some View {
		NavBarImageButton("plus") {
			isAddNewItemSheetPresented = true
		}
	}
	
		// MARK: - Helper Functions
	
	func handleOnAppear() {
		searchText = "" // clear searchText, get a clean screen
		today.update() // also recompute what "today" means, so the sectioning is correct
	}
	
	func handleDisappear() {
			// we save when this view goes off-screen.  we could use a more aggressive
			// strategy for saving data out to persistent storage, but saving here should
			// get the job done.
		persistentStore.save()
	}
	
		// the idea of this function is to break out the purchased Items into sections,
		// where we can produce either one section for everything, or else two sections
		// if multiSectionDisplay == true with:
		// -- those items purchased within the last N days,
		// -- and everything else
	var itemSections: [ItemSection] {
			// reduce items by search criteria
		let searchQualifiedItems = items.filter({ searchText.appearsIn($0.name) })
		
			// do we show one big section or two (recent + everything else)?
			// the one big section case is pretty darn easy:
		if !multiSectionDisplay {
			if searchText.isEmpty {
				return [ItemSection(index: 1, title: "Items: \(items.count)",
														items: items.map({ $0 }))]
			}
			return [ItemSection(index: 1, title: "Items containing: \"\(searchText)\": \(searchQualifiedItems.count)",
													items: searchQualifiedItems)]
		}
		
			// so we're doing two sections where we break these out
			// into (Today + back historyMarker days) and (all the others)
		let startingMarker = calendar.date(byAdding: .day, value: -historyMarker, to: today.start)!
		let recentItems = searchQualifiedItems
			.filter({ $0.dateLastPurchased != nil && $0.dateLastPurchased! >= startingMarker })
		let allOlderItems = searchQualifiedItems
			.filter({ $0.dateLastPurchased == nil || $0.dateLastPurchased! < startingMarker })
		
			// return an array of two sections only
		return [
			ItemSection(index: 1,
									title: section1Title(count: recentItems.count),
									items: recentItems),
			ItemSection(index: 2,
									title: section2Title(count: allOlderItems.count),
									items: allOlderItems)
		]
	}
	
	func section1Title(count: Int) -> String {
		var title = "Items Purchased "
		if historyMarker == 0 {
			title += "Today "
		} else {
			title += "in the last \(historyMarker) days "
		}
		if !searchText.isEmpty {
			title += "containing \"\(searchText)\" "
		}
		title += "(\(count) items)"
		return title
	}
	
	func section2Title(count: Int) -> String {
		var title = "(Other) Items"
		if !searchText.isEmpty {
			title += " containing \"\(searchText)\""
		}
		title += ": \(count)"
		return title
	}
	

	
}
