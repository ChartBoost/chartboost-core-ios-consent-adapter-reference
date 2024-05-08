// Copyright 2023-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// INTERNAL. FOR DEMO AND TESTING PURPOSES ONLY. DO NOT USE DIRECTLY.
/// A dummy SDK designed to support the Reference adapter.
/// Do NOT copy.
class ReferenceCMPSDK {

    static var shouldCollectConsent = false

    static var ccpaOptIn = true

    static var gdprConsentGiven = true

    typealias PartnerID = String

    static var partnerConsents: [PartnerID: Bool] = [
        "reference-cmp-partner-1": true,
        "reference-cmp-partner-2": false,
        "reference-cmp-partner-3": true,
        "reference-cmp-partner-4": false
    ]

    static func initializeSDK() {}

    static func forceSetConsentGranted() {
        ccpaOptIn = true
        gdprConsentGiven = true
        notifyConsetChangedToObservers()
    }

    static func forceSetConsentDenied() {
        ccpaOptIn = false
        gdprConsentGiven = false
        notifyConsetChangedToObservers()
    }

    static func reset() {
        ccpaOptIn = false
        gdprConsentGiven = false
        notifyConsetChangedToObservers()
    }

    static func showConciseDialog() {
        randomizeConsentValues()
        notifyConsetChangedToObservers()
    }

    static func showDetailedDialog() {
        randomizeConsentValues()
        notifyConsetChangedToObservers()
    }

    static func addObserverForConsentChanges(_ observer: ReferenceCMPSDKConsentObserver) {
        observers.append(observer)
    }

    static var observers: [ReferenceCMPSDKConsentObserver] = []

    private static func notifyConsetChangedToObservers() {
        observers.forEach {
            $0.ccpaOptInChanged()
            $0.gdprConsentGivenChanged()
            $0.partnerConsentsChanged()
        }
    }

    private static func randomizeConsentValues() {
        ccpaOptIn = .random()
        gdprConsentGiven = .random()
        for key in partnerConsents.keys {
            partnerConsents[key] = Bool.random()
        }
    }
}

protocol ReferenceCMPSDKConsentObserver: AnyObject {
    func ccpaOptInChanged()
    func gdprConsentGivenChanged()
    func partnerConsentsChanged(partnerIDs: Set<PartnerID>)
}
