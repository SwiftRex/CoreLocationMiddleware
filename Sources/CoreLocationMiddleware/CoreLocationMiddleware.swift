import CoreLocation
import SwiftRex

public struct LocationState: Equatable {
    var authzType: AuthzType = .whenInUse
    var authzStatus: CLAuthorizationStatus
    var location: CLLocation
    
    public init(authzType: AuthzType, authzStatus: CLAuthorizationStatus, location: CLLocation) {
        self.authzType = authzType
        self.authzStatus = authzStatus
        self.location = location
    }
}

public enum LocationAction: Equatable {
    // Input
    case startMonitoring
    case stopMonitoring
    case requestAuthorizationStatus
    case requestAuthorizationType
    case requestPosition
    // Output
    case gotPosition(CLLocation)
    case gotAuthzStatus(CLAuthorizationStatus)
    case receiveError(CLError)
}

public enum AuthzType: Equatable {
    case whenInUse
    case always
}


let locationReducer = Reducer<LocationAction, LocationState> { action, state in
    var state = state
    switch action {
    case .startMonitoring,
         .stopMonitoring,
         .requestAuthorizationStatus,
         .requestAuthorizationType,
         .requestPosition:
        break
    case let .gotAuthzStatus(status): state.authzStatus = status
    case let .gotPosition(position): state.location = position
    case .receiveError : break
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
                delegate.output?.dispatch(getAuthzStatus(status: manager.authorizationStatus))
            } else {
                return
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
}

class CLDelegate: NSObject, CLLocationManagerDelegate {
    
    var output: AnyActionHandler<LocationAction>? = nil
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if #available(iOS 14.0, *) {
            output?.dispatch(getAuthzStatus(status: status))
        } else {
            return
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let last = locations.last else { return }
        output?.dispatch(.gotPosition(last))
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        output?.dispatch(.receiveError(error as! CLError))
    }
}

private func getAuthzStatus(status: CLAuthorizationStatus) -> LocationAction {
    switch status {
    case .authorizedAlways, .authorizedWhenInUse, .denied, .restricted, .notDetermined:
        return .gotAuthzStatus(status)
    @unknown default:
        return .receiveError(CLError(.denied, userInfo: ["Unknown status": "The authorization status provided is unknown."]))
    }
}
