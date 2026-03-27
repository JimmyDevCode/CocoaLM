import Foundation

/// Errors produced by CocoaLM while locating models or generating text.
public enum CocoaLMError: LocalizedError, Sendable {
    /// The GGUF model file could not be found in the expected locations.
    case modelNotFound(filename: String)
    /// The packaged runtime is not available to the current process.
    case runtimeUnavailable
    /// The runtime returned an empty output.
    case emptyOutput
    /// The runtime returned a failure with an attached message.
    case generationFailed(message: String)

    /// A localized, developer-facing description of the runtime error.
    public var errorDescription: String? {
        switch self {
        case .modelNotFound(let filename):
            return "The model file '\(filename)' could not be found."
        case .runtimeUnavailable:
            return "The CocoaLM runtime is unavailable."
        case .emptyOutput:
            return "The model returned an empty output."
        case .generationFailed(let message):
            return message
        }
    }
}
