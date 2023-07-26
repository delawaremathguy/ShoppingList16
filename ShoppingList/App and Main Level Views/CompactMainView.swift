//
//  CompactMainView.swift
//  ShoppingList
//
//  Created by Jerry on 5/6/20.
//  Copyright © 2020 Jerry. All rights reserved.
//

import SwiftUI

// the CompactMainView is a tab view with five tabs.
// not much happens here, although do notice that each of the five views is
// wrapped in a NavigationStack.  this makes perfect sense in SwiftUI ... a
// NavigationStack can be a subview of a TabView, but don't ever make a TabView
// a subview of a NavigationStack !

struct CompactMainView: View {
	var body: some View {
		TabView {
			NavigationStack { ShoppingListView() }
				.tabItem { Label("Shopping List", systemImage: "cart") }
			
			NavigationStack { PurchasedItemsView() }
				.tabItem { Label("Purchased", systemImage: "purchased") }
			
			NavigationStack { LocationsView() }
				.tabItem { Label("Locations", systemImage: "map") }
			
			NavigationStack { PreferencesView() }
				.tabItem { Label("Preferences", systemImage: "gear") }
			
			NavigationStack { MoreView()  }
				.tabItem { Label("More", systemImage: "ellipsis") }

		} // end of TabView
	} // end of var body: some View
}

