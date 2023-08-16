import Foundation
import Security

class ClipboardMonitor: NSObject {
    private var clipboard = NSPasteboard.general
    private var keyGenerator: Timer!
    private var currentKey: [UInt8] = []

    override init() {
        super.init()

        clipboard.addObserver(self, forKeyPath: "changeCount", options: .new, context: nil)

        keyGenerator = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            self.currentKey = self.generateOneTimeKey()
            self.encryptClipboardContents()
        }
    }

    func generateOneTimeKey() -> [UInt8] {
        // Your existing key generation code
    }

    func encryptClipboardContents() {
        // Your existing encryption code
    }

    func decryptClipboardContents() {
        // Your existing decryption code
    }

    func showAlert(message: String) -> Bool {
        print("ALERT: \(message)")
        // Implement your alert mechanism here
        // Return true if user decides to take action, false otherwise
        return false
    }

    // Monitor clipboard changes
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "changeCount" {
            // Clipboard was changed
            let newChangeCount = clipboard.changeCount
            if newChangeCount != previousChangeCount {
                previousChangeCount = newChangeCount
                if clipboard.data(forType: .string) != nil {
                    if showAlert(message: "Copy action detected. Continue?") {
                        encryptClipboardContents()
                    }
                }
            }
        }
    }

    deinit {
        clipboard.removeObserver(self, forKeyPath: "changeCount")
        keyGenerator.invalidate()
    }
}

let monitor = ClipboardMonitor()

RunLoop.main.run()
