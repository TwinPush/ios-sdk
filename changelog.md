# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]
- Implemented method for setting enum properties to the device.

## [3.4.0] - 2017-10-17
### Added
- TwinPushManager data storage can now be overriden by the TwinPushManagerDelegate implementation.

## [3.3.0] - 2017-10-04
### Changed
- Device inbox, alias inbox and notification details request now take a new error block parameter to react to request failures.
- Notification inbox and notification details controllers have been adjusted to the new API and error handling can be easily extended while maintaining the same behaviour by default.

## [3.2.1] - 2017-09-06
### Fixed
- Fixed `#ifdef` check for XCode 8 to work with previous versions of XCode even when XCode 8 has been already installed

## [3.2.0] - 2017-07-20
### Changed
- Alias inbox now uses `TPInboxNotification`, that extends `TPNotification` with an additional opened date field
- Demo project now uses alias inbox and shows unread notifications in bold font

## [3.1.0] - 2017-06-23
### Fixed
- Fixed default notification details view not showing the content URL correctly

### Changed
- Changed default design for notification details view, featuring only a flat close button


## [3.0.0] - 2017-06-12
### Fixed
- Fixed crash when receiving notification with complex alert dictionary instead of plain string from APNS.

### Added
- Added support for `UserNotifications` framework for iOS 10+ devices.

#### Demo project
- Added notification service extension target with sample code for rich notification attachments.
- Added sample code for custom notification categories and actions.
- Added sample code for handling custom action responses.


## [2.2.0] - 2016-08-16
### Added
- Added functionality to delete inbox notifications using `deleteNotification:` method of alias inbox view controller.

## [2.1.0] - 2016-08-11
### Added
- Included alias inbox functionality

## [2.0.2] - 2016-04-13
### Changed
- Reverted changes to intermediate certificate names
- Improved automatic modal view discovery of notification detail view
- Notification inbox sections enum is now public to allow easier customization of notification inbox subclasses

### Fixed
- Notification detail view will no longer dismiss itself when an error occurs


## [2.0.1] - 2016-04-08
### Changed
- Updated default intermediate certificate names for certificate pinning functionality

## [2.0.0] - 2016-03-31
### Added
- Created `changelog.md` file to keep track of version changes
- By default `TwinPushManager` will automatically reset the application badge count on application open and notification reception unless `autoResetBadgeNumber` property is set to `NO`.
- Added `autoRegisterForRemoteNotifications` property to disable automatic remote notifications permission request on startup.
- `registerForRemoteNotifications` method is now public to manually request for user permission if `autoRegisterForRemoteNotifications` is set to `NO`.
- Notification detail webview will now open the content URL in Safari if an App Transport Policy error is received while showing it

### Changed
- `TwinPushManager` will now subscribe to `NSNotificationCenter` application notifications, making unneccessary to call application lifecycle methods directly.
- `TwinPushManager` methods `application:didFinishLaunchingWithOptions`, `applicationDidBecomeActive`, `applicationWillResignActive` and `applicationDidEnterBackground` are deprecated and will be removed in a future SDK release.

### Deleted
- Removed Region Monitoring selector from demo project


## [1.5.0] - 2015-12-03
### Added
- Register request will now send static device and user properties (device model, iOS version, locale, etc)
- A new API Hash will be stored to check if 'static' parameters change to discard cached values and force a new register in the platform
- iPhone 6 and iPhone 6 plus screen compatibility in Demo project
- Added complete documentation to readme file

### Changed
- Project migrated to XCode 6

## [1.4.0] - 2015-07-02
### Added
- Added iOS 8 location permissions handling
- Added 'always' permission request when using significant location changes functionality

### Changed
- Refactor statistics methods to make them more readable and reusable

### Fixed
- Custom properties in received notifications are now parsed correctly into the `TPNotification` object

### Deleted
- Removed region location monitoring functionality


## [1.3.0] - 2015-03-06
### Added
- Added Swift support
- Convenience method for changing the server subdomain
- Improved in-code documentation for `TwinPushManager`

### Changed
- Adapted all requests to the new TwinPush public API specs
- `TwinPushManager` will only send register requests when strictly required
- Deployment target bumped to 7.0

### Fixed
- Minor compilation warnings due to iOS 7 deprecations

## [1.2.0] - 2014-11-10
### Added
- Added TwinForms SDK
- Added iOS 8 notification request permission handling
- Added fine-grained error handling on notification details view

### Fixed
- Minor compilation warnings for 64bit devices

## [1.1.0] - 2014-06-12
### Added
- Implemented certificate pinning verification
- Device UDID is now configurable

### Changed
- Device UDID now defaults to `identifierForVendor`
- Replaced **ASIHTTP** in favour of `NSURLConnection` for WS requests
- Replaced **JSONKit** in favour of `NSJSONSerialization` for JSON handling

### Deleted
- Removed **OpenUDID** framework dependency
- Removed **ASIHTTP** framework dependency
- Removed **JSONKit** framework dependency


## 1.0.0 - 2014-05-20
### Added
- First fully functional public release.

[Unreleased]: https://github.com/TwinPush/ios-sdk/compare/v3.4.0...HEAD
[3.4.0]: https://github.com/TwinPush/ios-sdk/compare/v3.3.0...v3.4.0
[3.3.0]: https://github.com/TwinPush/ios-sdk/compare/v3.2.1...v3.3.0
[3.2.1]: https://github.com/TwinPush/ios-sdk/compare/v3.2.0...v3.2.1
[3.2.0]: https://github.com/TwinPush/ios-sdk/compare/v3.1.0...v3.2.0
[3.1.0]: https://github.com/TwinPush/ios-sdk/compare/v3.0.0...v3.1.0
[3.0.0]: https://github.com/TwinPush/ios-sdk/compare/v2.2.0...v3.0.0
[2.2.0]: https://github.com/TwinPush/ios-sdk/compare/v2.1.0...v2.2.0
[2.1.0]: https://github.com/TwinPush/ios-sdk/compare/v2.0.2...v2.1.0
[2.0.2]: https://github.com/TwinPush/ios-sdk/compare/v2.0.1...v2.0.2
[2.0.1]: https://github.com/TwinPush/ios-sdk/compare/v2.0.0...v2.0.1
[2.0.0]: https://github.com/TwinPush/ios-sdk/compare/v1.5.0...v2.0.0
[1.5.0]: https://github.com/TwinPush/ios-sdk/compare/v1.4.0...v1.5.0
[1.4.0]: https://github.com/TwinPush/ios-sdk/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/TwinPush/ios-sdk/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/TwinPush/ios-sdk/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/TwinPush/ios-sdk/compare/v1.0.0...v1.1.0