# CoreLocationMiddleware

This is a [Middleware](https://github.com/SwiftRex/SwiftRex#middleware) for [SwiftRex](https://github.com/SwiftRex/SwiftRex) which acts as a [CoreLocation](https://developer.apple.com/documentation/corelocation) delegate.

## Current features implemented

The middleware plugin currently provides the following features : 
* start / stop standard (as opposed to significant location change) location monitoring.
* listens to [location updates](https://developer.apple.com/documentation/corelocation/cllocationmanagerdelegate/1423615-locationmanager) from the CLLocationManager delegate and dispatches the CLLocation data back to the store
* listens to [authorization changes](https://developer.apple.com/documentation/corelocation/cllocationmanagerdelegate/3563956-locationmanagerdidchangeauthoriz) from the CLLocationManager delegate and dispatches the authorization status back to the store

## Future enhancements

The following additions are expected : 
* support for region monitoring
* support for iBeacon ranging
* support for visit-related events
* support for heading updates
* support for significant location changes (SLC)

# Companion product

We've made available a companion application to test the features provided by CoreLocationMiddleware : 
https://github.com/npvisual/CoreLocation-Redux
