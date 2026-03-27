import Foundation

/// Describes a GGUF model that can be loaded by CocoaLM.
public struct ModelDescriptor: Identifiable, Hashable, Codable, Sendable {
    /// Stable identifier used by the host app.
    public let id: String
    /// Human-readable name for UI or logging.
    public let displayName: String
    /// Upstream repository or source reference.
    public let repository: String
    /// GGUF filename expected on disk.
    public let filename: String
    /// Approximate compressed size in megabytes.
    public let estimatedSizeMB: Int
    /// Short operational notes for developers.
    public let notes: String

    /// Creates metadata for a GGUF model file managed by the host app.
    ///
    /// - Parameters:
    ///   - id: Stable identifier used by the host application.
    ///   - displayName: Human-readable name for UI, logs, or diagnostics.
    ///   - repository: Upstream model source, such as a Hugging Face repository.
    ///   - filename: Exact GGUF filename expected on disk.
    ///   - estimatedSizeMB: Approximate file size in megabytes.
    ///   - notes: Operational notes for developers integrating the model.
    public init(
        id: String,
        displayName: String,
        repository: String,
        filename: String,
        estimatedSizeMB: Int,
        notes: String
    ) {
        self.id = id
        self.displayName = displayName
        self.repository = repository
        self.filename = filename
        self.estimatedSizeMB = estimatedSizeMB
        self.notes = notes
    }
}
