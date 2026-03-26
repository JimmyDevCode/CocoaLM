import Foundation

/// Runtime options that control token generation.
public struct GenerationConfig: Hashable, Sendable {
    /// Maximum context window used by the runtime.
    public let contextLength: Int
    /// Maximum number of generated tokens per request.
    public let maxTokens: Int
    /// Sampling temperature. Use values near zero for deterministic output.
    public let temperature: Double

    public init(
        contextLength: Int = 1024,
        maxTokens: Int = 160,
        temperature: Double = 0.2
    ) {
        self.contextLength = contextLength
        self.maxTokens = maxTokens
        self.temperature = temperature
    }
}
