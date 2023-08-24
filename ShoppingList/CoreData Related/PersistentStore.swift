//
//  PersistentStore.swift
//  ShoppingList
//
//  Created by Jerry on 7/4/20.
//  Copyright © 2020 Jerry. All rights reserved.
//

import Foundation
import CoreData

final class PersistentStore: ObservableObject {
	
		// a reference to a task that delays saving data
	private var saveTask: Task<Void, Error>?
	
	lazy var persistentContainer: NSPersistentContainer = {
		/*
		The persistent container for the application. This implementation
		creates and returns a container, having loaded the store for the
		application to it. This property is optional since there are legitimate
		error conditions that could cause the creation of the store to fail.
		*/
		
		// choose here whether you want the cloud or not
		// -- when i install this on a device, i may want the cloud (you will need an Apple Developer
		//    account to use the cloud an add the right entitlements to your project);
		// -- for some initial testing on the simulator, i may use the cloud;
		// -- but for basic app building in the simulator, i prefer a non-cloud store.
		// by the way: using NSPersistentCloudKitContainer in the simulator works fine,
		// but you will see lots of console traffic about sync transactions.  those are not
		// errors, but it will clog up your console window.
		//
		// by the way, just choosing to use NSPersistentCloudKitContainer is not enough by itself.
		// you will have to make some changes in the project settings. see
		//    https://developer.apple.com/documentation/coredata/mirroring_a_core_data_store_with_cloudkit/setting_up_core_data_with_cloudkit
		// i have already made those changes in this project, but you will need your own
		// CloudKit container definition.
		
		// you need to decide which of NSPersistentContainer or NSPersistentCloudKitContainer
		// you want to use (the latter is for sharing across devices associated with the same iCloud
		// identifier.)
		// and to make this work, you'll also need to update the bundle identifier
		// (it cannot be com.dela.ware.math.ShoppingList -- that's my container).
#warning("⚠️ Please choose correct definition of Persistent Container")
#if targetEnvironment(simulator)
			// i avoid using the cloud with the simulator.  reason: i prefer to keep the simulator
			// off the cloud and away from real data that's being used on-device and shared with the
			// cloud ... i always want it to be a test bed where i can do outrageous things, such as
			// "delete all data," and i certainly don't want to do that with my real data (should the
			// simulator).
			// there are also a number of comments about the simulator not always working
			// well with cloud sync, if signed into iCloud.
		let container = NSPersistentContainer(name: "ShoppingList")
#else
			// but for a device, YOU must decide whether you'll just keep all data local, or
			// whether you feel the need to share with your other devices through the cloud.
			// USE  THIS DEFINITION (DEFAULT) FOR CONTAINER for on-device-only data storage:
		let container = NSPersistentContainer(name: "ShoppingList")
			// OR THIS DEFINITION FOR CONTAINER for on-device data storage shared via the cloud
			// and remember: you need a paid Apple Developer Subscription to work with the cloud.
//		let container = NSPersistentCloudKitContainer(name: "ShoppingList")
#endif

		// some of what follows are suggestions by "Apple Staff" on the Apple Developer Forums
		// for the case when you have an NSPersistentCloudKitContainer and iCloud synching
		// https://developer.apple.com/forums/thread/650173
		// you'll also see there how to use this code with the new XCode 12 App/Scene structure
		// that replaced the AppDelegate/SceneDelegate of XCode 11 and iOS 13.  additionally,
		// follow along with this discussion https://developer.apple.com/forums/thread/650876
		
		// (1) Enable history tracking.  this seems to be important when you have more than one persistent
		// store in your app (e.g., when using the cloud) and you want to do any sort of cross-store
		// syncing.  See WWDC 2019 Session 209, "Making Apps with Core Data."
		// also, once you use NSPersistentCloudKitContainer and turn these on, then you should leave
		// these on, even if you just now want to use what's on-disk with NSPersistentContainer and
		// without cloud access.
		guard let persistentStoreDescription = container.persistentStoreDescriptions.first else {
			fatalError("\(#function): Failed to retrieve a persistent store description.")
		}
		persistentStoreDescription.setOption(true as NSNumber,
																					forKey: NSPersistentHistoryTrackingKey)
		persistentStoreDescription.setOption(true as NSNumber,
																					forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
		
		container.loadPersistentStores(completionHandler: { (storeDescription, error) in
			if let error = error as NSError? {
				// Replace this implementation with code to handle the error appropriately.
				// fatalError() causes the application to generate a crash log and terminate. You should not use
				// this function in a shipping application, although it may be useful during development.
				
				/*
				Typical reasons for an error here include:
				* The parent directory does not exist, cannot be created, or disallows writing.
				* The persistent store is not accessible, due to permissions or data protection when the device is locked.
				* The device is out of space.
				* The store could not be migrated to the current model version.
				Check the error message to determine what the actual problem was.
				*/
				fatalError("Unresolved loadPersistentStores error \(error), \(error.userInfo)")
			}
			
		})
		
			// (2) also suggested for cloud-based Core Data are the two lines below for syncing with
			// the cloud.  i don't think there's any harm in adding these even for a single, on-disk
			// local store.
		container.viewContext.automaticallyMergesChangesFromParent = true
		container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
		
			// (3) when a Core Data object is deleted, it somewhat remains in memory as a
			// bit of a zombie object.  setting this to true (which i believe is the default) makes
			// sure that the isDeleted property of the object is set ... so we might ask about
			// it if we want in certain cases.  but in my experience, i'm not convinced
			// isDeleted returns the value true.
		container.viewContext.shouldDeleteInaccessibleFaults = true
		
		
			// this allows us to detect changes occurring outside of our code and update our UI,
			// according to Paul Hudson.  this is a recent addition, and to tell you the truth,
			// i have not had problems prior to including this: i think all the @FetchRequests
			// out there pick this up already.  but whether @ObservedObjects are getting
			// the message, well,, that's a different question that might be addressed here.
		NotificationCenter.default.addObserver(forName: .NSPersistentStoreRemoteChange,
																					 object: container.persistentStoreCoordinator,
																					 queue: .main,
																					 using: remoteStoreChanged)

		return container
	}()
	
	var context: NSManagedObjectContext { persistentContainer.viewContext }
	
		// call save to update the persistent store on disk "right away."
		// call this directly after all deletions; most other times, you
		// should be calling queueSave(), which delays/debounces save
		// operations so that we're grouping small changes that occur
		// in rapid succession into a single save operation.
	func save() {
		if context.hasChanges {
			do {
				try context.save()
			} catch let error as NSError {
				NSLog("Unresolved error saving context: \(error), \(error.userInfo)")
			}
		}
	}
	
/*
 *** code below courtesy of Paul Hudson ***
 call queueSave when saving data need not be immediate, but can wait
 a little bit.   we just set up a task to do the saving for us and define it
 so that it will not activate for a few seconds (or your choice of length
 of inactivity).
 for example, this means that if you can queueSave and then right away,
say within a second or two, call queueSave again, we're not saving twice;
 rather, we cancel any stored saving task and restart a new one with a
 new "countdown clock" to do the save.
 
 *** of note ***: we WILL call save() directly in the case of Item and Location
 object DELETIONS.  there are known issues with the timing of deletions with
 SwiftUI's occasional access to @ObservedObjects that are deleted, and so
 saving right after a deletion seems to keep some of these problems under control.
 */
	let saveDelay = 5 // a five-second debouncing of save operations
	func queueSave() {
			// cancel any existing, queued task to save
		saveTask?.cancel()
			// put in a new/replacement task to save after a delay.
		saveTask = Task {
			try await Task.sleep(for: .seconds(saveDelay))
			save()
		}
	}
	
		// if the remote store changes, this then re-broadcasts the change to anyone
		// who is listening.
	func remoteStoreChanged(_ notification: Notification) {
		objectWillChange.send()
	}
}
