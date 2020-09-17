import CoreLocation
import SwiftRex

public enum LocationState {
    case unknown
    case notAuthorized
    case authorized(lastPosition: CLLocation?)
}

public enum LocationAction: Equatable {
    // Input
    case startMonitoring(AuthzType)
    case stopMonitoring
    case getAuthorizationStatus
    case requestAuthorization(AuthzType)
    // Output
    case gotPosition(CLLocation)
    case gotAuthzStatus(CLAuthorizationStatus)
    case receiveError(CLError)
    
    public enum AuthzType: Equatable {
        case whenInUse
        case always
    }
}

let locationReducer = Reducer<LocationAction, LocationState> { action, state in
    var state = state
    switch action {
    case .startMonitoring, .stopMonitoring, .getAuthorizationStatus, .requestAuthorization:
        break
    case .gotAuthzStatus(.authorizedAlways),
         .gotAuthzStatus(.authorizedWhenInUse):
        if case .authorized = state { return state }
        state = .authorized(lastPosition: nil)
    case .gotAuthzStatus(.denied),
         .gotAuthzStatus(.restricted):
        state = .notAuthorized
    case .gotAuthzStatus(.notDetermined):
        state = .unknown
    case let .gotPosition(position):
        state = .authorized(lastPosition: position)
    case .receiveError,
         .gotAuthzStatus(_):
        break
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
        case let .startMonitoring(auth): startMonitoring(with: auth)
        case .stopMonitoring: stopMonitoring()
        case .getAuthorizationStatus:
            if #available(iOS 14.0, *) {
                delegate.output?.dispatch(getAuthzStatus(status: manager.authorizationStatus))
            } else {
                return
            }
        case let .requestAuthorization(value):
            switch value {
            case .always:
                manager.requestAlwaysAuthorization()
            case .whenInUse:
                manager.requestWhenInUseAuthorization()
            }
        default: return
        }
    }
    func startMonitoring(with auth: LocationAction.AuthzType) {
        switch getState?() {
        case .authorized?:
            manager.startUpdatingLocation()
        default:
            // requestAlwaysAuthorization or requestWhenInUseAuthorization could be decided on
            // the middleware init or as payload for startMonitoring
            auth == .always ? manager.requestAlwaysAuthorization() : manager.requestWhenInUseAuthorization()
            manager.startUpdatingLocation()
        }
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

@available(iOS 14.0, *)
private func getAuthzStatus(status: CLAuthorizationStatus) -> LocationAction {
    switch status {
    case .authorizedAlways, .authorizedWhenInUse, .denied, .restricted, .notDetermined:
        return .gotAuthzStatus(status)
    @unknown default:
        return .receiveError(CLError(.denied, userInfo: ["Unknown status": "The authorization status provided is unknown."]))
    }
    
}
