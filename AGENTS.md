# Repository guidance

## Project layout

- `TwinPushSDK/` contains the Objective-C SDK. `Classes/TwinPushManager.h` is the main public API; `Classes/Communications/` contains request creation and transport; `Classes/Entities/` contains models; `ViewControllers/` contains inbox and detail UI.
- `TwinPushSDK.xcodeproj` builds the SDK as a static library. `TwinPushSDKDemo/` is a separate sample application.
- `TwinPushSDK.podspec` defines the CocoaPods distribution, source files, public and private headers, frameworks, and minimum iOS version. Keep it aligned with changes to SDK sources and the Xcode project.
- `readme.md` documents integration. `docs/` contains detailed feature guidance. `Tests/Pinning/` contains the local certificate-pinning harness.

## Working conventions

- Match the surrounding Objective-C style and preserve the SDK's existing public API unless the task calls for an API change.
- Keep SDK behavior compatible with the minimum iOS version declared in the podspec and Xcode project (currently iOS 11).
- When adding SDK source files, include them in the Xcode target and verify that the podspec includes them with the intended header visibility.
- Treat certificate pinning, TLS trust, request cancellation, and persisted security state as security-sensitive behavior. Consult `docs/remote-certificate-pinning.md` before changing those paths.
- Do not overwrite unrelated working-tree changes. Check `git status` before editing and review the diff afterward.

## Validation

- For SDK changes, build with `xcodebuild -project TwinPushSDK.xcodeproj -scheme TwinPushSDK -sdk iphonesimulator -configuration Debug CODE_SIGNING_ALLOWED=NO build` when an iOS SDK is available.
- For certificate-pinning changes, run `Tests/Pinning/run.sh` on macOS. With an installed iOS simulator, run `Tests/Pinning/run-ios.sh SIMULATOR_UDID` as well.
- Report which checks ran and any environment limitation that prevented a check.
