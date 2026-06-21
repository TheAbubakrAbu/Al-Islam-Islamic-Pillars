import Foundation
import WatchConnectivity
import Combine

/// Two-way settings sync between iPhone and Apple Watch.
///
/// Designed to avoid the failure modes the previous version had:
/// - **Complete snapshots only.** Every message carries the full set of synced settings, and the receiver
///   only writes keys that are present — so a payload can never reset an unmentioned setting to a default
///   (that was the cause of settings randomly flipping on/off).
/// - **Monotonic versioning + device tiebreak.** Each payload carries a score = version·10 + deviceRank
///   (iPhone outranks the watch). A device applies an incoming payload only if its score beats everything
///   it has already sent or applied, so simultaneous edits converge deterministically instead of ping-ponging.
/// - **Echo suppression.** After applying a remote snapshot we remember its serialized form, so the local
///   change it triggers doesn't get sent straight back.
/// - **Reliable channel.** Uses `updateApplicationContext` (always delivered, latest-state-wins) plus an
///   immediate `sendMessage` when reachable; duplicates are harmless because of the score check.
final class WatchConnectivityManager: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()

    private let session = WCSession.default
    private var cancellables = Set<AnyCancellable>()

    /// Local persistent store (per-device; app groups don't sync across devices). Persisting the sync
    /// bookkeeping is what prevents a stale `applicationContext` from being re-applied over a newer local
    /// change on relaunch — the "change a setting, reopen, it reverts" bug.
    private let store: UserDefaults
    private static let scoreKey = "watchSync.knownMaxScore"
    private static let lastSyncedKey = "watchSync.lastSyncedSettingsData"

    /// Serialized form of the settings dict we last sent or applied — used to skip no-op/echo sends.
    private var lastSyncedSettingsData: Data {
        didSet { store.set(lastSyncedSettingsData, forKey: Self.lastSyncedKey) }
    }
    /// Highest score (version·10 + rank) we've sent or applied. Drives versioning and conflict resolution.
    /// Persisted so a relaunch doesn't forget it and re-accept an already-superseded payload.
    private var knownMaxScore: Int {
        didSet { store.set(knownMaxScore, forKey: Self.scoreKey) }
    }

    #if os(iOS)
    private let deviceRank = 1   // iPhone wins ties
    #else
    private let deviceRank = 0
    #endif

    private override init() {
        let store = UserDefaults(suiteName: AppIdentifiers.appGroupSuiteName) ?? .standard
        self.store = store
        self.knownMaxScore = store.integer(forKey: Self.scoreKey)
        self.lastSyncedSettingsData = store.data(forKey: Self.lastSyncedKey) ?? Data()
        super.init()
        guard WCSession.isSupported() else { return }

        session.delegate = self
        session.activate()

        // Push a fresh full snapshot shortly after any settings change (debounced to batch rapid edits).
        Settings.shared.objectWillChange
            .debounce(for: .milliseconds(400), scheduler: DispatchQueue.main)
            .sink { [weak self] in self?.sendSnapshotIfChanged() }
            .store(in: &cancellables)
    }

    // MARK: - Sending

    /// Sends any pending local change immediately, bypassing the debounce. Call when the app is about to be
    /// backgrounded so a just-made change isn't lost if the app is suspended before the debounce fires.
    @MainActor func flushPendingSync() {
        sendSnapshotIfChanged()
    }

    private func sendSnapshotIfChanged() {
        guard session.activationState == .activated else { return }

        let snapshot = Settings.shared.watchSyncSnapshot()
        guard let data = try? JSONSerialization.data(withJSONObject: snapshot, options: [.sortedKeys]) else { return }
        guard data != lastSyncedSettingsData else { return }   // no real change, or an echo of what we just applied
        lastSyncedSettingsData = data

        let version = knownMaxScore / 10 + 1
        let score = version * 10 + deviceRank
        knownMaxScore = max(knownMaxScore, score)

        let payload: [String: Any] = ["score": score, "settings": snapshot]

        do { try session.updateApplicationContext(payload) }
        catch { logger.debug("WC updateApplicationContext error: \(error)") }

        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil) { err in
                logger.debug("WC sendMessage error: \(err.localizedDescription)")
            }
        }
    }

    // MARK: - Receiving

    private func receive(_ payload: [String: Any]) {
        guard let score = payload["score"] as? Int,
              let settings = payload["settings"] as? [String: Any] else { return }
        // Only accept payloads that are strictly newer than anything we've sent or applied.
        guard score > knownMaxScore else { return }
        knownMaxScore = score

        // Remember the applied content so the change it triggers locally isn't echoed back.
        if let data = try? JSONSerialization.data(withJSONObject: settings, options: [.sortedKeys]) {
            lastSyncedSettingsData = data
        }

        Task { @MainActor in
            Settings.shared.applyWatchSyncSnapshot(settings)
        }
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error { logger.debug("WC activation failed: \(error)") }
        logger.debug("WC activation → \(activationState.rawValue)")

        // Apply any context that arrived while we were inactive (rejected if not strictly newer than what
        // we already know), then push any local change that wasn't sent before — between them, the latest
        // value always wins and both devices converge regardless of who was open when.
        if activationState == .activated {
            if !session.receivedApplicationContext.isEmpty {
                receive(session.receivedApplicationContext)
            }
            DispatchQueue.main.async { [weak self] in self?.sendSnapshotIfChanged() }
        }

        #if os(watchOS)
        // Now that we know whether the iPhone app is installed, (re)schedule prayer notifications
        // on the watch if it needs to handle them itself.
        if activationState == .activated {
            Task { @MainActor in
                Settings.shared.fetchPrayerTimes()
            }
        }
        #endif
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }
    #endif

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async { self.receive(message) }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async { self.receive(applicationContext) }
    }
}
