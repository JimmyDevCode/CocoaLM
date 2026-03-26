import Foundation

/// Search strategy used when locating a GGUF model file.
public enum ModelLocationStrategy: Sendable {
    /// Search the application bundle first, then the user's documents directory.
    case bundleThenDocuments
    /// Search the user's documents directory first, then the application bundle.
    case documentsThenBundle
}

/// Resolves the location of model files without downloading them.
public enum ModelLocator {
    /// Resolves a model URL for the given descriptor.
    ///
    /// - Parameters:
    ///   - descriptor: The model to locate.
    ///   - strategy: Search order for bundle and documents directory.
    ///   - bundle: Bundle used for bundled resources. Defaults to `.main`.
    ///   - fileManager: File manager used for filesystem lookups.
    /// - Returns: A local file URL if the model exists, otherwise `nil`.
    public static func locate(
        _ descriptor: ModelDescriptor,
        strategy: ModelLocationStrategy = .bundleThenDocuments,
        bundle: Bundle = .main,
        fileManager: FileManager = .default
    ) -> URL? {
        let bundledURL = bundle.resourceURL?.appendingPathComponent(descriptor.filename)
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(descriptor.filename)

        switch strategy {
        case .bundleThenDocuments:
            return firstExistingURL(in: [bundledURL, documentsURL], fileManager: fileManager)
        case .documentsThenBundle:
            return firstExistingURL(in: [documentsURL, bundledURL], fileManager: fileManager)
        }
    }

    private static func firstExistingURL(
        in urls: [URL?],
        fileManager: FileManager
    ) -> URL? {
        for url in urls.compactMap({ $0 }) where fileManager.fileExists(atPath: url.path) {
            return url
        }

        return nil
    }
}
