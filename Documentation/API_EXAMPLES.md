# CocoaLM API Examples

## Full example

This example covers the full public surface of CocoaLM:

- `CocoaLMRuntime`
- `ModelDescriptor`
- `ModelCatalog`
- `ModelLocationStrategy`
- `ModelLocator`
- `GenerationConfig`
- `CocoaLMSession`
- `CocoaLMError`

```swift
import CocoaLM
import Foundation

struct LocalClassifier {
    func run() async {
        guard CocoaLMRuntime.isAvailable else {
            print("CocoaLM runtime is unavailable on this process.")
            return
        }

        let model = ModelCatalog.qwen15BInstructQ4
        let config = GenerationConfig(
            contextLength: 1024,
            maxTokens: 160,
            temperature: 0.2
        )

        do {
            let session = try CocoaLMSession(
                model: model,
                strategy: .bundleThenDocuments,
                generationConfig: config
            )

            let output = try await session.generate(
                userPrompt: "Return a JSON object with mood and intensity.",
                systemPrompt: "You are a structured output assistant. Return valid JSON only."
            )

            print(output)
        } catch let error as CocoaLMError {
            switch error {
            case .modelNotFound(let filename):
                print("Missing model file: \(filename)")
            case .runtimeUnavailable:
                print("The packaged runtime is not available.")
            case .emptyOutput:
                print("The model returned an empty string.")
            case .generationFailed(let message):
                print("Generation failed: \(message)")
            }
        } catch {
            print("Unexpected error: \(error.localizedDescription)")
        }
    }
}
```

## Custom model descriptor

Use a custom `ModelDescriptor` when your app ships a different GGUF file.

```swift
import CocoaLM

let customModel = ModelDescriptor(
    id: "my-local-model",
    displayName: "My Local Model",
    repository: "my-org/my-model-repo",
    filename: "my-model-q4.gguf",
    estimatedSizeMB: 850,
    notes: "Good for short structured outputs."
)
```

## Explicit model lookup

`ModelLocator` can be used independently before creating a session.

```swift
import CocoaLM

let url = ModelLocator.locate(
    ModelCatalog.qwen15BInstructQ4,
    strategy: .documentsThenBundle
)
```

## GenerationConfig notes

Use `GenerationConfig` based on the kind of output you want:

- Structured JSON or classification: low temperature such as `0.1` or `0.2`
- Short assistant replies: medium temperature such as `0.3...0.6`
- More varied text: higher temperature values

Example:

```swift
let config = GenerationConfig(
    contextLength: 1024,
    maxTokens: 160,
    temperature: 0.2
)
```
