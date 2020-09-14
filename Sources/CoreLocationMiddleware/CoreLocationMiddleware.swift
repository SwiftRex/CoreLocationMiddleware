import CoreLocation
import SwiftRex

enum LocationState {
    case unknown
    case notAuthorized
    case authorized(lastPosition: CLLocation?)
}

enum LocationAction {
    case startMonitoring
    case stopMonitoring
    case gotPosition(CLLocation)
    case authorized
    case unauthorized
    case authorizationUnknown
    case receiveError(Error)
}

extension LocationAction: Equatable {
    static func == (lhs: LocationAction, rhs: LocationAction) -> Bool {
        switch (lhs, rhs) {
        case let (.receiveError(x), .receiveError(y)): return x.localizedDescription == y.localizedDescription
        case let (.gotPosition(x), .gotPosition(y)): return x == y
        case (.startMonitoring, .startMonitoring), (.stopMonitoring, .stopMonitoring), (.authorized, .authorized), (.unauthorized, .unauthorized), (.authorizationUnknown, .authorizationUnknown) : return true
        default:
            return false
        }
    }
}

let locationReducer = Reducer<LocationAction, LocationState> { action, state in
    var state = state
    switch action {
    case .authorized:
        if case .authorized = state { return state }
        state = .authorized(lastPosition: nil)
    case .startMonitoring, .stopMonitoring:
        break
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

class CoreLocationMiddleware: NSObject, Middleware {
    private var getState: GetState<LocationState>?
    private var output: AnyActionHandler<LocationAction>?
    private let manager = CLLocationManager()

    func receiveContext(getState: @escaping GetState<LocationState>, output: AnyActionHandler<LocationAction>) {
        self.getState = getState
        self.output = output
        manager.delegate = self
    }
    func handle(action: LocationAction, from dispatcher: ActionSource, afterReducer: inout AfterReducer) {
        switch action {
        case .startMonitoring, .authorized:
            startMonitoring()
        case .stopMonitoring:
            stopMonitoring()
        default: return
        }
    }
    func startMonitoring() {
        switch getState?() {
        case .authorized?:
            manager.startUpdatingLocation()
        default:
            // requestAlwaysAuthorization or requestWhenInUseAuthorization could be decided on
            // the middleware init or as payload for startMonitoring
            manager.requestAlwaysAuthorization()
        }
    }
    func stopMonitoring() {
        manager.stopUpdatingLocation()
    }
}

extension CoreLocationMiddleware: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            output?.dispatch(.authorizationUnknown)
        case .denied, .restricted:
            output?.dispatch(.unauthorized)
        case .authorizedAlways, .authorizedWhenInUse:
            output?.dispatch(.authorized)
        @unknown default:
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
