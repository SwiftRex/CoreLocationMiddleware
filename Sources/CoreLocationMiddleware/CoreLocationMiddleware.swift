import CoreLocation
import SwiftRex


// MARK: - ACTION
public enum LocationAction {
    // Input
    case request(RequestAction)
    // Output
    case status(StatusAction)
}

public enum RequestAction {
    case start(MonitoringType)
    case stop(MonitoringType)
    case requestAuthorizationStatus
    case requestAuthorizationType
    case requestPosition
    case requestDeviceCapabilities
    case requestLocationServiceConfiguration(LocationServiceConfiguration?)
    case requestHeadingServiceConfiguration(HeadingServiceConfiguration?)
    case requestRegionMonitoringServiceConfiguration
    case requestBeaconRangingConstraints
}

public enum StatusAction {
    case gotPosition(CLLocation)
    case gotHeading(CLHeading)
    case gotVisit(CLVisit)
    case gotBeacon([CLBeacon], CLBeaconIdentityConstraint)
    case gotLocationUpdatesDeliveryStatus(LocationUpdatesDeliveryStatus)
    case gotAuthzStatus(AuthzStatus)
    case gotDeviceCapabilities(DeviceCapabilities)
    case gotLocationServiceConfiguration(LocationServiceConfiguration)
    case gotHeadingServiceConfiguration(HeadingServiceConfiguration)
    case gotRegionMonitoringServiceConfiguration(RegionMonitoringServiceConfiguration)
    case gotBeaconRangingConstraints(Set<CLBeaconIdentityConstraint>)
    case receiveError(Error)
}

public enum MonitoringType {
    case locationMonitoring
    case slcMonitoring
    case headingUpdates
    case regionMonitoring(CLRegion)
    case beaconRanging(CLBeaconIdentityConstraint)
    case visitMonitoring
}

// MARK: - STATE
public struct LocationState: Equatable {
    var authzType: AuthzType
    var authzStatus: CLAuthorizationStatus
    var authzAccuracy: CLAccuracyAuthorization?
    var location: CLLocation
    var heading: CLHeading?
    var visit: CLVisit?
    var beacons: [CLBeacon]?
    /// Identity characteristics for the latest array of CLBeacon retrieved via the delegate
    var beaconIdentityConstraints: CLBeaconIdentityConstraint?
    var locationUpdatesDeliveryStatus: LocationUpdatesDeliveryStatus?
    var locationServiceConfig: LocationServiceConfiguration?
    var headingServiceConfig: HeadingServiceConfiguration?
    var regionMonitoringServiceConfiguration: RegionMonitoringServiceConfiguration?
    /// The set of beacon constraints currently being tracked using ranging.
    var rangedBeaconConstraints: Set<CLBeaconIdentityConstraint>?
    
    public init(
        authzType: AuthzType = .whenInUse,
        authzStatus: CLAuthorizationStatus,
        authzAccuracy: CLAccuracyAuthorization? = .none,
        location: CLLocation
    ) {
        self.authzType = authzType
        self.authzStatus = authzStatus
        self.authzAccuracy = authzAccuracy
        self.location = location
    }
}

public enum AuthzType: Equatable {
    case whenInUse
    case always
}

public struct AuthzStatus: Equatable {
    public let status : CLAuthorizationStatus
    public let accuracy: CLAccuracyAuthorization?
}

public struct DeviceCapabilities: Equatable {
    public let isSignificantLocationChangeAvailable: Bool
    public let isHeadingAvailable: Bool
    public let isRegionMonitoringAvailable: Bool
    public let isRangingAvailable: Bool
    public let isLocationServiceAvailable: Bool
}

public struct LocationServiceConfiguration: Equatable {
    public let pausesLocationUpdatesAutomatically: Bool
    public let allowsBackgroundLocationUpdates: Bool
    public let showsBackgroundLocationIndicator: Bool
    public let distanceFilter: CLLocationDistance
    public let desiredAccuracy: CLLocationAccuracy
    public let activityType: CLActivityType
}

