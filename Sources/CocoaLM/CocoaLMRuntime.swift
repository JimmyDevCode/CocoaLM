import Foundation
import CocoaLMBridge

/// Runtime-level utilities exposed by CocoaLM.
public enum CocoaLMRuntime {
    /// Returns whether the packaged runtime is available to the current process.
    public static var isAvailable: Bool {
        CocoaLMBridge.isRuntimeAvailable()
    }
}
