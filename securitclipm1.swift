import Foundation
import Security
import os.secureEnclave

class SecureClipboardManager: NSObject {
    private var clipboard = NSPasteboard.general
    private var keyGenerator: Timer!
    private var currentKey: [UInt8] = []
    private var previousChangeCount = 0
    private var isSecureClipboardEnabled = false

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
        let secureEnclave = SecureEnclave.shared
        return secureEnclave.generateRandomBytes(count: 32)
    }

    func enableSecureClipboard() {
        isSecureClipboardEnabled = true
        print("Secure clipboard enabled")
    }

    func disableSecureClipboard() {
        isSecureClipboardEnabled = false
        print("Secure clipboard disabled")
    }

    func encryptClipboardContents() {
        guard let clipboardData = clipboard.data(forType: .string) else {
            return
        }
        let encryptedContents = encryptClipboardContents(contents: clipboardData, key: currentKey)
        clipboard.clearContents()
        clipboard.setData(encryptedContents, forType: .string)
        print("Clipboard contents encrypted")
    }

    func decryptClipboardContents() {
        guard let encryptedData = clipboard.data(forType: .string) else {
            return
        }
        let decryptedContents = decryptClipboardContents(contents: encryptedData, key: currentKey)
        clipboard.clearContents()
        clipboard.setString(decryptedContents, forType: .string)
        print("Clipboard contents decrypted")
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
                    if isSecureClipboardEnabled && showAlert(message: "Copy action detected. Continue?") {
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

let clipboardManager = SecureClipboardManager()

// Parse CLI commands
if CommandLine.arguments.count > 1 {
    let command = CommandLine.arguments[1]
    switch command {
    case "start":
        clipboardManager.startMonitoring()
    case "stop":
        clipboardManager.stopMonitoring()
    case "enable":
        clipboardManager.enableSecureClipboard()
    case "disable":
        clipboardManager.disableSecureClipboard()
    case "status":
        clipboardManager.showStatus()
    default:
        print("Unknown command: \(command)")
    }
} else {
    // Default behavior, start monitoring clipboard changes
    clipboardManager.startMonitoring()
    
    // Enter a run loop to keep the app running
    RunLoop.main.run()
}
