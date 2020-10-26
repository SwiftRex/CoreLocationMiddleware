// Generated using Sourcery 1.0.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT


import CoreLocation

extension LocationAction {
    public var request: RequestAction? {
        get {
            guard case let .request(associatedValue0) = self else { return nil }
            return (associatedValue0)
        }
        set {
            guard case .request = self, let newValue = newValue else { return }
            self = .request(newValue)
        }
    }

    public var isRequest: Bool {
        self.request != nil
    }

    public var status: StatusAction? {
        get {
            guard case let .status(associatedValue0) = self else { return nil }
            return (associatedValue0)
        }
        set {
            guard case .status = self, let newValue = newValue else { return }
            self = .status(newValue)
        }
    }

    public var isStatus: Bool {
        self.status != nil
    }

}

extension RequestAction {
    public var start: MonitoringType? {
        get {
            guard case let .start(associatedValue0) = self else { return nil }
            return (associatedValue0)
        }
        set {
            guard case .start = self, let newValue = newValue else { return }
            self = .start(newValue)
        }
    }

    public var isStart: Bool {
        self.start != nil
    }

    public var stop: MonitoringType? {
        get {
            guard case let .stop(associatedValue0) = self else { return nil }
            return (associatedValue0)
        }
        set {
            guard case .stop = self, let newValue = newValue else { return }
            self = .stop(newValue)
        }
    }

    public var isStop: Bool {
        self.stop != nil
    }

    public var requestAuthorizationStatus: Void? {
        get {
            guard case .requestAuthorizationStatus = self else { return nil }
            return ()
        }
    }

    public var isRequestAuthorizationStatus: Bool {
        self.requestAuthorizationStatus != nil
    }

    public var requestAuthorizationType: Void? {
        get {
            guard case .requestAuthorizationType = self else { return nil }
            return ()
        }
    }

    public var isRequestAuthorizationType: Bool {
        self.requestAuthorizationType != nil
    }

    public var requestPosition: Void? {
        get {
            guard case .requestPosition = self else { return nil }
            return ()
        }
    }

    public var isRequestPosition: Bool {
        self.requestPosition != nil
    }

    public var requestState: CLRegion? {
        get {
            guard case let .requestState(associatedValue0) = self else { return nil }
            return (associatedValue0)
        }
        set {
            guard case .requestState = self, let newValue = newValue else { return }
            self = .requestState(newValue)
        }
    }

    public var isRequestState: Bool {
        self.requestState != nil
    }

    public var requestDeviceCapabilities: Void? {
        get {
            guard case .requestDeviceCapabilities = self else { return nil }
            return ()
        }
    }

    public var isRequestDeviceCapabilities: Bool {
        self.requestDeviceCapabilities != nil
    }

    public var requestLocationServiceConfiguration: LocationServiceConfiguration?? {
        get {
            guard case let .requestLocationServiceConfiguration(associatedValue0) = self else { return nil }
            return (associatedValue0)
        }
        set {
            guard case .requestLocationServiceConfiguration = self, let newValue = newValue else { return }
            self = .requestLocationServiceConfiguration(newValue)
        }
    }

    public var isRequestLocationServiceConfiguration: Bool {
        self.requestLocationServiceConfiguration != nil
    }

    public var requestHeadingServiceConfiguration: HeadingServiceConfiguration?? {
        get {
            guard case let .requestHeadingServiceConfiguration(associatedValue0) = self else { return nil }
            return (associatedValue0)
        }
        set {
            guard case .requestHeadingServiceConfiguration = self, let newValue = newValue else { return }
            self = .requestHeadingServiceConfiguration(newValue)
        }
    }

    public var isRequestHeadingServiceConfiguration: Bool {
        self.requestHeadingServiceConfiguration != nil
    }

    public var requestRegionMonitoringServiceConfiguration: Void? {
        get {
            guard case .requestRegionMonitoringServiceConfiguration = self else { return nil }
            return ()
        }
    }

    public var isRequestRegionMonitoringServiceConfiguration: Bool {
        self.requestRegionMonitoringServiceConfiguration != nil
    }

    public var requestBeaconRangingConstraints: Void? {
        get {
            guard case .requestBeaconRangingConstraints = self else { return nil }
            return ()
        }
    }

    public var isRequestBeaconRangingConstraints: Bool {
        self.requestBeaconRangingConstraints != nil
    }

}

extension StatusAction {
    public var gotPosition: CLLocation? {
        get {
            guard case let .gotPosition(associatedValue0) = self else { return nil }
            return (associatedValue0)
        }
        set {
            guard case .gotPosition = self, let newValue = newValue else { return }
            self = .gotPosition(newValue)
        }
    }

    public var isGotPosition: Bool {
        self.gotPosition != nil
    }

    public var gotHeading: CLHeading? {
        get {
            guard case let .gotHeading(associatedValue0) = self else { return nil }
            return (associatedValue0)
        }
        set {
            guard case .gotHeading = self, let newValue = newValue else { return }
            self = .gotHeading(newValue)
        }
    }

    public var isGotHeading: Bool {
        self.gotHeading != nil
    }

    public var gotVisit: CLVisit? {
        get {
            guard case let .gotVisit(associatedValue0) = self else { return nil }
            return (associatedValue0)
        }
        set {
            guard case .gotVisit = self, let newValue = newValue else { return }
            self = .gotVisit(newValue)
        }
    }

