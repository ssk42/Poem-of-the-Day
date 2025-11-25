# Bazel CI Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Developer Workflow                        │
└─────────────────────────────────────────────────────────────────┘

┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│   Xcode     │         │  ./bazel.sh │         │    make     │
│ (Development)│         │  (Bazel CLI)│         │ (Makefile)  │
└──────┬──────┘         └──────┬──────┘         └──────┬──────┘
       │                       │                        │
       │                       │                        │
       └───────────────────────┼────────────────────────┘
                               │
                               ▼
                    ┌──────────────────┐
                    │    Bazelisk      │
                    │ (Version Manager)│
                    └────────┬─────────┘
                             │
                             ▼
                    ┌──────────────────┐
                    │   Bazel 7.0.0    │
                    └────────┬─────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
        ▼                    ▼                    ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│  WORKSPACE   │    │    BUILD     │    │  .bazelrc    │
│              │    │              │    │              │
│ • rules_apple│◄───┤ • App Target │◄───┤ • iOS Config │
│ • rules_swift│    │ • Test Targets    │ • Simulators │
│ • Skylib     │    │ • Library    │    │ • Flags      │
└──────────────┘    └──────────────┘    └──────────────┘


┌─────────────────────────────────────────────────────────────────┐
│                         CI/CD Pipeline                            │
└─────────────────────────────────────────────────────────────────┘

        ┌────────────────────────────────────────┐
        │      GitHub Push / Pull Request        │
        └───────────────┬────────────────────────┘
                        │
                        ▼
        ┌────────────────────────────────────────┐
        │        GitHub Actions Trigger          │
        │   (.github/workflows/bazel-ci.yml)     │
        └───────────────┬────────────────────────┘
                        │
        ┌───────────────┴─────────────────┬──────────────┐
        │                                 │              │
        ▼                                 ▼              ▼
┌──────────────┐              ┌──────────────┐  ┌──────────────┐
│  Build Job   │              │   Lint Job   │  │ Security Job │
│              │              │              │  │              │
│ 1. Cache     │              │ • SwiftLint  │  │ • Scan       │
│ 2. Build App │              │ • Format     │  │ • Analyze    │
│ 3. Unit Tests│              │ • Deps Graph │  │              │
│ 4. UI Tests  │              │              │  │              │
│ 5. Coverage  │              │              │  │              │
└──────┬───────┘              └──────────────┘  └──────────────┘
       │
       ▼
┌──────────────┐
│   Results    │
│              │
│ • Test Pass  │
│ • Coverage % │
│ • Artifacts  │
│ • Logs       │
└──────────────┘


┌─────────────────────────────────────────────────────────────────┐
│                      Build Target Graph                          │
└─────────────────────────────────────────────────────────────────┘

                    ┌───────────────────┐
                    │  PoemOfTheDay     │
                    │  (iOS App)        │
                    └────────┬──────────┘
                             │
                             │ depends on
                             │
                             ▼
                    ┌───────────────────┐
                    │ PoemOfTheDayLib   │
                    │ (Swift Library)   │
                    └────────┬──────────┘
                             │
                             │ sources
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
        ▼                    ▼                    ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│ ContentView  │    │ ViewModels   │    │  Services    │
│ (UI)         │    │ (Logic)      │    │ (Backend)    │
└──────────────┘    └──────────────┘    └──────────────┘

        ┌────────────────────┬────────────────────┐
        │                    │                    │
        ▼                    ▼                    ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│Unit Tests    │    │  UI Tests    │    │ Integration  │
│              │    │              │    │ Tests        │
│ depends on   │    │ depends on   │    │ depends on   │
│ Library      │    │ App          │    │ Library      │
└──────────────┘    └──────────────┘    └──────────────┘


┌─────────────────────────────────────────────────────────────────┐
│                      Caching Strategy                            │
└─────────────────────────────────────────────────────────────────┘

┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│   Local     │         │  GitHub     │         │   Remote    │
│   Cache     │◄────────┤  Actions    │────────►│   Cache     │
│             │         │  Cache      │         │  (Optional) │
│ ~/.bazel_   │         │             │         │             │
│  cache      │         │             │         │             │
└─────────────┘         └─────────────┘         └─────────────┘
      │
      │ Reads/Writes
      │
      ▼
┌─────────────────────────────────────┐
│        Build Artifacts              │
│                                     │
│ • Compiled .o files                 │
│ • Linked libraries                  │
│ • Test results                      │
│ • Coverage reports                  │
└─────────────────────────────────────┘


