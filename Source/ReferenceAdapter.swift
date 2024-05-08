// Copyright 2023-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostCoreSDK

/// INTERNAL. FOR DEMO AND TESTING PURPOSES ONLY. DO NOT USE DIRECTLY.
///
/// An adapter that is used for reference purposes. It is designed to showcase and test the Consent Adapter contract of the Chartboost Core SDK.
/// Implementations of the Chartboost Core Consent Adapter interface may roughly model their own design after this class, but do NOT call this adapter directly.
@objc(CBCReferenceAdapter)
@objcMembers
public final class ReferenceAdapter: NSObject, ConsentAdapter {

    /// The module identifier.
    public let moduleID = "reference"

    /// The version of the module.
    public let moduleVersion = "1.1.0.0.0"

    /// The delegate to be notified whenever any change happens in the CMP consent info.
    /// This delegate is set by Core SDK and is an essential communication channel between Core and the CMP.
    /// Adapters should not set it themselves.
    public weak var delegate: ConsentAdapterDelegate?

    /// The observer for changes on UserDefault's consent-related keys.
    private var userDefaultsObserver: Any?

    /// Indicates whether the CMP has determined that consent should be collected from the user.
    public var shouldCollectConsent: Bool {
        ReferenceCMPSDK.shouldCollectConsent
    }

    /// Current user consent info as determined by the CMP.
    ///
    /// Consent info may include IAB strings, like TCF or GPP, and parsed boolean-like signals like "CCPA Opt In Sale"
    /// and partner-specific signals.
    ///
    /// Predefined consent key constants, such as ``ConsentKeys/tcf`` and ``ConsentKeys/usp``, are provided
    /// by Core. Adapters should use them when reporting the status of a common standard.
    /// Custom keys should only be used by adapters when a corresponding constant is not provided by the Core.
    ///
    /// Predefined consent value constants are also proivded, but are only applicable to non-IAB string keys, like
    /// ``ConsentKeys/ccpaOptIn`` and ``ConsentKeys/gdprConsentGiven``.
    public var consents: [ConsentKey: ConsentValue] {
        // First load the standard IAB strings from User Defaults
        // (A modern CMP likely supports the IAB standard and this may be the only thing that needs to be done).
        var consents = userDefaultsIABStrings()
        // Optionally include boolean consent info for different consent standards.
        // Your CMP may or may not provide this kind of info. If it does, it's better to include it, as it may be needed
        // by Core modules that do not yet support IAB standards.
        consents[ConsentKeys.ccpaOptIn] = ReferenceCMPSDK.ccpaOptIn ? ConsentValues.granted : ConsentValues.denied
        consents[ConsentKeys.gdprConsentGiven] = ReferenceCMPSDK.gdprConsentGiven ? ConsentValues.granted : ConsentValues.denied
        // Optionally include boolean consent info targeted to specific partners.
        // Your CMP may or may not provide this kind of info.
        for referencePartnerID, consented in ReferenceCMPSDK.partnerConsents {
            let key = mapReferenceCMPPartnerIDToChartboostPartnerID(referencePartnerID)
            consents[key] = consented ? ConsentValues.granted : ConsentValues.denied
        }
        return consents
    }

    /// Showcases how CMP-specific partner IDs may be mapped to Chartboost-specific partner IDs.
    /// CMPs may have their own identifiers associated with partner SDKs (e.g. ad SDKs), and they need to be mapped to standard
    /// Chartboost partner IDs so other Chartboost Core modules can use them.
    private var func mapReferenceCMPPartnerIDToChartboostPartnerID(_ referencePartnerID: ReferenceCMPSDK.PartnerID) -> String {
        let map =
            ["reference-cmp-partner-1": "chartboost",
             "reference-cmp-partner-1": "admob",
             "reference-cmp-partner-1": "facebook",
             "reference-cmp-partner-1": "some_other_sdk"]
        return map[referencePartnerID] ?? referencePartnerID
    }

    // MARK: - Instantiation and Initialization

    /// Instantiates a ``ReferenceAdapter`` module which can be passed on a call to
    /// ``ChartboostCore/initializeSDK(configuration:moduleObserver:)``.
    public convenience init() {
        self.init(credentials: nil)
    }

    /// The designated initializer for the module.
    /// The Chartboost Core SDK will invoke this initializer when instantiating modules defined on
    /// the dashboard through reflection.
    /// - parameter credentials: A dictionary containing all the information required to initialize
    /// this module, as defined on the Chartboost Core's dashboard.
    ///
    /// - note: Modules should not perform costly operations on this initializer.
    /// Chartboost Core SDK may instantiate and discard several instances of the same module.
    /// Chartboost Core SDK keeps strong references to modules that are successfully initialized.
    public init(credentials: [String: Any]?) {
        // You may read here some configuration options from the credentials map.
        // E.g. self.featureFlagEnabled = credentials?["feature_flag_enabled"] as? Bool ?? false

        // Start observing changes to standard IAB strings in the User Defaults
        // (A modern CMP likely supports the IAB standard and this may be the only thing that needs to be observed).
        userDefaultsObserver = startObservingUserDefaultsIABStrings()

        // Optionally start observing changes to custom consent values provided by the CMP.
        // Your CMP may or may not provide this kind of info. If it does, it's important to observe changes to it
        // so Chartboost Core is always up to date with the latest consent info that the CMP provides.
        ReferenceCMPSDK.addObserverForConsentChanges(self)
    }

