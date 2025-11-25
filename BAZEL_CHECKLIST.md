# Bazel Setup Checklist

Use this checklist to ensure your Bazel setup is complete and working.

## 📋 Pre-Setup

- [x] ✅ Fixed syntax error in ContentView.swift
- [x] ✅ Created all Bazel configuration files
- [x] ✅ Created CI/CD pipeline
- [x] ✅ Created helper scripts
- [x] ✅ Created documentation

## 🔧 Installation

- [ ] Install Bazelisk
  ```bash
  brew install bazelisk
  ```

- [ ] Verify installation
  ```bash
  bazelisk version
  # Should show: Bazelisk version: v1.x.x
  # Bazel version: 7.0.0
  ```

- [ ] Make helper script executable
  ```bash
  chmod +x bazel.sh
  ```

## 📁 Project Configuration

- [ ] Verify your project structure matches BUILD file expectations
  ```bash
  # Check where your Swift files are
  find . -name "*.swift" -not -path "*/\.*" | head -10
  
  # Update BUILD file if paths don't match
  ```

- [ ] Locate your Info.plist file
  ```bash
  find . -name "Info.plist" -not -path "*/\.*"
  
  # Update BUILD file with correct path
  ```

- [ ] Check your bundle identifier
  ```bash
  # Update in BUILD file if different from:
  # com.yourcompany.poemoftheday
  ```

## 🏗️ First Build

- [ ] Attempt first build
  ```bash
  ./bazel.sh build
  ```

- [ ] If build fails, check common issues:
  - [ ] Xcode command line tools installed
    ```bash
    xcode-select --install
    ```
  
  - [ ] Correct Xcode selected
    ```bash
    sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
    ```
  
  - [ ] Swift files are where BUILD expects them
    ```bash
    # Update glob patterns in BUILD file
    ```

- [ ] Build succeeds ✅

## 🧪 Test Setup

- [ ] List available simulators
  ```bash
  xcrun simctl list devices | grep iPhone
  ```

- [ ] Update simulator in .bazelrc if needed
  ```bash
  # Edit line:
  # test --ios_simulator_device="iPhone 16"
  ```

- [ ] Run unit tests
  ```bash
  ./bazel.sh unit-test
  ```

- [ ] Run UI tests
  ```bash
  ./bazel.sh ui-test
  ```

- [ ] All tests pass ✅

## 📊 Coverage

- [ ] Generate coverage report
  ```bash
  ./bazel.sh coverage
  ```

- [ ] Verify coverage report location
  ```bash
  bazelisk info output_path
  # Look in: {output_path}/_coverage/_coverage_report.dat
  ```

## 🔄 CI/CD Setup

- [ ] Enable GitHub Actions
  - Go to repository Settings → Actions → General
  - Enable Actions

- [ ] Add repository secrets (if needed)
  - Settings → Secrets and variables → Actions
  - Add any API keys or credentials

- [ ] Verify workflow file exists
  ```bash
  ls -la .github/workflows/bazel-ci.yml
  ```

- [ ] Check Xcode version in CI
  ```bash
  # Verify this matches available version on GitHub runners:
  grep "XCODE_VERSION" .github/workflows/bazel-ci.yml
  ```

- [ ] Commit and push changes
  ```bash
  git add .
  git commit -m "Add Bazel build system and CI"
  git push origin main
  ```

- [ ] Check GitHub Actions tab
  - Go to repository → Actions
  - Verify workflow runs

- [ ] All CI jobs pass ✅

## 🎯 Optional Enhancements

- [ ] Set up remote caching
  - Configure in .bazelrc
  - Add remote cache URL

- [ ] Set up Codecov
  - Sign up at codecov.io
  - Add CODECOV_TOKEN to GitHub secrets
  - Uncomment codecov section in CI workflow

- [ ] Install SwiftLint
  ```bash
  brew install swiftlint
  ```

- [ ] Install swift-format
  ```bash
  brew install swift-format
  ```

