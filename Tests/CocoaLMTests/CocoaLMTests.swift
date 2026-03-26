import XCTest
@testable import CocoaLM

final class CocoaLMTests: XCTestCase {
    func testCatalogContainsRecommendedModels() {
        XCTAssertTrue(ModelCatalog.all.contains(ModelCatalog.qwen15BInstructQ4))
        XCTAssertTrue(ModelCatalog.all.contains(ModelCatalog.smolLM17BInstructQ4))
    }

    func testModelLocatorReturnsNilWhenModelDoesNotExist() {
        let descriptor = ModelDescriptor(
            id: "missing-model",
            displayName: "Missing Model",
            repository: "example/missing",
            filename: "missing.gguf",
            estimatedSizeMB: 1,
            notes: "Test model."
        )

        let url = ModelLocator.locate(
            descriptor,
            strategy: .bundleThenDocuments,
            bundle: Bundle(for: Self.self),
            fileManager: .default
        )

        XCTAssertNil(url)
    }

    func testGenerationConfigDefaultsAreStable() {
        let config = GenerationConfig()

        XCTAssertEqual(config.contextLength, 1024)
        XCTAssertEqual(config.maxTokens, 160)
        XCTAssertEqual(config.temperature, 0.2)
    }

    func testRuntimeAvailabilityIsTrueWithBundledBinaryTarget() {
        XCTAssertTrue(CocoaLMRuntime.isAvailable)
    }
}
