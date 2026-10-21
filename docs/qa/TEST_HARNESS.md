# Automated test harness

## Targets

- `BOTAITests`: Swift Testing unit tests for repositories, parser, learning and deletion.
- `BOTAIUITests`: XCTest UI smoke tests for fresh launch and relaunch.
- Both are included in the shared `BOTAI` Xcode scheme (`ios/project.yml` is authoritative; regenerate using `cd ios && xcodegen generate`).

## Isolation

The app accepts test-only process arguments (not enabled in normal launches):

- `-botai-ui-testing` redirects the application SQLite database to `Application Support/BOTAI-UITests/learning.sqlite` rather than `Application Support/BOTAI/learning.sqlite`.
- `-botai-reset-ui-test-data` deletes only the isolated `BOTAI-UITests` folder at startup. Never supply it without `-botai-ui-testing`.

This isolates local database content from a normal app launch *inside the same simulator installation*. Each test must explicitly reset before assuming an empty state. The test runner must use a disposable simulator and a test account; this does not isolate Supabase credentials, keychain, user defaults, network state, or remote data. Those require separate handling before any authenticated UI tests.

## Commands

```sh
cd ios
xcodegen generate
xcodebuild -project BOTAI.xcodeproj -scheme BOTAI \
  -destination 'platform=iOS Simulator,id=2322A47B-83E7-42FE-A708-5F1CFA018DBC' \
  -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO test
```

The simulator UUID above is an example from the development Mac; use `xcrun simctl list devices available` to select an available iPhone. Disable parallel test execution until shared resources are isolated. Store `.xcresult` outside the repository.

## Test limitations

- UI smoke tests check launch and relaunch only; they do not establish functional correctness of material, course, learning or sync flows.
- Launch isolation currently covers the main SQLite database only, not all possible persistent app or backend state.
- A successful `build-for-testing` confirms compilation, not test execution.