    public var isGotVisit: Bool {
        self.gotVisit != nil
    }

    public var gotBeacon: ([CLBeacon], CLBeaconIdentityConstraint)? {
        get {
            guard case let .gotBeacon(associatedValue0, associatedValue1) = self else { return nil }
            return (associatedValue0, associatedValue1)
        }
        set {
            guard case .gotBeacon = self, let newValue = newValue else { return }
            self = .gotBeacon(newValue.0, newValue.1)
        }
    }

    public var isGotBeacon: Bool {
        self.gotBeacon != nil
    }

    public var gotRegion: (CLRegion, CLRegionState)? {
        get {
            guard case let .gotRegion(associatedValue0, associatedValue1) = self else { return nil }
            return (associatedValue0, associatedValue1)
        }
        set {
            guard case .gotRegion = self, let newValue = newValue else { return }
            self = .gotRegion(newValue.0, newValue.1)
        }
    }

    public var isGotRegion: Bool {
        self.gotRegion != nil
    }

    public var gotLocationUpdatesDeliveryStatus: LocationUpdatesDeliveryStatus? {
        get {
            guard case let .gotLocationUpdatesDeliveryStatus(associatedValue0) = self else { return nil }
            return (associatedValue0)
        }
        set {
            guard case .gotLocationUpdatesDeliveryStatus = self, let newValue = newValue else { return }
            self = .gotLocationUpdatesDeliveryStatus(newValue)
        }
    }

    public var isGotLocationUpdatesDeliveryStatus: Bool {
        self.gotLocationUpdatesDeliveryStatus != nil
    }

    public var gotRegionBeingMonitored: CLRegion? {
        get {
            guard case let .gotRegionBeingMonitored(associatedValue0) = self else { return nil }
            return (associatedValue0)
        }
        set {
            guard case .gotRegionBeingMonitored = self, let newValue = newValue else { return }
            self = .gotRegionBeingMonitored(newValue)
        }
    }

    public var isGotRegionBeingMonitored: Bool {
        self.gotRegionBeingMonitored != nil
    }

    public var gotAuthzStatus: AuthzStatus? {
        get {
            guard case let .gotAuthzStatus(associatedValue0) = self else { return nil }
            return (associatedValue0)
        }
        set {
            guard case .gotAuthzStatus = self, let newValue = newValue else { return }
            self = .gotAuthzStatus(newValue)
        }
    }

    public var isGotAuthzStatus: Bool {
        self.gotAuthzStatus != nil
    }

    public var gotDeviceCapabilities: DeviceCapabilities? {
        get {
            guard case let .gotDeviceCapabilities(associatedValue0) = self else { return nil }
            return (associatedValue0)
        }
        set {
            guard case .gotDeviceCapabilities = self, let newValue = newValue else { return }
            self = .gotDeviceCapabilities(newValue)
        }
    }

    public var isGotDeviceCapabilities: Bool {
        self.gotDeviceCapabilities != nil
    }

    public var gotLocationServiceConfiguration: LocationServiceConfiguration? {
        get {
            guard case let .gotLocationServiceConfiguration(associatedValue0) = self else { return nil }
            return (associatedValue0)
        }
        set {
            guard case .gotLocationServiceConfiguration = self, let newValue = newValue else { return }
            self = .gotLocationServiceConfiguration(newValue)
        }
    }

    public var isGotLocationServiceConfiguration: Bool {
        self.gotLocationServiceConfiguration != nil
    }

    public var gotHeadingServiceConfiguration: HeadingServiceConfiguration? {
        get {
            guard case let .gotHeadingServiceConfiguration(associatedValue0) = self else { return nil }
            return (associatedValue0)
        }
        set {
            guard case .gotHeadingServiceConfiguration = self, let newValue = newValue else { return }
            self = .gotHeadingServiceConfiguration(newValue)
        }
    }

    public var isGotHeadingServiceConfiguration: Bool {
        self.gotHeadingServiceConfiguration != nil
    }

    public var gotRegionMonitoringServiceConfiguration: RegionMonitoringServiceConfiguration? {
        get {
            guard case let .gotRegionMonitoringServiceConfiguration(associatedValue0) = self else { return nil }
            return (associatedValue0)
        }
        set {
            guard case .gotRegionMonitoringServiceConfiguration = self, let newValue = newValue else { return }
            self = .gotRegionMonitoringServiceConfiguration(newValue)
        }
    }

    public var isGotRegionMonitoringServiceConfiguration: Bool {
        self.gotRegionMonitoringServiceConfiguration != nil
    }

    public var gotBeaconRangingConstraints: Set<CLBeaconIdentityConstraint>? {
        get {
            guard case let .gotBeaconRangingConstraints(associatedValue0) = self else { return nil }
            return (associatedValue0)
        }
        set {
            guard case .gotBeaconRangingConstraints = self, let newValue = newValue else { return }
            self = .gotBeaconRangingConstraints(newValue)
        }
    }

    public var isGotBeaconRangingConstraints: Bool {
        self.gotBeaconRangingConstraints != nil
    }

    public var receiveError: Error? {
        get {
            guard case let .receiveError(associatedValue0) = self else { return nil }
            return (associatedValue0)
        }
        set {
            guard case .receiveError = self, let newValue = newValue else { return }
            self = .receiveError(newValue)
        }
    }

    public var isReceiveError: Bool {
        self.receiveError != nil
    }

}