public struct HeadingServiceConfiguration: Equatable {
    public let headingFilter: CLLocationDegrees
    public let headingOrientation: CLDeviceOrientation
    public let displayHeadingCalibration: Bool? = nil
}

public struct RegionMonitoringServiceConfiguration: Equatable {
    public let monitoredRegions: Set<CLRegion>
    public let maximumRegionMonitoringDistance: CLLocationDistance
}

public enum LocationUpdatesDeliveryStatus: Equatable {
    case paused
    case resumed
}

// MARK: - REDUCERS

extension Reducer where ActionType == LocationAction, StateType == LocationState {
    static let location = Reducer<StatusAction, LocationState>.status.lift(action: \LocationAction.status)
}

extension Reducer where ActionType == StatusAction, StateType == LocationState {
    static let status = Reducer { action, state in
        var state = state
        switch action {
        case let .gotAuthzStatus(status):
            state.authzStatus = status.status
            state.authzAccuracy = status.accuracy
        case let .gotPosition(position): state.location = position
        case let .gotHeading(heading): state.heading = heading
        case let .gotVisit(visit): state.visit = visit
        case let .gotBeacon(beacons, constraints):
            state.beacons = beacons
            state.beaconIdentityConstraints = constraints
        case let .gotLocationUpdatesDeliveryStatus(status): state.locationUpdatesDeliveryStatus = status
        case let .gotLocationServiceConfiguration(config): state.locationServiceConfig = config
        case let .gotHeadingServiceConfiguration(config): state.headingServiceConfig = config
        case let .gotRegionMonitoringServiceConfiguration(config): state.regionMonitoringServiceConfiguration = config
        case let .gotBeaconRangingConstraints(constraints):
            state.rangedBeaconConstraints = constraints
        case .gotDeviceCapabilities,
             .receiveError: break
        }
        return state
    }
}


// MARK: - MIDDLEWARE
public final class CoreLocationMiddleware: Middleware {
    
    public typealias InputActionType = LocationAction
    public typealias OutputActionType = LocationAction
    public typealias StateType = LocationState
    
    private var getState: GetState<LocationState>?
    private let manager = CLLocationManager()
    private let delegate = CLDelegate()

    public init() { }
    
    public func receiveContext(getState: @escaping GetState<LocationState>, output: AnyActionHandler<LocationAction>) {
        self.getState = getState
        delegate.output = output
        delegate.state = getState()
        manager.delegate = delegate
    }
    
    public func handle(action: LocationAction, from dispatcher: ActionSource, afterReducer: inout AfterReducer) {
        switch action {
        case let .request(.start(type)): startService(service: type)
        case let .request(.stop(type)): stopService(service: type)
        case .request(.requestAuthorizationStatus):
            if #available(iOS 14.0, *) {
                delegate.output?.dispatch(
                    .status(
                        getAuthzStatus(
                            status: manager.authorizationStatus,
                            accuracy: manager.accuracyAuthorization
                        )
                    )
                )
            } else {
                delegate.output?.dispatch(
                    .status(
                        getAuthzStatus(
                            status: CLLocationManager.authorizationStatus(),
                            accuracy: .none
                        )
                    )
                )
            }
        case .request(.requestAuthorizationType):
            switch getState?().authzType {
            case .always:
                manager.requestAlwaysAuthorization()
            case .whenInUse:
                manager.requestWhenInUseAuthorization()
            case .none:
                break
            }
        case .request(.requestPosition): manager.requestLocation()
        case .request(.requestDeviceCapabilities):
            delegate.output?.dispatch(.status(getDeviceCapabilities()))
        case let .request(.requestLocationServiceConfiguration(config)):
            switch config {
            case .none: delegate.output?.dispatch(.status(getLocationServiceConfig()))
            case let .some(config): setLocationServiceConfig(config: config)
            }
        case let .request(.requestHeadingServiceConfiguration(config)):
            switch config {
            case .none: delegate.output?.dispatch(.status(getHeadingServiceConfig()))
            case let .some(config): setHeadingServiceConfig(config: config)
            }
        case .request(.requestRegionMonitoringServiceConfiguration):
            delegate.output?.dispatch(.status(getHeadingServiceConfig()))
        case .request(.requestBeaconRangingConstraints):
            delegate.output?.dispatch(.status(.gotBeaconRangingConstraints(manager.rangedBeaconConstraints)))
        default: return
        }
    }
}

