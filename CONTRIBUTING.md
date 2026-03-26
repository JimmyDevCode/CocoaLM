# Contributing

Thanks for considering a contribution to CocoaLM.

## Scope

CocoaLM is intentionally narrow in scope:

- local GGUF runtime integration for Apple platforms
- Swift-first public APIs
- minimal runtime abstractions

Please avoid broadening the package into:

- model download management
- prompt orchestration frameworks
- product-specific safety layers
- agent frameworks

Those concerns belong in host applications.

## Development principles

- Keep the public API small.
- Prefer additive changes over breaking changes.
- Keep logs and documentation in English.
- Keep app-specific behavior outside the package.
- Keep large model files out of the repository.

## Pull requests

Before opening a PR:

1. Update documentation for any public API change.
2. Add or update tests when behavior changes.
3. Avoid introducing new required dependencies without a strong reason.
4. Keep Objective-C++ changes isolated to the bridge target.

## Release-minded changes

Changes that affect packaging should also update:

- `README.md`
- `Documentation/ARCHITECTURE.md`
- `Documentation/RELEASING.md`
- `CHANGELOG.md`
