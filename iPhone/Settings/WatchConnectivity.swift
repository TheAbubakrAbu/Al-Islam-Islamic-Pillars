import WatchConnectivity

class WatchConnectivityManager: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()
    
    private override init() {
        super.init()
        
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        switch activationState {
        case .activated:
            print("WCSession is activated.")
        case .inactive:
            print("WCSession is inactive.")
        case .notActivated:
            print("WCSession is not activated.")
        @unknown default:
            print("Unknown WCSession activation state.")
        }

        if let error = error {
            print("WCSession activation failed with error: \(error.localizedDescription)")
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("Received message from iPhone: \(message)")

        DispatchQueue.main.async {
            if let settingsDict = message["settings"] as? [String: Any] {
                print("Updating settings from: \(settingsDict)")
                Settings.shared.update(from: settingsDict)
                print("Updated settings: \(Settings.shared.dictionaryRepresentation())")
            }
        }
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {}
    #endif
}
