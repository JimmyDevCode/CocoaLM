import Foundation

/// Curated model recommendations that work well with CocoaLM.
public enum ModelCatalog {
    /// Recommended balance for structured text generation in mobile apps.
    public static let qwen15BInstructQ4 = ModelDescriptor(
        id: "qwen2.5-1.5b-instruct-q4",
        displayName: "Qwen2.5 1.5B Instruct Q4_K_M",
        repository: "Qwen/Qwen2.5-1.5B-Instruct-GGUF",
        filename: "qwen2.5-1.5b-instruct-q4_k_m.gguf",
        estimatedSizeMB: 986,
        notes: "Good default for on-device structured generation and multilingual prompts."
    )

    /// Alternative lightweight model for experimentation.
    public static let smolLM17BInstructQ4 = ModelDescriptor(
        id: "smollm2-1.7b-instruct-q4",
        displayName: "SmolLM2 1.7B Instruct Q4_K_M",
        repository: "QuantFactory/SmolLM2-1.7B-Instruct-GGUF",
        filename: "SmolLM2-1.7B-Instruct.Q4_K_M.gguf",
        estimatedSizeMB: 1100,
        notes: "Useful as a small on-device alternative when prompt quality matters less than size."
    )

    /// All built-in recommendations exposed by the framework.
    ///
    /// This list is intentionally small and opinionated. Host apps remain free
    /// to define custom ``ModelDescriptor`` values outside the catalog.
    public static let all: [ModelDescriptor] = [
        qwen15BInstructQ4,
        smolLM17BInstructQ4
    ]
}
