import AppKit

final class BobClient {
    enum BobError: LocalizedError {
        case invalidPayload
        case scriptCreationFailed
        case requestFailed(String)

        var errorDescription: String? {
            switch self {
            case .invalidPayload:
                return "Could not prepare the text for Bob."
            case .scriptCreationFailed:
                return "Could not create the Bob automation script."
            case let .requestFailed(message):
                return "Bob request failed: \(message)"
            }
        }
    }

    func translate(text: String, completion: ((Error?) -> Void)? = nil) {
        let payload: [String: Any] = [
            "path": "translate",
            "body": [
                "action": "translateText",
                "text": text,
                "windowLocation": "mouse",
                "inputBoxState": Settings.shared.inputBoxState.rawValue
            ]
        ]

        guard JSONSerialization.isValidJSONObject(payload),
              let data = try? JSONSerialization.data(withJSONObject: payload),
              let json = String(data: data, encoding: .utf8)
        else {
            completion?(BobError.invalidPayload)
            return
        }

        let appleScriptJSON = json
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

        let source = """
        tell application id "com.hezongyidev.Bob"
            request "\(appleScriptJSON)"
        end tell
        """

        guard let script = NSAppleScript(source: source) else {
            completion?(BobError.scriptCreationFailed)
            return
        }

        var errorInfo: NSDictionary?
        script.executeAndReturnError(&errorInfo)

        if let errorInfo {
            let message = (errorInfo[NSAppleScript.errorMessage] as? String)
                ?? errorInfo.description
            completion?(BobError.requestFailed(message))
        } else {
            completion?(nil)
        }
    }
}
