# Contributing to device_trust

Thank you for your interest in contributing! This document outlines the process for contributing to the device_trust Flutter plugin.

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:

   ```bash
   git clone https://github.com/YOUR_USERNAME/device_trust.git
   cd device_trust
   ```

3. **Create a feature branch**:

   ```bash
   git checkout -b feature/your-feature-name
   ```

## Branch Naming Convention

- `feature/description` - New features
- `fix/description` - Bug fixes
- `docs/description` - Documentation updates
- `chore/description` - Maintenance tasks

## Development Workflow

### 1. Install Dependencies

```bash
flutter pub get
cd example && flutter pub get && cd ..
```

### 2. Run Static Analysis

Ensure code passes strict linting:

```bash
flutter analyze
cd example && flutter analyze && cd ..
```

All issues must be resolved before submitting.

### 3. Run Tests

```bash
# Plugin tests
flutter test

# Example app tests
cd example && flutter test && cd ..
```

### 4. Format Code

```bash
dart format .
```

### 5. Add Tests

- **New features**: Add unit tests covering the new functionality
- **Bug fixes**: Add regression tests to prevent recurrence
- Aim for meaningful test coverage, not just numbers

### 6. Update Documentation

- Update `README.md` if user-facing behavior changes
- Add dartdoc comments for any new public APIs (`/// documentation`)
- Update `CHANGELOG.md` under `[Unreleased]` section

### 7. Test on Real Devices

If your change affects platform code:

- **Android**: Test on physical device and emulator
- **iOS**: Test on physical device and simulator

Document test results in your PR description.

### 8. Validate iOS Dependency Manager Paths

If your change touches iOS native code (`ios/device_trust/Sources/`), validate
**both** CocoaPods and Swift Package Manager integration:

#### CocoaPods Validation

```bash
flutter config --no-enable-swift-package-manager
cd example && flutter build ios --simulator --no-codesign && cd ..
cd ios && pod lib lint --allow-warnings && cd ..
```

#### Swift Package Manager Validation

```bash
flutter config --enable-swift-package-manager
cd example && flutter build ios --simulator --no-codesign && cd ..
```

#### SPM Resolution Assertion

After building the example app with SPM enabled, ensure that the build actually
resolved `device_trust` via Swift Package Manager and not via CocoaPods fallback.
This is enforced in CI, but contributors should verify locally as well:

- Check that the generated Xcode project and/or `Package.resolved` references
  `device_trust` as a Swift package dependency.

**Requirements:**

- **Flutter 3.41.0+** and **Dart 3.11.0+** are required for SPM support.
- Do not commit absolute local filesystem paths in Xcode project files.
  If adding the plugin as a local package in the example, ensure the
  `project.pbxproj` reference uses a relative path
  (e.g., `../../ios/device_trust`) with `sourceTree = "<group>"`.

## Code Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Respect `public_member_api_docs` linting rule - all public members must have documentation
- Use `const` constructors where possible
- Prefer `final` for local variables
- Keep functions small and focused
- Avoid `print()` in production code (use logging if needed)

## Platform-Specific Guidelines

### Android (Kotlin/C++)

- Follow Kotlin coding conventions
- Keep C++ code POSIX-compliant
- Add comments for non-obvious native code
- Ensure fail-soft behavior (no crashes on errors)

### iOS (Swift/Objective-C++)

- Follow Swift style guidelines
- Use `@try-@catch` for fail-soft behavior in Objective-C++
- Test on both simulator and physical device

## Running the Example App

### iOS

```bash
cd example
flutter run -d "iPhone 15"  # Simulator
# or
flutter run -d <device-id>  # Physical device
```

### Android

```bash
cd example
flutter run -d emulator-5554  # Emulator
# or
flutter run -d <device-id>    # Physical device
```

## Pull Request Process

1. **Commit your changes** with clear, descriptive messages:

   ```bash
   git commit -m "feat: add X detection for Android"
   ```

   Follow [Conventional Commits](https://www.conventionalcommits.org/):
   - `feat:` - New feature
   - `fix:` - Bug fix
   - `docs:` - Documentation
   - `chore:` - Maintenance
   - `test:` - Adding tests

2. **Push to your fork**:

   ```bash
   git push origin feature/your-feature-name
   ```

3. **Open a Pull Request** on GitHub with:
   - Clear title and description
   - Reference related issues (e.g., "Fixes #123")
   - Completed PR checklist
   - Test results (platforms tested)

4. **Sign-off commits** (Developer Certificate of Origin):

   ```bash
   git commit -s -m "Your message"
   ```

5. **Respond to review feedback** promptly

## Breaking Changes

If your PR introduces breaking changes:

1. Mark it clearly in the PR title: `[BREAKING]`
2. Document migration steps in the PR description
3. Update `CHANGELOG.md` with migration guide
4. If changing minimum Dart or Flutter SDK requirements, update all version
   constraints and release documentation accordingly.

## Questions?

- Open a [Discussion](https://github.com/MuhammedErdemKazanci/device_trust/discussions) for questions
- Check existing issues before creating new ones
- Be respectful and follow the [Code of Conduct](CODE_OF_CONDUCT.md)

## License

By contributing, you agree that your contributions will be licensed under the same [MIT License](LICENSE) that covers the project.
