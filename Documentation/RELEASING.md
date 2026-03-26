# Releasing CocoaLM

## Current development setup

The package currently depends on a local binary target:

- `../Vendor/llama.cpp/build-apple/llama.xcframework`

That is acceptable for local development, but not for a public Swift Package Manager release.

## Public release requirements

Before tagging `1.0` or publishing the repository:

1. Build a release XCFramework from `llama.cpp`.
2. Package and host the artifact outside the repository.
3. Replace the local binary target path with a remote binary target and checksum.
4. Validate `swift build` on a clean machine with no local `Vendor/` directory.
5. Verify the README installation instructions against the hosted artifact.

## Suggested artifact strategy

Recommended options:

- GitHub Releases artifact + `binaryTarget(url:checksum:)`
- dedicated artifact hosting bucket

## Example migration

Replace:

```swift
.binaryTarget(
    name: "llama",
    path: "../Vendor/llama.cpp/build-apple/llama.xcframework"
)
```

With:

```swift
.binaryTarget(
    name: "llama",
    url: "https://github.com/your-org/CocoaLM/releases/download/0.1.0/llama.xcframework.zip",
    checksum: "<checksum>"
)
```

## Release checklist

- Update `CHANGELOG.md`.
- Build and host the XCFramework artifact.
- Update `Package.swift`.
- Run `swift package describe`.
- Run `swift build`.
- Tag the release.
