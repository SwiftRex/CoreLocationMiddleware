import CoreLocation
import SwiftRex

public enum LocationState {
    case unknown
    case notAuthorized
    case authorized(lastPosition: CLLocation?)
}

public enum LocationAction {
    // Input
    case startMonitoring(AuthorizationRequest)
    case stopMonitoring
    case getAuthorizationStatus
    case requestAuthorization(AuthorizationRequest)
    // Output
    case gotPosition(CLLocation)
    case authorized
    case unauthorized
    case authorizationUnknown
    case receiveError(Error)
    
    public enum AuthorizationRequest: Equatable {
        case whenInUse
        case always
    }
}

extension LocationAction: Equatable {
    public static func == (lhs: LocationAction, rhs: LocationAction) -> Bool {
        switch (lhs, rhs) {
        case let (.receiveError(x), .receiveError(y)): return x.localizedDescription == y.localizedDescription
        case let (.gotPosition(x), .gotPosition(y)): return x == y
        case let (.requestAuthorization(x), .requestAuthorization(y)),
            let (.startMonitoring(x), .startMonitoring(y)): return x == y
        case (.stopMonitoring, .stopMonitoring), (.authorized, .authorized), (.unauthorized, .unauthorized), (.authorizationUnknown, .authorizationUnknown), (.getAuthorizationStatus, .getAuthorizationStatus) : return true
        default:
            return false
        }
    }
}

let locationReducer = Reducer<LocationAction, LocationState> { action, state in
    var state = state
    switch action {
    case .startMonitoring, .stopMonitoring, .getAuthorizationStatus, .requestAuthorization:
        break
    case .authorized:
        if case .authorized = state { return state }
        state = .authorized(lastPosition: nil)
    case let .gotPosition(position):
        state = .authorized(lastPosition: position)
    case .unauthorized:
        state = .notAuthorized
    case .authorizationUnknown:
        state = .unknown
    case .receiveError:
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
    func startMonitoring(with auth: LocationAction.AuthorizationRequest) {
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
        output?.dispatch(.receiveError(error))
    }
}

@available(iOS 14.0, *)
private func getAuthzStatus(status: CLAuthorizationStatus) -> LocationAction {
    switch status {
    case .authorizedAlways, .authorizedWhenInUse:
        return .authorized
    case  .denied, .restricted:
        return .unauthorized
    default:
        return .authorizationUnknown
    }
    
}
