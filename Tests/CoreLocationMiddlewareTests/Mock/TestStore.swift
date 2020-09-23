//
//  File.swift
//  
//
//  Created by Nicolas Philippe on 9/14/20.
//

import Foundation
import CoreLocation

@testable import SwiftRex
@testable import CoreLocationMiddleware

struct TestState: Equatable {
    var value = UUID()
    var name = ""
}

struct AppState: Equatable {
    let testState: TestState
    var list: [Item]

    struct Item: Equatable, Identifiable {
        let id: Int
        let name: String
    }
}

class TestStore {
    var state: LocationState = LocationState(authzStatus: .notDetermined, location: CLLocation())
    var actionsReceived: [LocationAction] = [.stopMonitoring]

    var getState: (() -> LocationState)!
    var actionHandler: AnyActionHandler<LocationAction>!

    init() {
        actionHandler = .init { action, _ in
            self.actionsReceived.append(action)
        }
        getState = { self.state }
    }
}
