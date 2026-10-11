# Release builds and versioning

## APK names

CI names every APK `wyrmbreaker-v<VERSION>-build<N>.apk`:

- `<VERSION>` comes from the [`VERSION`](../VERSION) file. Bump it when you
  ship something notable, e.g. `0.5.0` → `0.6.0`.
- `<N>` is the GitHub Actions run number. It increases on every push and is
  also used as the Android `versionCode`, so newer builds always install over
  older ones.

The same version shows at the bottom of the home screen.

## Release signing

Android only installs signed APKs. A **release** APK must be signed with your
own key, and every future update (especially on Google Play) must use the
**same key**.

CI builds a signed **release** APK when these three repository secrets exist
(Settings → Secrets and variables → Actions):

| Secret | Value |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | The keystore file, base64-encoded on one line |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore and key password |
| `ANDROID_KEY_ALIAS` | Key alias (`wyrmbreaker`) |

Without them, CI falls back to a debug-signed APK named `...-debug.apk` and
shows a warning in the run.

**Never commit the keystore or its password.** `.gitignore` blocks
`*.keystore`. Keep a backup somewhere safe.

To make a new key yourself (requires a JDK):

```sh
keytool -genkeypair -v -keystore wyrmbreaker-release.keystore -alias wyrmbreaker \
  -keyalg RSA -keysize 2048 -validity 10000
base64 -w0 wyrmbreaker-release.keystore   # paste this into ANDROID_KEYSTORE_BASE64
```

Note: Android won't install a release build over a debug build of the same
app (different signatures). Uninstall the old debug version once first.
