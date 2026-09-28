# Remote certificate pinning on iOS

Configure the public integration key copied from **Configuration → Certificate
pins → your subdomain**, after an administrator has generated its signing key
and published a pinset. The key is public; distribute it through trusted app
configuration. Use the application's API token, never an owner's token.

```objc
TwinPushManager *twinPush = [TwinPushManager manager];
twinPush.serverSubdomain = @"your-subdomain";
NSError *error = [twinPush enableCertificatePinning:@"tp-pinning-v1:YOUR_43_CHARACTER_BASE64URL_FINGERPRINT_HERE"];
if (error) {
    // Configuration error: stop initialization and report it to your application.
    return;
}
[twinPush setupTwinPushManagerWithAppId:@"YOUR_APP_ID"
                              apiKey:@"YOUR_APP_TOKEN"
                            delegate:self];
```

Replace the entire placeholder with the copied key. No PEM file, TLS pin,
environment, key ID or additional endpoint URL is supplied by the application.
The exact API is `- (NSError *)enableCertificatePinning:(NSString *)key` on
`TwinPushManager`. `nil` means the key format was accepted and remote mode was
activated, **not** that bootstrap has succeeded. Invalid input returns an error
immediately without changing the current mode. This includes noncanonical
Base64URL. Treat that error as a configuration failure rather than proceeding
with setup. Activation must run on the main thread, like the SDK's initialization
and request lifecycle APIs.

Call it **before setup**, because setup can send a device-registration request.
The domain can be assigned before activation or before setup. Activation records
the trust anchor immediately; bootstrap starts asynchronously once domain, app ID
and token are available. Requests wait up to 25 seconds for an authenticated,
nonexpired pinset, then use their existing error callbacks if unavailable.
Security errors use `com.twinpush.CertificatePinning`. A request cancelled while
waiting does not invoke its success/error callback. No request is automatically
replayed after a pin mismatch, including POST, PUT and DELETE.

## Scope and compatibility

The iOS SDK uses Objective-C, `TPRequestFactory`, `TPRequestLauncher` and
`NSURLConnection`, not Android Volley. The opt-in remote mode routes the same
requests and callbacks through an isolated `NSURLSession` transport. Device
registration, inbox/list/detail requests, badges, custom properties and statistics
all use this launcher. There are no new dependencies and the minimum remains
iOS 11. Security and CommonCrypto are supplied by Apple.

Without activation the existing transport is unchanged. `TwinFormsManager` has
its own launcher and configuration; this API does not enable remote pinning for
that separate service. Notification rich content loaded in `WKWebView` is not a
TwinPush API request and is not covered by this API.

Activation applies to requests launched afterward. Already dispatched legacy
requests can finish under their original policy, and may already have transmitted
data. They are **not** retroactively protected. Applications needing a strict
startup boundary must activate before setup/first request.

Repeated calls with the same key are idempotent and request a refresh subject to
backoff. A different valid key invalidates the old controller. Changing domain,
application or token cancels operations of the old remote configuration and
starts an independent bootstrap. Old asynchronous results cannot install state
in the new configuration. A queued request whose origin does not match fails.
Reactivation/key changes do not remove historical version records. The integration
key authenticates the complete environment, including its hostname; a new domain
usually requires an independently supplied new integration key.

The former certificate-name pinning API has been removed. Applications migrating
from it must remove those calls and activate remote pinning before setup. Bootstrap
and ordinary requests continue to require platform CA and hostname validation.
Remote mode never honors `allowUnsafeCertificate`.

## Verification and transport

Only the internal bootstrap creates these exact authenticated GET requests:

- `/api/v2/apps/:app_id/certificate_pins/verification_key`
- `/api/v2/apps/:app_id/certificate_pins`

The SDK's configured HTTPS origin and app token are used. The server contract
explicitly supports v2 independently of the existing SDK API version. Both
responses are capped at 16 KiB while streaming; advertised oversize bodies are
rejected before reading. All redirects are rejected, including same-origin ones.
There is no path-matching bypass on ordinary requests and no caller-selectable
bootstrap flag. HTTP 403, 404 and 503 cannot disable pinning.

