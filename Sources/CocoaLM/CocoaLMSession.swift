import Foundation
import CocoaLMBridge

private final class BridgePool {
    static let shared = BridgePool()

    private var bridges: [String: CocoaLMBridge] = [:]
    private let lock = NSLock()

    func bridge(modelURL: URL, contextLength: Int) -> CocoaLMBridge {
        lock.lock()
        defer { lock.unlock() }

        let key = "\(modelURL.path)#\(contextLength)"
        if let existing = bridges[key] {
            return existing
        }

        let bridge = CocoaLMBridge(
            modelPath: modelURL.path,
            contextLength: contextLength
        )
        bridges[key] = bridge
        return bridge
    }
}

/// High-level session object used to generate text with a local GGUF model.
public final class CocoaLMSession {
    /// Model metadata associated with this session.
    public let model: ModelDescriptor
    /// Local URL of the GGUF file used by the runtime.
    public let modelURL: URL
    /// Generation parameters for this session.
    public let generationConfig: GenerationConfig

    private let bridge: CocoaLMBridge

    /// Creates a session for a concrete model URL.
    ///
    /// - Parameters:
    ///   - model: Metadata for the GGUF model.
    ///   - modelURL: Local filesystem URL of the GGUF file.
    ///   - generationConfig: Runtime generation options.
    /// - Throws: `CocoaLMError.runtimeUnavailable` if the runtime is missing.
    ///
    /// Example:
    ///
    /// ```swift
    /// let modelURL = Bundle.main.url(
    ///     forResource: "qwen2.5-1.5b-instruct-q4_k_m",
    ///     withExtension: "gguf"
    /// )!
    ///
    /// let session = try CocoaLMSession(
    ///     model: ModelCatalog.qwen15BInstructQ4,
    ///     modelURL: modelURL
    /// )
    /// ```
    public init(
        model: ModelDescriptor,
        modelURL: URL,
        generationConfig: GenerationConfig = GenerationConfig()
    ) throws {
        guard CocoaLMRuntime.isAvailable else {
            throw CocoaLMError.runtimeUnavailable
        }

        self.model = model
        self.modelURL = modelURL
        self.generationConfig = generationConfig
        self.bridge = BridgePool.shared.bridge(
            modelURL: modelURL,
            contextLength: generationConfig.contextLength
        )
    }

    /// Creates a session by searching for the model in the app bundle and/or documents directory.
    ///
    /// - Parameters:
    ///   - model: Metadata for the GGUF model.
    ///   - strategy: Search strategy for locating the model.
    ///   - bundle: Bundle used for bundled resources.
    ///   - fileManager: File manager used for filesystem lookups.
    ///   - generationConfig: Runtime generation options.
    /// - Throws: `CocoaLMError.modelNotFound` if the file cannot be resolved.
    ///
    /// Example:
    ///
    /// ```swift
    /// let session = try CocoaLMSession(
    ///     model: ModelCatalog.qwen15BInstructQ4,
    ///     strategy: .bundleThenDocuments
    /// )
    /// ```
    public convenience init(
        model: ModelDescriptor,
        strategy: ModelLocationStrategy = .bundleThenDocuments,
        bundle: Bundle = .main,
        fileManager: FileManager = .default,
        generationConfig: GenerationConfig = GenerationConfig()
    ) throws {
        guard let modelURL = ModelLocator.locate(
            model,
            strategy: strategy,
            bundle: bundle,
            fileManager: fileManager
        ) else {
            throw CocoaLMError.modelNotFound(filename: model.filename)
        }

        try self.init(
            model: model,
            modelURL: modelURL,
            generationConfig: generationConfig
        )
    }

    /// Generates a response for a user prompt and optional system prompt.
    ///
    /// - Parameters:
    ///   - userPrompt: End-user input passed to the runtime.
    ///   - systemPrompt: System instructions used to shape the generation.
    /// - Returns: The generated text returned by the model.
    /// - Throws: `CocoaLMError` if generation fails or returns no content.
    ///
    /// Example:
    ///
    /// ```swift
    /// let output = try await session.generate(
    ///     userPrompt: "Summarize this text as JSON.",
    ///     systemPrompt: "Return valid JSON only."
    /// )
    /// ```
    public func generate(
        userPrompt: String,
        systemPrompt: String = ""
    ) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            bridge.generate(
                withSystemPrompt: systemPrompt,
                userPrompt: userPrompt,
                maxTokens: generationConfig.maxTokens,
                temperature: generationConfig.temperature
            ) { output, error in
                if let output, output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                    continuation.resume(returning: output)
                } else if let error {
                    continuation.resume(
                        throwing: CocoaLMError.generationFailed(
                            message: error.localizedDescription
                        )
                    )
                } else {
                    continuation.resume(throwing: CocoaLMError.emptyOutput)
                }
            }
        }
    }
}
