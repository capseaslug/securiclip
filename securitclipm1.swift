
//By TT 2023
// This function generates a one-time key that is used to encrypt the clipboard contents.
func generateOneTimeKey() -> [UInt8] {
  // Get the secure enclave from the M1 chip.
  let secureEnclave = SecureEnclave.shared

  // Generate a 256-bit random key.
  let key = secureEnclave.generateRandomBytes(count: 32)

  // Return the key.
  return key
}

// This function encrypts the clipboard contents using the given key.
func encryptClipboardContents(contents: Data, key: [UInt8]) -> Data {
  // Create a cipher using the key.
  let cipher = try! Cipher.init(encryptionAlgorithm: .aes128GCM, key: key)

  // Encrypt the contents.
  let encryptedContents = cipher.encrypt(data: contents)

  // Return the encrypted contents.
  return encryptedContents
}

// This function decrypts the clipboard contents using the given key.
func decryptClipboardContents(contents: Data, key: [UInt8]) -> Data {
  // Create a cipher using the key.
  let cipher = try! Cipher.init(decryptionAlgorithm: .aes128GCM, key: key)

  // Decrypt the contents.
  let decryptedContents = cipher.decrypt(data: contents)

  // Return the decrypted contents.
  return decryptedContents
}

// This function is called when the bootloader starts.
func bootloaderEntry() {
  // Get the system clipboard.
  let clipboard = NSPasteboard.general

  // Create a listener for clipboard changes.
  clipboard.addObserver(self, forKeyPath: "contents", options: [.new], context: nil)

  // Start generating one-time keys.
  let keyGenerator = Timer(interval: 1.0, repeats: true) { timer in
    let key = generateOneTimeKey()

    // Encrypt the clipboard contents using the key.
    let encryptedContents = encryptClipboardContents(contents: clipboard.data, key: key)

    // Set the clipboard contents to the encrypted contents.
    clipboard.setData(encryptedContents, forType: .string)
  }

  keyGenerator.start()

  // Wait for the user to press a key.
  while true {
    let key = readLine()!

    if key == "paste" {
      // Check the user's fingerprint.
      let success = authenticateWithTouchID()

      if success {
        // Decrypt the clipboard contents and paste them.
        let decryptedContents = decryptClipboardContents(contents: clipboard.data, key: keyGenerator.currentKey)
        clipboard.clearContents()
        clipboard.setData(decryptedContents, forType: .string)
      }
    }
  }
}

// This function is called when the clipboard contents change.
func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
  // If the clipboard contents have changed, encrypt them using the current one-time key.
  if keyPath == "contents" {
    let key = keyGenerator.currentKey
    let encryptedContents = encryptClipboardContents(contents: clipboard.data, key: key)
    clipboard.setData(encryptedContents, forType: .string)
  }
}