The verification key is accepted only after authenticating the environment-bound
SPKI fingerprint against the integration key and checking the SPKI-derived key ID.
Strict JSON parsing detects duplicate decoded keys before insertion, rejects
unknown fields/types, and preserves integer precision. PEM contains one public
RSA SPKI with canonical DER, a 2048–8192-bit modulus and no trailing material.
The pin document is verified using Apple's RSA PKCS#1 v1.5/SHA-256 implementation
against the contract's LF-separated canonical bytes, including the final LF.
Version, expiry, ASCII ordering, unique pins and canonical Base64 are mandatory.

For ordinary requests the transport evaluates platform trust with the expected
TLS hostname, then hashes the **leaf certificate's original DER SPKI**, not a
re-encoded raw RSA/EC key or an intermediate/root key. At least one current pin
must match before the authentication challenge authorizes HTTP transmission.
Each ordinary operation owns a new ephemeral session, avoiding connection-pool
reuse across requests or revisions; it has no shared cookie, credential or HTTP
cache. This costs additional TLS handshakes. Sessions are invalidated at completion.
Ordinary responses are capped at 16 MiB in remote mode.

A new signed payload cancels in-flight operations using the previous one;
expiration also schedules cancellation. Validity is checked before dispatch,
during the trust challenge and at completion, as well as on application resume.
Already transmitted bytes cannot be recalled when a policy changes. The SDK
never automatically retries these operations. Platform TLS/session implementation
behavior is also covered by the local HTTPS tests; device/OS release testing
remains appropriate for an SDK release.

## Persistence and recovery

An atomic binary property-list file in Application Support contains the original
signed document, original key response and provisioned public anchor. Files are
separated by hostname, with historical records per authenticated environment.
The signed version and canonical payload are the persistent high-water mark;
equal versions with different canonical bytes and lower versions are rejected.
Changing app or origin prevents using another configuration's cached pinset,
while the environment's rollback floor remains shared across app/key changes.

Loading reauthenticates keys and signatures, including expired historical records
needed for rollback checks. All controllers share a serial queue; commits re-read
and merge persisted version floors before atomic replacement. Corrupt/unreadable
state fails closed rather than resetting the version. Local storage is inside
the application's sandbox; it is not tamper-proof against a compromised device,
application or restored backup. This is not a cross-process shared-app-group store.

Startup refresh is asynchronous. Successful refresh schedules another attempt
at most one hour later or five minutes before expiry (with a 30-second minimum
interval to avoid repeatedly fetching an unchanged, nearly expired revision). Expiry is never extended.
A pin mismatch requests recovery through bootstrap, rate-limited to once per
30 seconds. There is only one refresh per controller, and failures use exponential
backoff capped at five minutes with at most three automatic attempts per failed
burst. Later requests/resume can try again after backoff. A verified, still-current
cache can be used during network errors. Expired or missing state cannot authorize
ordinary traffic. The refresh timer runs only while the application can run;
there is no permanent background service.

Renewing a TLS certificate or moving from GoDaddy to Let's Encrypt does not change
the integration key while the signing key and environment stay the same. Retaining
the TLS public key retains its SPKI pin. Changing TLS keys requires publishing
an overlapping pinset, e.g. `[A] → [A,B] → [B]`. Signing-key rotation requires a
trusted app configuration update; downloading a new `key_id` alone never authorizes it.

First installation and local data deletion have no historical rollback floor.
An older but unexpired, correctly signed document can be replayed in that window.
A restored backup can likewise restore an older floor. Expiry relies on the local
clock; moving it backward can extend acceptance. Signatures do not solve these
cases or guarantee network availability. Do not use the public interoperability
vector's fake TLS pin in production.

## Validation

`Tests/Pinning/run.sh` compiles and runs the actual Foundation/Security transport
on macOS against a local HTTPS server. OpenSSL independently creates test-only
signatures and certificates; the supplied public interoperability vector is
also checked byte-for-byte with an injected 2030 clock. A second process verifies
the persistent rollback floor. No private fixture keys are committed.

`Tests/Pinning/run-ios.sh SIMULATOR_UDID` builds the SDK and runs the suite in an
installed iOS simulator, additionally exercising the real request launcher with
remote mode both disabled and enabled, and the public activation API. The test
transport adds a local test CA only to its own `SecTrust` object before calling
the unchanged production trust evaluation. It does not install a system CA or
compile a trust bypass into the SDK.
