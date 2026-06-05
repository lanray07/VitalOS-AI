# iOS GitHub Actions Secrets

The `iOS Xcode` workflow builds VitalOS AI on GitHub-hosted macOS runners.

Required signing secrets:

- `APPLE_TEAM_ID`
- `IOS_DISTRIBUTION_CERTIFICATE_BASE64` or `BUILD_CERTIFICATE_BASE64`
- `IOS_DISTRIBUTION_CERTIFICATE_PASSWORD` or `P12_PASSWORD`
- `IOS_PROVISIONING_PROFILE_BASE64` or `BUILD_PROVISION_PROFILE_BASE64`
- `KEYCHAIN_PASSWORD`

Required TestFlight upload secrets:

- `APP_STORE_CONNECT_API_KEY_ID` or `ASC_KEY_ID`
- `APP_STORE_CONNECT_API_ISSUER_ID` or `ASC_ISSUER_ID`
- `APP_STORE_CONNECT_API_KEY_BASE64` or `ASC_KEY_BASE64`

The certificate should be a base64-encoded `.p12`. The provisioning profile should be a base64-encoded `.mobileprovision`. The App Store Connect API key should be the base64-encoded `.p8` file.
