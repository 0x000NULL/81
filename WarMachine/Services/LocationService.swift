import Foundation
import CoreLocation
import OSLog

private let log = Logger(subsystem: "app.81", category: "location")

@MainActor
final class LocationService: NSObject {
    private let manager = CLLocationManager()
    private(set) var distanceMi: Double = 0
    private var lastLocation: CLLocation?
    private var continuation: AsyncStream<Double>.Continuation?

    let distanceStream: AsyncStream<Double>

    override init() {
        var cont: AsyncStream<Double>.Continuation!
        self.distanceStream = AsyncStream { cont = $0 }
        self.continuation = cont
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = 5
        manager.activityType = .fitness
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
    }

    func requestWhenInUse() {
        manager.requestWhenInUseAuthorization()
    }

    func escalateToAlways() {
        manager.requestAlwaysAuthorization()
    }

    var authorizationStatus: CLAuthorizationStatus {
        manager.authorizationStatus
    }

    func startTracking() {
        distanceMi = 0
        lastLocation = nil
        manager.startUpdatingLocation()
    }

    func stopTracking() {
        manager.stopUpdatingLocation()
        continuation?.finish()
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            for loc in locations where loc.horizontalAccuracy >= 0 && loc.horizontalAccuracy <= 25 {
                if let last = self.lastLocation {
                    let meters = loc.distance(from: last)
                    let miles = meters / 1609.344
                    self.distanceMi += miles
                    self.continuation?.yield(self.distanceMi)
                }
                self.lastLocation = loc
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        log.error("Location error: \(String(describing: error))")
    }
}