┌─────────────────────────────────────────────────────────────────┐
│                      File Structure                              │
└─────────────────────────────────────────────────────────────────┘

poem-of-the-day/
├── WORKSPACE              ← Bazel workspace config
├── BUILD                  ← Build targets definition
├── .bazelrc               ← Build flags & configs
├── .bazelversion          ← Pin Bazel version (7.0.0)
├── .bazelignore           ← Files to ignore
│
├── bazel.sh               ← Helper script (CLI)
├── Makefile               ← Alternative interface
│
├── .github/
│   └── workflows/
│       └── bazel-ci.yml   ← CI/CD pipeline
│
├── Poem of the Day/
│   ├── **/*.swift         ← Source files
│   ├── Tests/             ← Unit tests
│   ├── UITests/           ← UI tests
│   └── Info.plist         ← App metadata
│
└── Documentation/
    ├── BAZEL_BUILD.md         ← Usage guide
    ├── BAZEL_MIGRATION.md     ← Migration steps
    ├── BAZEL_SETUP_SUMMARY.md ← This summary
    └── README.md              ← Updated README


┌─────────────────────────────────────────────────────────────────┐
│                   Common Use Cases                               │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────────┐
│  Local Development   │
├──────────────────────┤
│ 1. Edit in Xcode     │──► Fast development loop
│ 2. Test with Xcode   │──► Native Xcode experience
│ 3. Commit changes    │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│  Pre-Push Check      │
├──────────────────────┤
│ ./bazel.sh ci        │──► Full CI locally
│ make ci              │──► Catches issues early
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│  Push to GitHub      │
├──────────────────────┤
│ git push origin main │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│  CI Runs on GitHub   │
├──────────────────────┤
│ • Build              │──► Reproducible
│ • Test               │──► Same as local
│ • Deploy (optional)  │──► Automated
└──────────────────────┘


┌─────────────────────────────────────────────────────────────────┐
│                Command Equivalents                               │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────────┬──────────────────────┬─────────────────┐
│   Xcode Command      │  Bazel Command       │  Make Command   │
├──────────────────────┼──────────────────────┼─────────────────┤
│ Cmd+B (Build)        │ ./bazel.sh build     │ make build      │
│ Cmd+U (Test)         │ ./bazel.sh test      │ make test       │
│ Product > Clean      │ ./bazel.sh clean     │ make clean      │
│ Test > Unit Tests    │ ./bazel.sh unit-test │ make unit-test  │
│ Test > UI Tests      │ ./bazel.sh ui-test   │ make ui-test    │
│ Coverage Report      │ ./bazel.sh coverage  │ make coverage   │
└──────────────────────┴──────────────────────┴─────────────────┘


┌─────────────────────────────────────────────────────────────────┐
│                   Benefits Summary                               │
└─────────────────────────────────────────────────────────────────┘

✅ Reproducible Builds
   Same input → Same output, always

✅ Incremental Compilation
   Only rebuild what changed

✅ Hermetic Testing
   Tests run in isolated environment

✅ Parallel Execution
   Maximum CPU utilization

✅ Remote Caching
   Share builds across team and CI

✅ Cross-Platform
   Works on macOS, Linux (future)

✅ Scalable
   Handles projects of any size

✅ Fast CI/CD
   Cached builds = faster pipelines

```

## Quick Reference Card

### Most Common Commands

```bash
# Build
./bazel.sh build          # Build debug
./bazel.sh build --release # Build release

# Test
./bazel.sh test           # All tests
./bazel.sh unit-test      # Unit tests only
./bazel.sh ui-test        # UI tests only

# CI
./bazel.sh ci             # Full CI locally

# Clean
./bazel.sh clean          # Clean cache
./bazel.sh deep-clean     # Nuclear option

# Help
./bazel.sh help           # Show all commands
make help                 # Alternative
```

### File Locations

```bash
# Build outputs
bazel-bin/               # Compiled binaries
bazel-out/               # All outputs
bazel-testlogs/          # Test results

# Configuration
WORKSPACE                # Dependencies
BUILD                    # Targets
.bazelrc                 # Build flags

# CI
.github/workflows/bazel-ci.yml  # Pipeline
```

### Debugging

```bash
# Verbose build
bazelisk build --verbose_failures //:PoemOfTheDay

# Show what's being built
bazelisk build --explain=explain.txt //:PoemOfTheDay

# Profile build
bazelisk build --profile=profile.json //:PoemOfTheDay
bazelisk analyze-profile profile.json
```
