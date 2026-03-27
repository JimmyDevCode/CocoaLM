# Releasing CocoaLM

## Current release setup

The package is currently distributed through:

- a hosted GitHub Releases artifact
- `binaryTarget(url:checksum:)` in `Package.swift`

That means the public package no longer depends on a local `Vendor/` directory.

## When cutting a new version

Before publishing a new CocoaLM release:

1. Build a release XCFramework from `llama.cpp`.
2. Package and host the artifact outside the repository.
3. Compute the Swift Package Manager checksum.
4. Update `Package.swift` with the new release URL and checksum.
5. Validate `swift build` on a clean machine with no local `Vendor/` directory.
6. Verify the README installation instructions against the hosted artifact.

## Suggested artifact strategy

Recommended options:

- GitHub Releases artifact + `binaryTarget(url:checksum:)`
- dedicated artifact hosting bucket

## Example configuration

```swift
.binaryTarget(
    name: "llama",
    url: "https://github.com/JimmyDevCode/CocoaLM/releases/download/0.1.1/llama.xcframework.zip",
    checksum: "01f3183fec1a6af553f8ffc76061d1a870629ddd66dded95c1746b816d7b0649"
)
```

## Release checklist

- Update `CHANGELOG.md`.
- Build and host the XCFramework artifact.
- Compute the new checksum.
- Update `Package.swift`.
- Run `swift package describe`.
- Run `swift build`.
- Run `swift test`.
- Tag the release.
