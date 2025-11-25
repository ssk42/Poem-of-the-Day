# Bazel CI Quick Reference

## Manual Build Commands

```bash
cd "Poem of the Day"

# Build everything
bazel build //...

# Build specific targets
bazel build //:PoemOfTheDay
bazel build //Poem\ of\ the\ Day\ Widget:PoemOfTheDayWidget

# Run tests
bazel test //...
bazel test //Poem\ of\ the\ DayTests:PoemOfTheDayTests
bazel test //Poem\ of\ the\ DayUITests:PoemOfTheDayUITests

# Clean build
bazel clean
```

## CI/CD Integration

The project uses Bazel for builds in CI via GitHub Actions.

### Workflow: `.github/workflows/bazel-ci.yml`

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop`
- Manual workflow dispatch

**Steps:**
1. Checkout code
2. Install Bazelisk (Bazel version manager)
3. Cache Bazel build artifacts
4. Build app library
5. Build main app
6. Build widget extension
7. Run unit tests
8. Run UI tests
9. Upload artifacts

**Caching:**
- Caches `~/.cache/bazel` and `~/Library/Caches/bazel`
- Cache key based on MODULE.bazel, .bazelrc, and BUILD files
- Significantly speeds up subsequent builds

### Local Development

Developers can use either:
- **Xcode** for editing, debugging, and local testing
- **Bazel** for reproducible builds matching CI

### Benefits

✅ **Hermetic builds** - same results every time
✅ **Fast incremental builds** - only rebuilds changed code
✅ **Shared cache** - across team and CI
✅ **No Xcode version conflicts** - controlled via .bazelrc
✅ **Cross-platform CI** - can run on Linux (future)

### Requirements

Team members need:
```bash
brew install bazelisk
```

Bazelisk automatically uses the version specified in `.bazelversion`.
