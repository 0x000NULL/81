import Foundation
import CloudKit
import CoreData
import OSLog

private let log = Logger(subsystem: "app.81", category: "cloudkit")

/// Live status of the CloudKit private database backing the SwiftData
/// container. Surfaces account state and the most recent sync event so
/// the Settings UI can show a meaningful indicator.
@MainActor
@Observable
final class CloudKitStatusService {
    static let shared = CloudKitStatusService()

    enum AccountStatus: Equatable {
        case unknown
        case available
        case noAccount
        case restricted
        case unavailable

        var label: String {
            switch self {
            case .unknown: "Checking iCloud…"
            case .available: "Connected"
            case .noAccount: "Signed out of iCloud"
            case .restricted: "iCloud restricted on this device"
            case .unavailable: "iCloud unavailable"
            }
        }
    }

    var accountStatus: AccountStatus = .unknown
    var lastSyncDate: Date?
    var lastEventDescription: String?

    private var eventObserver: NSObjectProtocol?

    private init() {
        eventObserver = NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let event = note.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                as? NSPersistentCloudKitContainer.Event,
                  let endDate = event.endDate
            else { return }
            let typeDescription: String
            switch event.type {
            case .setup: typeDescription = "Setup"
            case .import: typeDescription = "Import"
            case .export: typeDescription = "Export"
            @unknown default: typeDescription = "Sync"
            }
            Task { @MainActor [weak self] in
                self?.lastSyncDate = endDate
                self?.lastEventDescription = typeDescription
            }
        }
        Task { await refreshAccountStatus() }
    }

    // Singleton lives for the app lifetime; observer never needs cleanup.

    func refreshAccountStatus() async {
        do {
            let status = try await CKContainer(identifier: AppModelContainer.cloudKitContainerID).accountStatus()
            accountStatus = mapped(status)
        } catch {
            log.warning("CKContainer.accountStatus failed: \(String(describing: error))")
            accountStatus = .unavailable
        }
    }

    private func mapped(_ status: CKAccountStatus) -> AccountStatus {
        switch status {
        case .available: .available
        case .noAccount: .noAccount
        case .restricted: .restricted
        case .couldNotDetermine, .temporarilyUnavailable: .unavailable
        @unknown default: .unknown
        }
    }
}
