//
//  ShoppingListApp.swift
//  ShoppingList
//
//  Created by Jerry on 11/19/20.
//  Copyright © 2020 Jerry. All rights reserved.
//

import Foundation
import SwiftUI

/*
 the app will hold an object of type Today, which keeps track of the "start of today."
 the PurchasedItemsView needs to know what "today" means to properly section out
 its data, and it might seem to you that the PurchasedItemsView could handle that by
 itself.  however, if you push the app into the background when the PurchasedItemsView
 is showing and then bring it back a few days later, the PurchasedItemsView will show
 the same display as when it went into the background and not know about the change;
 so its view will need to be updated.  that's why this is here: the app certainly
 knows when it becomes active, can update what "today" means, and the
 PurchasedItemsView will pick up on that in its environment
 */

class Today: ObservableObject {
	@Published var start: Date = Calendar.current.startOfDay(for: Date())
	
	func update() {
		let newStart = Calendar.current.startOfDay(for: Date())
		if newStart != start {
			start = newStart
		}
	}
}

/*
the App creates both the (global, singleton) PersistentStore and a Today object
as @StateObjects and pushes the managedObjectContext of the PersistentStore
and the Today object into the SwiftUI environment.
new in this version is that we have the App create the InStoreTimer as well and
push that into the environment, for use with the TimerTabView.
we also attach .onReceive modifiers to the MainView to watch being moved into
and out of the background.
*/

@main
struct ShoppingListApp: App {
	
	@StateObject var persistentStore: PersistentStore
	@StateObject var today = Today()
	@StateObject var inStoreTimer = InStoreTimer()
	
	let resignActivePublisher =
		NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
	let enterForegroundPublisher =
		NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
	
	init() {
		// this is done in an init so we can create the persistentStore, set up
		// the App's @StateObject for it, and also set the static (class) variables
		// for Item and Location classes so they can access the store
		//and its context.
		let store = PersistentStore()
		Item.persistentStore = store
		Location.persistentStore = store
		_persistentStore = StateObject(wrappedValue: store)
	}
	
	var body: some Scene {
		WindowGroup {
			MainView()
				.environment(\.managedObjectContext, persistentStore.context)
				.environmentObject(persistentStore)
				.environmentObject(today)
				.environmentObject(inStoreTimer)
				.onReceive(resignActivePublisher, perform: handleResignActive)
				.onReceive(enterForegroundPublisher, perform: handleBecomeActive)
		}
	}
	
	func handleResignActive(_ note: Notification) {
			// when going into background, save Core Data (right now, please) and shut down timer
		persistentStore.save()
		inStoreTimer.suspendForBackground()
	}
	
	func handleBecomeActive(_ note: Notification) {
			// when app becomes active, restart timer if it was running previously.
			// also update the meaning of Today because we may be transitioning to
			// active on a different day than when we were pushed into the background
		if inStoreTimer.isSuspended {
			inStoreTimer.start()
		}
		today.update()
	}

}
