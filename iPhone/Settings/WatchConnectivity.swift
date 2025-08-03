import Foundation
import WatchConnectivity
import Combine

final class WatchConnectivityManager: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()

    private let session = WCSession.default
    private var cancellables = Set<AnyCancellable>()
    private let outgoing = PassthroughSubject<[String:Any], Never>()
    private var lastPayload = Data()

    private override init() {
        super.init()
        guard WCSession.isSupported() else { return }

        session.delegate = self
        session.activate()

        outgoing
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] snapshot in
                guard let self else { return }
                Task { await self.push(snapshot) }
            }
            .store(in: &cancellables)
    }
    
    func queue(message: [String:Any]) { outgoing.send(message) }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error { logger.debug("WC activation failed: \(error)") }
        logger.debug("WC activation → \(activationState.rawValue)")
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }
    #endif

    func session(_ session: WCSession, didReceiveMessage msg: [String : Any]) {
        applyIfSettings(msg)
    }

    func session(_ session: WCSession, didReceiveApplicationContext ctx: [String : Any]) {
        applyIfSettings(ctx)
    }

    private func session(_ session: WCSession, didReceiveUserInfo info: [String : Any] = [:]) async {
        applyIfSettings(info)
    }

    private func push(_ payload: [String:Any]) async {
        guard let data = try? JSONSerialization.data(withJSONObject: payload), data != lastPayload else { return }
        lastPayload = data

        do { try session.updateApplicationContext(payload) }
        catch { logger.debug("WC updateApplicationContext error: \(error)") }

        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil) { err in
                logger.debug("WC sendMessage error: \(err.localizedDescription)")
            }
            return
        }

        _ = session.transferUserInfo(payload)
    }

    private func applyIfSettings(_ dict: [String:Any]) {
        guard let s = dict["settings"] as? [String:Any] else { return }
        Task { @MainActor in Settings.shared.update(from: s) }
    }
}
