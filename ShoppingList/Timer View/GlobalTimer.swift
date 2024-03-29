//
//  GlobalTimer.swift
//  ShoppingList
//
//  Created by Jerry on 7/20/20.
//  Copyright © 2020 Jerry. All rights reserved.
//

import Foundation

// with a timer in this the app, it's a real question of whether the timer should be
// stopped when you switch to a different app or get a phone call.  so, you decide.
// in my own case, i would not want to disable the timer if i am on the phone when
// i am in the store because it's probably part of the "shopping experience," e.g., if i
// have to call my wife with a question about which brand of salad dressing to get.
// this boolean determines this behaviour (so my preference is "false")

// fileprivate let kDisableTimerWhenAppIsNotActive = false

// note: if you don't disable the timer when in the background, what we'll really be
// doing is remembering how much time we had accumulated before we went into the
// background; we killed the timer; and when we become active again, we restart a timer,
// setting the startDate of the timer to either the current date, or the date when
// we were previously stopped.

class InStoreTimer: ObservableObject {
	
	// there are three states for this simple timer.  movement between states works this way:
	//
	// .stopped:
	// -- initial state
	// -- calling reset() does not change state, just resets time counters
	// -- calling start() moves to the .running state
	//
	// .running:
	// -- upon entry, creates a timer to call back every 1 second and increment totalAccumulatedTime
	//      and remembers when it starts (either "now" or "when i last shut down") according
	//      to the value of kDisableTimerWhenAppIsNotActive
	// -- calling stop() shuts down the timer and moves back to the .stopped state
	// -- calling suspend() moves into the .suspended state
	//
	// .suspsended:
	// -- upon entry, shuts down the timer, updates totalAccumulatedTime, and remembers its shutdown date
	// -- calling start() moves to the .running state
	
	private enum SLTimerMode {
		case stopped
		case running
		case suspended
	}
	
	// the heart of a timer object is a Timer, if one is active
	private weak var timer: Timer? = nil

	// these are the internals of the timer: when did it last start; when did it last
	// shut down; what state is it in; and how much time had it accumulated before
	// it last shut down up.
	private var previouslyAccumulatedTime: TimeInterval = 0
	private var startDate: Date? = nil
	private var lastStopDate: Date? = nil
	private var state: SLTimerMode = .stopped
			
	// this is what people need to see: its accumulated time, which is the sum of
	// any the previouslyAccumulatedTime plus any current run time.  it gets updated by the timer
	// while running every second, which causes a subscriber to see the update.
	@Published var totalAccumulatedTime: TimeInterval = 0

	// now we let people ask us questions or tell us to do things
	var isSuspended: Bool { return state == .suspended }
	var isRunning: Bool { return state == .running }
	var isStopped: Bool { return state == .stopped }
	
	// new for SL16: whether to suspend the timer when going into the background
	// is now a user preference.  unfortunately, we don't have @AppStorage available
	// here, so we just read UserDefaults directly
	private var suspendWhenInBackground: Bool {
		UserDefaults.standard.bool(forKey: kDisableTimerWhenInBackgroundKey)
	}
	
	private func shutdownTimer() {
		// how long we've been in the .running state
		let accumulatedRunningTime = Date().timeIntervalSince(startDate!)
		// total running time: however long we had been running before entering the
		// current .running state, plus how long we've now been running now
		previouslyAccumulatedTime += accumulatedRunningTime
		totalAccumulatedTime = previouslyAccumulatedTime

		// remember when we  shut down
		lastStopDate = Date()
		// throw out the timer
		timer?.invalidate()
		timer = nil  // should happen anyway with a weak variable
	}
	
	func suspendForBackground() {
		// it only makes sense to suspend if you are running and you've
		// established a preference that you wish to not let the timer
		// effectively be running while in the background
		if suspendWhenInBackground && state == .running {
			shutdownTimer()
			state = .suspended
		}
	}
	
	func start() {
		// we can only start if we are not running (either suspended or stopped)
		if state != .running {
			// set new start time beginning now
			startDate = Date()
			// except, if we are restarting the timer after the app was moved from inactive
			// to active, use whatever we had as the lastStopDate when we suspended to be
			// the new startDate (if so configured to do so)
			if isSuspended && !suspendWhenInBackground {
				startDate = lastStopDate
			}
			// schedule a new timer
			timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(update)), userInfo: nil, repeats: true)
			state = .running
		}
	}
	
	func stop() {
		// it only makes sense to stop if you are running
		if state == .running {
			shutdownTimer()
			state = .stopped
		}
	}
	
	@objc private func update() {
		// how long we've been running in the current .running state
		// and add in any previously accumulated time
		totalAccumulatedTime = previouslyAccumulatedTime + Date().timeIntervalSince(startDate!)
	}
	
	func reset() {
		guard state == .stopped else { return }
		previouslyAccumulatedTime = 0
		totalAccumulatedTime = 0
	}
	
}
