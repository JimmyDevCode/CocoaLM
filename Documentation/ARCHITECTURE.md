# CocoaLM Architecture

## Goals

- Provide a Swift-first API for local text generation on Apple platforms.
- Hide `llama.cpp` implementation details behind a small bridge layer.
- Keep model selection and prompt engineering outside the framework.
- Support bundle-based and documents-based model resolution.

## Design principles

### 1. Small public surface

The public API is intentionally small:

- `ModelDescriptor`
- `ModelCatalog`
- `GenerationConfig`
- `ModelLocator`
- `CocoaLMRuntime`
- `CocoaLMSession`

Everything else remains internal to reduce coupling and preserve refactoring freedom.

### 2. Runtime separate from model distribution

The framework owns:

- runtime packaging
- loading
- token generation
- error translation

The host app owns:

- which model to use
- where to store the model
- how to download it
- how to structure prompts
- how to validate outputs

### 3. Swift-first, Objective-C++ hidden

Swift remains the main integration surface for app developers. Objective-C++ exists only to bridge into the `llama.cpp` C/C++ API.

This keeps product code cleaner and makes the framework easier to consume from SwiftUI or UIKit apps.

### 4. Reuse loaded models

The bridge pool caches one bridge per `modelURL + contextLength` pair. That avoids repeatedly reloading large GGUF files during a session.

### 5. English logs and docs

Framework logs, source documentation, README content, and architectural notes are all written in English to match common package ecosystem expectations.

## Current packaging strategy

CocoaLM is currently distributed through:

- a hosted GitHub Releases XCFramework artifact
- `binaryTarget(url:checksum:)` in `Package.swift`

That keeps the public package installable through Swift Package Manager without requiring a local `Vendor/` directory.

For future releases, the maintainer still rebuilds `llama.xcframework` from `llama.cpp`, uploads a new release artifact, and updates the binary target URL and checksum.

## Non-goals

- Shipping 1 GB+ GGUF files through SPM
- Product-specific safety logic
- Product-specific prompt templates
- Product-specific JSON parsers

Those belong in the host application.
