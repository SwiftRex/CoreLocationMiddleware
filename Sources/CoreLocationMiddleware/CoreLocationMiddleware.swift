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
}

public enum StatusAction {
    case gotPosition(CLLocation)
    case gotAuthzStatus(AuthzStatus)
    case gotDeviceCapabilities(DeviceCapabilities)
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
    
    public init(authzType: AuthzType = .whenInUse,
                authzStatus: CLAuthorizationStatus,
                authzAccuracy: CLAccuracyAuthorization? = .none,
                location: CLLocation) {
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
        case .gotDeviceCapabilities, .receiveError : break
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
        manager.delegate = delegate
    }
    
    public func handle(action: LocationAction, from dispatcher: ActionSource, afterReducer: inout AfterReducer) {
        switch action {
        case .request(let .start(type)):
            switch type {
            case .locationMonitoring: startLocationMonitoring()
            case .slcMonitoring: manager.startMonitoringSignificantLocationChanges()
            default: return
            }
        case .request(let .stop(type)):
            switch type {
            case .locationMonitoring: stopLocationMonitoring()
            case .slcMonitoring: manager.stopMonitoringSignificantLocationChanges()
            default: return
            }
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
        case .request(.requestDeviceCapabilities): delegate.output?.dispatch(.status(getDeviceCapabilities()))
        default: return
        }
    }
}

extension CoreLocationMiddleware {
    func startLocationMonitoring() {
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
        manager.startUpdatingLocation()
    }
    
    func stopLocationMonitoring() {
        manager.stopUpdatingLocation()
    }
    
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

extension CoreLocationMiddleware {
    
}

// MARK: - DELEGATE
class CLDelegate: NSObject, CLLocationManagerDelegate {
    
    var output: AnyActionHandler<LocationAction>? = nil

    @available(iOS 14.0, *)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        output?.dispatch(
            LocationAction.status(
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
            LocationAction.status(
                getAuthzStatus(
                    status: status,
                    accuracy: .none
                )
            )
        )
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let last = locations.last else { return }
        output?.dispatch(LocationAction.status(.gotPosition(last)))
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        output?.dispatch(LocationAction.status(.receiveError(error)))
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