    /// Sets up the module to make it ready to be used.
    /// - parameter configuration: A ``ModuleConfiguration`` for configuring the module.
    /// - parameter completion: A completion handler to be executed when the module is done initializing.
    /// An error should be passed if the initialization failed, whereas `nil` should be passed if it succeeded.
    public func initialize(configuration: ModuleConfiguration, completion: @escaping (Error?) -> Void) {
        // Initialize the CMP SDK.
        ReferenceCMPSDK.initializeSDK()
    }

    // MARK: - Consent

    /// Informs the CMP that the user has granted consent.
    /// This method should be used only when a custom consent dialog is presented to the user, thereby making the publisher
    /// responsible for the UI-side of collecting consent. In most cases ``showConsentDialog(_:from:completion:)`` should
    /// be used instead.
    /// If the CMP does not support custom consent dialogs or the operation fails for any other reason, the completion
    /// handler is executed with a `false` parameter.
    /// - parameter source: The source of the new consent. See the ``ConsentSource`` documentation for more info.
    /// - parameter completion: Handler called to indicate if the operation went through successfully or not.
    public func grantConsent(source: ConsentSource, completion: @escaping (_ succeeded: Bool) -> Void) {
        // Optionally call the CMP method to grant consent, if the CMP provides this functionality.
        ReferenceCMPSDK.forceSetConsentGranted()
        completion(true)
    }

    /// Informs the CMP that the user has denied consent.
    /// This method should be used only when a custom consent dialog is presented to the user, thereby making the publisher
    /// responsible for the UI-side of collecting consent. In most cases ``showConsentDialog(_:from:completion:)``should
    /// be used instead.
    /// If the CMP does not support custom consent dialogs or the operation fails for any other reason, the completion
    /// handler is executed with a `false` parameter.
    /// - parameter source: The source of the new consent. See the ``ConsentSource`` documentation for more info.
    /// - parameter completion: Handler called to indicate if the operation went through successfully or not.
    public func denyConsent(source: ConsentSource, completion: @escaping (_ succeeded: Bool) -> Void) {
        // Optionally call the CMP method to deny consent, if the CMP provides this functionality.
        ReferenceCMPSDK.forceSetConsentDenied()
        completion(true)
    }

    /// Informs the CMP that the given consent should be reset.
    /// If the CMP does not support the `reset()` function or the operation fails for any other reason, the completion
    /// handler is executed with a `false` parameter.
    /// - parameter completion: Handler called to indicate if the operation went through successfully or not.
    public func resetConsent(completion: @escaping (_ succeeded: Bool) -> Void) {
        // Optionally call the CMP method to reset, if the CMP provides this functionality.
        ReferenceCMPSDK.reset()
        completion(true)
    }

    /// Instructs the CMP to present a consent dialog to the user for the purpose of collecting consent.
    /// - parameter type: The type of consent dialog to present. See the ``ConsentDialogType`` documentation for more info.
    /// If the CMP does not support a given type, it should default to whatever type it does support.
    /// - parameter viewController: The view controller to present the consent dialog from.
    /// - parameter completion: This handler is called to indicate whether the consent dialog was successfully presented or not.
    /// Note that this is called at the moment the dialog is presented, **not when it is dismissed**.
    public func showConsentDialog(
        _ type: ConsentDialogType,
        from viewController: UIViewController,
        completion: @escaping (_ succeeded: Bool) -> Void
    ) {
        // Call the CMP method to show the dialog.
        // We assume the ReferenceCMPSDK always succeeds in showing a dialog so we pass `true` in the completion.
        if type == .concise {
            ReferenceCMPSDK.showConciseDialog()
        } else {
            ReferenceCMPSDK.showDetailedDialog()
        }
        completion(true)
    }
}

// Conformance to the ReferenceCMPSDK observer protocol which provides consent updates.
// This is just an example, your CMP may provide different kinds of updates using different mechanisms (e.g.
// notifications, delegate methods, observers, etc.).
extension ReferenceAdapter: ReferenceCMPSDKConsentObserver {

    func ccpaOptInChanged() {
        delegate?.onConsentChange(key: ConsentKey.ccpaOptIn)
    }

    func gdprConsentGivenChanged() {
        delegate?.onConsentChange(key: ConsentKey.ccpaOptIn)
    }

    func partnerConsentsChanged(partnerIDs: Set<PartnerID>) {
        // Same as in the implementation of the `consents` computed property, we must map CMP-specific partner IDs
        // to Chartboost-specific partner IDs to other Chartboost Core modules can use them.
        for referencePartnerID in partnerIDs {
            let key = mapReferenceCMPPartnerIDToChartboostPartnerID(referencePartnerID)
            delegate?.onConsentChange(key: key)
        }
    }
}
