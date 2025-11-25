# Migrating to Bazel - Quick Start Guide

This guide will help you migrate your Poem of the Day project to use Bazel for CI/CD.

## 🎯 Why Bazel?

- **Reproducible Builds**: Same input = same output, every time
- **Incremental Builds**: Only rebuilds what changed
- **Scalable**: Handles large codebases efficiently
- **Cross-Platform**: Works on macOS, Linux, and Windows
- **Remote Caching**: Share build artifacts across team and CI
- **Hermetic**: Isolated build environment

## 📋 Pre-Migration Checklist

- [x] Syntax errors in ContentView.swift fixed
- [ ] All existing tests pass with Xcode
- [ ] API keys and secrets documented
- [ ] Current project structure documented
- [ ] Team notified of upcoming changes

## 🚀 Migration Steps

### Step 1: Install Bazelisk

```bash
# macOS via Homebrew
brew install bazelisk

# Verify installation
bazelisk version
```

### Step 2: Verify Bazel Files

The following files have been created for you:

- ✅ `WORKSPACE` - Defines external dependencies
- ✅ `BUILD` - Defines build targets
- ✅ `.bazelrc` - Build configuration
- ✅ `.bazelversion` - Pins Bazel version to 7.0.0
- ✅ `.bazelignore` - Files to ignore
- ✅ `.github/workflows/bazel-ci.yml` - CI pipeline
- ✅ `bazel.sh` - Helper script for common commands
- ✅ `BAZEL_BUILD.md` - Comprehensive documentation

### Step 3: Configure Project Structure

**Important**: The BUILD file assumes your project structure is:

```
Poem of the Day/
├── Source files (*.swift)
├── Tests/
│   └── Unit tests
├── UITests/
│   └── UI tests
└── Info.plist
```

**Action Required**: Update the `BUILD` file if your structure differs:

```bash
# Check your actual structure
find . -name "*.swift" -not -path "*/\.*" | head -20

# Edit BUILD file to match your structure
nano BUILD
```

### Step 4: Make Helper Script Executable

```bash
chmod +x bazel.sh
```

### Step 5: First Build

```bash
# Try building the app
./bazel.sh build

# If you see errors, they're likely due to file path issues
# Update the glob patterns in BUILD to match your actual file locations
```

### Step 6: Fix Common Issues

#### Issue: "No such package"

**Problem**: Bazel can't find your source files

**Solution**: Update the `srcs` glob in BUILD:

```python
swift_library(
    name = "PoemOfTheDayLib",
    srcs = glob([
        "**/*.swift",  # Match all Swift files
    ], exclude = [
        "**/*Tests.swift",
        "**/Tests/**",
    ]),
    ...
)
```

#### Issue: "No such file: Info.plist"

**Problem**: Info.plist location is incorrect

**Solution**: Update the path in BUILD:

```python
ios_application(
    name = "PoemOfTheDay",
    infoplists = ["path/to/actual/Info.plist"],
    ...
)
```

#### Issue: "Missing dependencies"

**Problem**: External dependencies not configured

**Solution**: Add dependencies to WORKSPACE and update BUILD

### Step 7: Run Tests

```bash
# Try running tests
./bazel.sh test

# If tests fail, check the test file locations
# Update the test srcs glob in BUILD
```

### Step 8: Set Up CI

The GitHub Actions workflow is ready at `.github/workflows/bazel-ci.yml`

**Action Required**:

1. **Enable GitHub Actions** in your repository settings
2. **Configure secrets** (if needed):
   - Go to Settings → Secrets → Actions
   - Add any API keys or credentials

3. **Push to GitHub**:
   ```bash
   git add .
   git commit -m "Add Bazel build system"
   git push origin main
   ```

4. **Verify CI runs**: Check the Actions tab on GitHub

### Step 9: Configure Code Coverage (Optional)

If you want coverage reports uploaded to Codecov:

