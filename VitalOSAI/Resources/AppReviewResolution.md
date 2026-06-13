# App Review Resolution Notes

Current submission ID: `382b5f03-d546-4e1b-ae7a-0bf092978a0d`
Review date: June 12, 2026
Version reviewed: `1.0 (2)`
New binary target: `1.0 (3)`

Previous submission ID: `1634ae45-b290-4737-91d4-e09549f56c76`
Previous review date: June 10, 2026

## Required App Store Connect Actions

- Upload a new build with build number `3`.
- Confirm the Paid Apps Agreement is active.
- Complete every subscription product's metadata, pricing, localization, and App Review screenshot.
- Submit the subscription products themselves for App Review with the app version.
- Add this line to the App Description or EULA metadata field:

```text
Terms of Use (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
```

- Confirm the Privacy Policy URL field points to a public, functional privacy policy.
- Attach a screen recording in the App Review reply showing Settings > Subscription, the purchase buttons, Restore Purchases, functional legal links, and HealthKit disclosure in Onboarding or Settings.

## Guideline 2.1(b) - In-App Purchases Not Submitted

Code status:

- StoreKit 2 product loading and purchase flow are implemented.
- Product IDs used by the app:
  - `vitalos.premium.monthly`
  - `vitalos.premium.yearly`
  - `vitalos.elite.monthly`
- The paywall is available from Settings > Subscription.
- Purchase buttons call StoreKit `Product.purchase()`.
- Restore Purchases calls `AppStore.sync()`.

App Store Connect status:

- This rejection cannot be fully resolved in code. The subscriptions must be submitted for review in App Store Connect.
- The `scripts/appstore_metadata.rb` script can create/update subscription metadata and upload App Review screenshots when App Store Connect API credentials are configured.
- The `scripts/appstore_submit.rb` script now defaults to target build `3` and submits eligible subscription products before submitting the app review item.

## Guideline 3.1.2(c) - Subscription Metadata

Code changes made:

- The paywall now shows each subscription's title, duration, and price from StoreKit.
- The paywall now includes functional Privacy Policy and Terms of Use (EULA) links.
- Settings > Legal & Safety now includes functional Privacy Policy and Terms of Use (EULA) links.
- `TERMS_OF_USE.md` now includes the standard Apple Terms of Use (EULA) URL.
- `scripts/appstore_metadata.rb` now appends the Terms of Use (EULA) URL to App Store version descriptions.

## Guideline 2.5.1 - HealthKit UI Identification

Code changes made:

- Onboarding now labels the optional connection as HealthKit (Apple Health).
- Onboarding explains that HealthKit can read steps, active energy, sleep analysis, and resting heart rate after permission.
- Settings > Integrations now labels HealthKit (Apple Health) permissions and repeats the same data-category disclosure.
- Enabling the HealthKit toggle now calls the HealthKit authorization request.

The app imports and uses HealthKit. No CareKit imports were found.

## Suggested App Review Reply

```text
Thank you for the review. We uploaded a new binary, version 1.0 build 3, to address the remaining issues.

For Guideline 2.1(b), the app uses StoreKit 2 for subscriptions with product IDs vitalos.premium.monthly, vitalos.premium.yearly, and vitalos.elite.monthly. The paywall is available at Settings > Subscription, purchase buttons call Product.purchase(), and Restore Purchases calls AppStore.sync(). We also submitted the subscription products for App Review with their required App Review screenshots.

For Guideline 3.1.2(c), the paywall now shows each subscription title, duration, and price, and includes functional Privacy Policy and Terms of Use (EULA) links. The same legal links are also available in Settings > Legal & Safety. The App Store metadata includes the Terms of Use (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/

For Guideline 2.5.1, VitalOS AI now clearly identifies HealthKit (Apple Health) functionality in Onboarding and Settings. The app explains that HealthKit can read steps, active energy, sleep analysis, and resting heart rate after permission to support educational wellness insights.

VitalOS AI version 1.0 does not send check-ins, HealthKit data, voice transcripts, profile details, or other personal wellness data to a third-party AI service. Responses are generated in the app from local educational wellness rules.
```