// Service start / stop
extension CoreLocationMiddleware {
    func startService(service: MonitoringType) {
        let stateType = getState?().authzType
        let stateStatus = getState?().authzStatus
        
        switch stateType {
        case .always:
            if CLAuthorizationStatus.authorizedAlways != stateStatus {
                manager.requestAlwaysAuthorization()
            }
        case .whenInUse:
            if ![CLAuthorizationStatus.authorizedAlways, CLAuthorizationStatus.authorizedWhenInUse].contains(stateStatus) {
                manager.requestWhenInUseAuthorization()
            }
        case .none:
            break
        }
        
        switch service {
        case .locationMonitoring: manager.startUpdatingLocation()
        case .slcMonitoring: manager.startMonitoringSignificantLocationChanges()
        case .visitMonitoring: manager.startMonitoringVisits()
        case .headingUpdates: manager.startUpdatingHeading()
        case let .beaconRanging(constraint): manager.startRangingBeacons(satisfying: constraint)
        case let .regionMonitoring(region): manager.startMonitoring(for: region)
        }
    }
    
    func stopService(service: MonitoringType) {
        switch service {
        case .locationMonitoring: manager.stopUpdatingLocation()
        case .slcMonitoring: manager.stopMonitoringSignificantLocationChanges()
        case .visitMonitoring: manager.stopMonitoringVisits()
        case .headingUpdates: manager.stopUpdatingHeading()
        case let .beaconRanging(constraint): manager.stopRangingBeacons(satisfying: constraint)
        case let .regionMonitoring(region): manager.stopMonitoring(for: region)
        }
    }
}

// Device Capabilities
extension CoreLocationMiddleware {
    func getDeviceCapabilities() -> StatusAction {
        .gotDeviceCapabilities(
            DeviceCapabilities(
                isSignificantLocationChangeAvailable: CLLocationManager.significantLocationChangeMonitoringAvailable(),
                isHeadingAvailable: CLLocationManager.headingAvailable(),
                isRegionMonitoringAvailable: CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self),
                isRangingAvailable: CLLocationManager.isRangingAvailable(),
                isLocationServiceAvailable: CLLocationManager.locationServicesEnabled()
            )
        )
    }
}

// Location Service Configuration
extension CoreLocationMiddleware {
    func getLocationServiceConfig() -> StatusAction {
        .gotLocationServiceConfiguration(
            LocationServiceConfiguration(
                pausesLocationUpdatesAutomatically: manager.pausesLocationUpdatesAutomatically,
                allowsBackgroundLocationUpdates: manager.allowsBackgroundLocationUpdates,
                showsBackgroundLocationIndicator: manager.showsBackgroundLocationIndicator,
                distanceFilter: manager.distanceFilter,
                desiredAccuracy: manager.desiredAccuracy,
                activityType: manager.activityType
            )
        )
    }
    
    func setLocationServiceConfig(config: LocationServiceConfiguration) {
        manager.pausesLocationUpdatesAutomatically = config.pausesLocationUpdatesAutomatically
        manager.allowsBackgroundLocationUpdates = config.allowsBackgroundLocationUpdates
        manager.showsBackgroundLocationIndicator = config.showsBackgroundLocationIndicator
        manager.distanceFilter = config.distanceFilter
        manager.desiredAccuracy = config.desiredAccuracy
        manager.activityType = config.activityType
    }
}

