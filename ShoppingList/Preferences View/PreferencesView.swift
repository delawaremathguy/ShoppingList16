//
//  OperationTabView.swift
//  ShoppingList
//
//  Created by Jerry on 6/11/20.
//  Copyright © 2020 Jerry. All rights reserved.
//

import SwiftUI

struct PreferencesView: View {
	
		// this view is for user preferences:
		//
		// Purchased Items History Mark:
		// -- first section: items purchased within the last N days
		// -- second section: all other items purchased.
		// we'll allow N here to be 0 ... 10
		//
		// in SL16, i have added a preference for whether to disable a running timer
		// when in the background; and i have cleaned up the view code so i can really
		// read and understand some of what was written three years ago (!)
		// i also have moved the former "devtools hacks" over to the MoreView.
	
	// user default. 0 = purchased today; 3 = purchased up to 3 days ago, ...
	@AppStorage(kPurchasedMostRecentlyKey)
	private var historyMarker = kPurchasedMostRecentlyDefaultValue
	
	// user default.  true ==> turn of timer (counting) when in the background.
	@AppStorage(kDisableTimerWhenInBackgroundKey)
	private var suspendTimerWhenInBackground = kDisableTimerWhenInBackgroundDefaultValue

	var body: some View {
		Form {
			Section(header: Text("Purchased Items History Mark"),
							footer: Text("Sets the number of days to look backwards in time to separate out items purchased recently.")) {
				Stepper(value: $historyMarker, in: 0...10) {
					HStack {
						SLFormLabelText(labelText: "History mark: ")
						Text("\(historyMarker)")
					}
				}
			}
			
			Section(header: Text("Timer Preference"),
							footer: Text("Turn this on if you want the timer to pause, say, while you are on a phone call")) {
				Toggle(isOn: $suspendTimerWhenInBackground) {
					Text("Suspend when in background")
				}
			}
		} // end of Form
		.navigationBarTitle("Preferences")
	} // end of var body: some View
	
}
