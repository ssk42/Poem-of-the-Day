# App Store Connect Automation

Release automation for Poem of the Day runs on
[`asc`](https://github.com/rorkai/App-Store-Connect-CLI), a scriptable CLI for
the App Store Connect API. It replaces `xcrun altool` and removes the manual
build-number bumps that used to land in `BUILD.bazel`.

## What this gives you

| Capability | Command | Where it runs |
| --- | --- | --- |
| Next safe build number | `asc builds next-build-number` | Bazel CI + `make next-build` |
| Upload + wait for processing | `asc builds upload --wait` | Bazel CI release job |
| TestFlight distribution | `asc publish testflight --group` | Bazel CI release job |
| Listing copy as code | `asc metadata push` | `App Store Metadata` workflow |
| Screenshot upload | `asc screenshots upload` | `App Store Metadata` / `App Store Release` |
| Readiness report | `asc validate` | `App Store Release` workflow |
| Submit for review | `asc publish appstore --submit` | `App Store Release` workflow |

## Install

```bash
brew install asc
asc version
```

## Credentials

Create an API key at
<https://appstoreconnect.apple.com/access/integrations/api>. You need the
**Key ID**, the **Issuer ID**, and the downloaded `AuthKey_XXXX.p8`.

`asc` reads credentials straight from the environment, so no `asc auth login`
step is required in CI. This repo already had App Store Connect secrets under
`APP_STORE_CONNECT_*` names, so `scripts/asc-env.sh` maps them onto the names
`asc` expects rather than requiring you to re-upload anything:

| Repository secret | `asc` variable |
| --- | --- |
| `APP_STORE_CONNECT_KEY_ID` | `ASC_KEY_ID` |
| `APP_STORE_CONNECT_ISSUER_ID` | `ASC_ISSUER_ID` |
| `APP_STORE_CONNECT_API_KEY_BASE64` | `ASC_PRIVATE_KEY_B64` |
| `APP_STORE_CONNECT_APP_ID` | `ASC_APP_ID` |

### One new secret is required

`APP_STORE_CONNECT_APP_ID` — the numeric App Store app ID (the digits in your
App Store Connect URL, e.g. `1234567890`). Everything else already exists.

```bash
asc apps list --output table          # find the ID
gh secret set APP_STORE_CONNECT_APP_ID
```

### Optional repository variable

`TESTFLIGHT_GROUP` — a TestFlight beta group name. When set, the Bazel CI
release job distributes each build to that group; when unset, it uploads and
waits for processing without distributing.

```bash
gh variable set TESTFLIGHT_GROUP --body "Internal Testers"
```

### Local setup

```bash
export APP_STORE_CONNECT_KEY_ID=...
export APP_STORE_CONNECT_ISSUER_ID=...
export APP_STORE_CONNECT_API_KEY_BASE64=$(base64 < AuthKey_XXXX.p8)
export APP_STORE_CONNECT_APP_ID=...

make asc-check
```

## Build numbers are no longer hand-edited

`BUILD.bazel` used to hardcode `CFBundleVersion`, so every release needed a
"bump build version" commit, and the widget's `Info.plist` had to be kept in
sync by hand.

Both now read from Bazel `--define` values declared in `.bazelrc`:

```
build --define=app_version=1.6
build --define=build_number=436
```

The app's generated `Info.plist` and the shared `//:VersionInfoPlist` fragment
(merged into the widget extension) both consume those values, so the app and
its widget can no longer drift apart. CI overrides `build_number` with the
value from `asc builds next-build-number`, which reconciles processed builds
and in-flight uploads:

```bash
bazelisk build --config=release \
  --define=app_version=1.6 \
  --define=build_number=437 \
  //:PoemOfTheDay
```

Bump `app_version` in `.bazelrc` when shipping a new marketing version. Leave
`build_number` alone — it is only a local default.

## Metadata as code

Listing copy lives in `metadata/` and is validated in CI:

```
metadata/
├── app-info/
│   └── en-US.json        # name, subtitle
└── version/
    └── 1.6/
        └── en-US.json    # description, keywords, promotionalText, whatsNew
```

These files were seeded from `AppStoreDescription.md`. URLs
(`marketingUrl`, `supportUrl`, privacy fields) are deliberately absent:
`asc metadata push` treats an omitted field as a no-op, so whatever is live in
App Store Connect is left untouched. To bring the live values under version
control, run `make metadata-pull` and commit the result.

```bash
make metadata-validate   # offline; enforces App Store length limits
make metadata-diff       # dry-run against App Store Connect
make metadata-push       # apply
```

When a new marketing version starts, create `metadata/version/<version>/` —
copying the previous version's files is usually the right starting point.

## Screenshots

Screenshots are stored per device size with a locale subdirectory, which is the
layout `asc` expects for locale fan-out:

```
AppStoreScreenshots/
├── iPhone_6.5/en-US/*.png   # 1242x2688 -> IPHONE_65
└── iPhone_6.3/en-US/*.png   # 1206x2622 -> IPHONE_61
```

```bash
make screenshots-upload
asc screenshots sizes --all   # check required dimensions
```

Uploads use `--replace`, so each run replaces the existing set for that device
type rather than appending to it.

## Workflows

### Bazel CI — `.github/workflows/bazel-ci.yml`

On push to `main` or a `v*` tag: builds, resolves the next build number,
stamps it into the build, uploads to App Store Connect, waits for processing,
and distributes to `TESTFLIGHT_GROUP` if one is configured.

### App Store Metadata — `.github/workflows/asc-metadata.yml`

Pull requests touching `metadata/` get a validation pass and a dry-run diff in
the job summary. Pushes to `main` apply the change. Screenshot upload is
available via manual dispatch.

### App Store Release — `.github/workflows/asc-release.yml`

Manual dispatch. Builds a signed IPA, syncs metadata, previews the publish
plan, then runs `asc publish appstore`. **Submission only happens when the
`submit` input is checked** — otherwise the build is attached to the version
and validated, and a human makes the final call in App Store Connect.

## Local workflows

`.asc/workflow.json` defines multi-step runs for local use:

```bash
asc workflow validate --output json
asc workflow run --dry-run testflight_beta VERSION:1.6
asc workflow run testflight_beta VERSION:1.6 TESTFLIGHT_GROUP:"Internal Testers"
```

A failed run can be resumed without redoing completed steps:

```bash
asc workflow run testflight_beta --resume RUN_ID
```

## Day-to-day commands

```bash
make asc-check            # verify credentials
make next-build           # what build number is next?
make upload               # stamped build -> TestFlight
make release-status       # release pipeline dashboard
make release-check        # submission readiness
make testflight-feedback  # recent tester feedback and crashes
```

## Troubleshooting

**`asc auth status` fails in CI** — check that `APP_STORE_CONNECT_API_KEY_BASE64`
holds the base64 of the `.p8` file with no trailing newline
(`base64 < AuthKey.p8 | tr -d '\n'`).

**`--app is required`** — `APP_STORE_CONNECT_APP_ID` is unset. See above.

**Screenshot dimension rejected** — run `asc screenshots sizes --all` and
confirm the PNGs match exactly; App Store Connect does not resize.

**Build number collision** — `asc builds next-build-number` considers both
processed builds and in-flight uploads, so a rerun after a failed upload
picks the correct next value rather than colliding.