// Heading Service Configuration
extension CoreLocationMiddleware {
    func getHeadingServiceConfig() -> StatusAction {
        .gotHeadingServiceConfiguration(
            HeadingServiceConfiguration(
                headingFilter: manager.headingFilter,
                headingOrientation: manager.headingOrientation
            )
        )
    }
    
    func setHeadingServiceConfig(config: HeadingServiceConfiguration) {
        manager.headingFilter = config.headingFilter
        manager.headingOrientation = config.headingOrientation
    }
}

// Region Monitoring Service Configuration (getter only)
extension CoreLocationMiddleware {
    func getRegionMonitoringServiceConfig() -> StatusAction {
        .gotRegionMonitoringServiceConfiguration(
            RegionMonitoringServiceConfiguration(
                monitoredRegions: manager.monitoredRegions,
                maximumRegionMonitoringDistance: manager.maximumRegionMonitoringDistance
            )
        )
    }
}

// MARK: - DELEGATE
class CLDelegate: NSObject, CLLocationManagerDelegate {
    
    var output: AnyActionHandler<LocationAction>? = nil
    var state: LocationState? = nil

    @available(iOS 14.0, *)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        output?.dispatch(
            .status(
                getAuthzStatus(
                    status: manager.authorizationStatus,
                    accuracy: manager.accuracyAuthorization
                )
            )
        )
    }

    @available(iOS, introduced: 4.2, deprecated: 14.0)
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        output?.dispatch(
            .status(
                getAuthzStatus(
                    status: status,
                    accuracy: .none
                )
            )
        )
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let last = locations.last else { return }
        output?.dispatch(.status(.gotPosition(last)))
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        output?.dispatch(.status(.gotHeading(newHeading)))
    }
    
    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        // We default to not showing the calibration display unless it's been set
        // in the Heading Service configuration.
        state?.headingServiceConfig?.displayHeadingCalibration ?? false
    }
    
    func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint) {
        output?.dispatch(.status(.gotBeacon(beacons, beaconConstraint)))
    }
    
    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        output?.dispatch(.status(.gotLocationUpdatesDeliveryStatus(.paused)))
    }
    
    func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        output?.dispatch(.status(.gotLocationUpdatesDeliveryStatus(.resumed)))
    }
    
    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        output?.dispatch(.status(.gotVisit(visit)))
    }
    
    func locationManager(_ manager: CLLocationManager, didFailRangingFor beaconConstraint: CLBeaconIdentityConstraint, error: Error) {
        // TODO: maybe add an additional field to report the constraints for which
        // the ranging failed.
        output?.dispatch(.status(.receiveError(error)))
    }
    func locationManager(_ manager: CLLocationManager, didFinishDeferredUpdatesWithError error: Error?) {
        guard let error = error else { return }
        output?.dispatch(.status(.receiveError(error)))
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        output?.dispatch(.status(.receiveError(error)))
    }
}

// MARK: - HELPERS
private func getAuthzStatus(status: CLAuthorizationStatus, accuracy: CLAccuracyAuthorization?) -> StatusAction {
    switch status {
    case .authorizedAlways, .authorizedWhenInUse, .denied, .restricted, .notDetermined:
        return .gotAuthzStatus(AuthzStatus(status: status, accuracy: accuracy))
    @unknown default:
        return .receiveError(CLError(.denied, userInfo: ["Unknown status": "The authorization status provided is unknown."]))
    }
}

// MARK: - PRISM
extension LocationAction {
    public var status: StatusAction? {
        get {
            guard case let .status(value) = self else { return nil }
            return value
        }
        set {
            guard case .status = self, let newValue = newValue else { return }
            self = .status(newValue)
        }
    }

    public var isStatusAction: Bool {
        self.status != nil
    }
}
