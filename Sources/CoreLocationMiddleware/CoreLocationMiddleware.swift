import CoreLocation
import SwiftRex

public struct LocationState: Equatable {
    var authzType: AuthzType
    var authzStatus: CLAuthorizationStatus
    var authzAccuracy: AuthzAccuracy
    var location: CLLocation
    
    public init(authzType: AuthzType = .whenInUse,
                authzStatus: CLAuthorizationStatus,
                authzAccuracy: AuthzAccuracy = .undefined,
                location: CLLocation) {
        self.authzType = authzType
        self.authzStatus = authzStatus
        self.authzAccuracy = authzAccuracy
        self.location = location
    }
}

public enum LocationAction {
    // Input
    case startMonitoring
    case stopMonitoring
    case requestAuthorizationStatus
    case requestAuthorizationType
    case requestPosition
    case requestDeviceCapabilities
    // Output
    case gotPosition(CLLocation)
    case gotAuthzStatus(AuthzStatus)
    case gotDeviceCapabilities(DeviceCapabilities)
    case receiveError(Error)
}

public enum AuthzType: Equatable {
    case whenInUse
    case always
}

public struct AuthzStatus: Equatable {
    public let status : CLAuthorizationStatus
    public let accuracy: AuthzAccuracy
}

public enum AuthzAccuracy: Equatable {
    case defined(CLAccuracyAuthorization)
    case undefined
}

public struct DeviceCapabilities: Equatable {
    public let isSignificantLocationChangeAvailable: Bool
    public let isHeadingAvailable: Bool
    public let isRegionMonitoringAvailable: Bool
    public let isRangingAvailable: Bool
    public let isLocationServiceAvailable: Bool
}


let locationReducer = Reducer<LocationAction, LocationState> { action, state in
    var state = state
    switch action {
    case .startMonitoring,
         .stopMonitoring,
         .requestAuthorizationStatus,
         .requestAuthorizationType,
         .requestPosition,
         .requestDeviceCapabilities:
        break
    case let .gotAuthzStatus(status):
        state.authzStatus = status.status
        state.authzAccuracy = status.accuracy
    case let .gotPosition(position): state.location = position
    case .gotDeviceCapabilities, .receiveError : break
    }

    return state
}

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
        case .startMonitoring: startMonitoring()
        case .stopMonitoring: stopMonitoring()
        case .requestAuthorizationStatus:
            if #available(iOS 14.0, *) {
                delegate.output?.dispatch(
                    getAuthzStatus(
                        status: manager.authorizationStatus,
                        accuracy: .defined(manager.accuracyAuthorization)
                    )
                )
            } else {
                delegate.output?.dispatch(
                    getAuthzStatus(
                        status: CLLocationManager.authorizationStatus(),
                        accuracy: .undefined
                    )
                )
            }
        case .requestAuthorizationType:
            switch getState?().authzType {
            case .always:
                manager.requestAlwaysAuthorization()
            case .whenInUse:
                manager.requestWhenInUseAuthorization()
            case .none:
                break
            }
        case .requestPosition: manager.requestLocation()
        case .requestDeviceCapabilities: delegate.output?.dispatch(getDeviceCapabilities())
        default: return
        }
    }
    
    func startMonitoring() {
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
    
    func stopMonitoring() {
        manager.stopUpdatingLocation()
    }
    
    func getDeviceCapabilities() -> LocationAction {
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

class CLDelegate: NSObject, CLLocationManagerDelegate {
    
    var output: AnyActionHandler<LocationAction>? = nil

    @available(iOS 14.0, *)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        output?.dispatch(
            getAuthzStatus(
                status: manager.authorizationStatus,
                accuracy: .defined(manager.accuracyAuthorization)
            )
        )
    }

    @available(iOS, introduced: 4.2, deprecated: 14.0)
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        output?.dispatch(
            getAuthzStatus(
                status: status,
                accuracy: .undefined
            )
        )
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let last = locations.last else { return }
        output?.dispatch(.gotPosition(last))
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        output?.dispatch(.receiveError(error))
    }
}

private func getAuthzStatus(status: CLAuthorizationStatus, accuracy: AuthzAccuracy) -> LocationAction {
    switch status {
    case .authorizedAlways, .authorizedWhenInUse, .denied, .restricted, .notDetermined:
        return .gotAuthzStatus(AuthzStatus(status: status, accuracy: accuracy))
    @unknown default:
        return .receiveError(CLError(.denied, userInfo: ["Unknown status": "The authorization status provided is unknown."]))
    }
}