1. Sign up at [codecov.io](https://codecov.io)
2. Add repository
3. Add `CODECOV_TOKEN` to GitHub Secrets
4. Uncomment the codecov section in `.github/workflows/bazel-ci.yml`

### Step 10: Team Onboarding

Share with your team:

1. **Quick start**: They just need to run `brew install bazelisk`
2. **Documentation**: Point them to `BAZEL_BUILD.md`
3. **Helper script**: Show them `./bazel.sh help`
4. **Xcode still works**: Bazel is additive, not replacing Xcode

## 🔧 Customizing Your Setup

### Adding External Dependencies

Edit `WORKSPACE` to add Swift packages or other dependencies:

```python
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

git_repository(
    name = "some_dependency",
    remote = "https://github.com/user/repo.git",
    tag = "1.0.0",
)
```

### Custom Build Configurations

Add custom configs to `.bazelrc`:

```bash
# Add production config
build:production --compilation_mode=opt
build:production --define=PRODUCTION=1
build:production --strip=always
```

Use it:

```bash
bazelisk build --config=production //:PoemOfTheDay
```

### Multiple iOS Versions

Test against multiple iOS versions:

```bash
# iOS 17
bazelisk test --ios_simulator_version=17.0 //...

# iOS 18
bazelisk test --ios_simulator_version=18.0 //...
```

## 📊 Monitoring Build Performance

### Build Profiling

```bash
# Profile a build
bazelisk build --profile=profile.json //:PoemOfTheDay

# Analyze profile
bazelisk analyze-profile profile.json
```

### Build Metrics

```bash
# Generate build event log
bazelisk build --build_event_text_file=events.txt //:PoemOfTheDay

# Check what was cached
cat events.txt | grep "action_result"
```

## 🚨 Troubleshooting

### Build Fails Immediately

1. Check Xcode is installed and selected:
   ```bash
   xcode-select -p
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   ```

2. Check file paths in BUILD match your project

3. Run with verbose output:
   ```bash
   bazelisk build --verbose_failures //:PoemOfTheDay
   ```

### Tests Don't Run

1. List available simulators:
   ```bash
   xcrun simctl list devices
   ```

2. Update `.bazelrc` with a valid device:
   ```bash
   test --ios_simulator_device="iPhone 15"
   ```

3. Boot the simulator manually:
   ```bash
   open -a Simulator
   ```

### CI Fails on GitHub

1. Check the GitHub Actions logs
2. Ensure Xcode version matches (currently set to 16.0)
3. Update `.github/workflows/bazel-ci.yml` if needed:
   ```yaml
   env:
     XCODE_VERSION: "15.4"  # Change to available version
   ```

### Slow Builds

1. Enable disk cache (already in `.bazelrc`)
2. Use remote cache for team (configure in `.bazelrc`)
3. Increase parallel jobs:
   ```bash
   bazelisk build --jobs=16 //:PoemOfTheDay
   ```

## 📈 Next Steps

1. **Week 1**: Get Bazel building locally
2. **Week 2**: Get CI pipeline green
3. **Week 3**: Enable remote caching
4. **Week 4**: Optimize build times
5. **Ongoing**: Keep BUILD files updated as project grows

## 🤝 Getting Help

- **Documentation**: See `BAZEL_BUILD.md`
- **Quick commands**: Run `./bazel.sh help`
- **Bazel docs**: https://bazel.build/
- **Rules Apple**: https://github.com/bazelbuild/rules_apple

## ✅ Success Criteria

You've successfully migrated when:

- [ ] `./bazel.sh build` succeeds
- [ ] `./bazel.sh test` passes all tests
- [ ] `./bazel.sh ci` completes without errors
- [ ] GitHub Actions CI is green
- [ ] Team can build and test locally with Bazel
- [ ] Build times are reasonable (< 5 min for clean build)

## 🎉 You're Done!

You now have:

- ✅ Reproducible builds
- ✅ Fast incremental compilation
- ✅ Hermetic CI environment
- ✅ Scalable build system
- ✅ Both Xcode and Bazel working side-by-side

**Pro Tip**: You can continue using Xcode for day-to-day development and use Bazel for CI/CD and team builds. They work great together!

---

Questions? Check `BAZEL_BUILD.md` or create an issue!