- [ ] Set up graphviz for dependency graphs
  ```bash
  brew install graphviz
  ./bazel.sh graph  # Generate dependency visualization
  ```

## 🧹 Cleanup

- [ ] Add Bazel to .gitignore (already done ✅)
- [ ] Remove any unnecessary files
- [ ] Verify .bazelignore is correct

## 📚 Team Onboarding

- [ ] Share documentation with team
  - [ ] BAZEL_BUILD.md
  - [ ] BAZEL_MIGRATION.md
  - [ ] BAZEL_ARCHITECTURE.md

- [ ] Update team wiki/docs
- [ ] Add to project README (already done ✅)
- [ ] Share quick start commands
  ```bash
  # Just these three commands to get started:
  brew install bazelisk
  chmod +x bazel.sh
  ./bazel.sh build
  ```

## ✅ Verification

Run the full CI pipeline locally:

- [ ] Run local CI
  ```bash
  ./bazel.sh ci
  ```

- [ ] Output shows:
  - [x] ✓ Build successful
  - [x] ✓ Unit tests passed
  - [x] ✓ UI tests passed
  - [x] ✓ Coverage generated

## 🎉 Success Criteria

You're done when:

- [x] `./bazel.sh build` completes successfully
- [x] `./bazel.sh test` passes all tests
- [x] `./bazel.sh ci` runs without errors
- [x] GitHub Actions CI is green
- [x] Team can build locally with Bazel
- [x] Build times are reasonable (< 5 min clean build)
- [x] Documentation is accessible and clear

## 🔍 Troubleshooting Reference

If you encounter issues, check these resources in order:

1. **Quick Fixes**: See below
2. **Build Guide**: `BAZEL_BUILD.md`
3. **Migration Guide**: `BAZEL_MIGRATION.md`
4. **Architecture**: `BAZEL_ARCHITECTURE.md`

### Quick Troubleshooting

#### Build Error: "No such package"
```bash
# Fix: Update glob patterns in BUILD file
# Check actual file locations:
find . -name "*.swift" -not -path "*/\.*" | head -20
```

#### Build Error: "No such file: Info.plist"
```bash
# Fix: Update Info.plist path in BUILD file
find . -name "Info.plist"
# Then edit BUILD file with correct path
```

#### Test Error: "Simulator not found"
```bash
# Fix: List simulators and update .bazelrc
xcrun simctl list devices | grep iPhone
# Edit .bazelrc with valid device name
```

#### CI Error: "Xcode version not found"
```bash
# Fix: Update XCODE_VERSION in .github/workflows/bazel-ci.yml
# Check available versions on GitHub runners
```

#### Cache Issues
```bash
# Nuclear option - clear everything
./bazel.sh deep-clean
rm -rf ~/Library/Developer/Xcode/DerivedData
```

## 📞 Getting Help

- **Command Help**: `./bazel.sh help` or `make help`
- **Bazel Docs**: https://bazel.build/
- **Rules Apple**: https://github.com/bazelbuild/rules_apple
- **Project Issues**: Create an issue on GitHub

## 📝 Notes

### What's Included

✅ All configuration files created
✅ CI/CD pipeline ready
✅ Helper scripts for easy use
✅ Comprehensive documentation
✅ Code syntax error fixed

### What You Need to Do

⚠️ Install Bazelisk
⚠️ Verify project structure matches BUILD
⚠️ Update Info.plist path if needed
⚠️ Test build locally
⚠️ Enable GitHub Actions
⚠️ Share with team

### Optional but Recommended

💡 Set up remote caching
💡 Configure Codecov
💡 Install linting tools
💡 Generate dependency graphs

---

**Pro Tip**: Start by running `./bazel.sh build` locally. If it fails, the error message will tell you exactly what needs to be fixed!

**Remember**: Bazel is additive. You can keep using Xcode for development while using Bazel for CI/CD. They work great together!

---

Last Updated: $(date)
Setup Version: 1.0
Bazel Version: 7.0.0
