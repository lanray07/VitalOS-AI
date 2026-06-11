# App Review Resolution Notes

Submission ID: `1634ae45-b290-4737-91d4-e09549f56c76`
Review date: June 10, 2026
Version reviewed: `1.0 (1)`
New binary target: `1.0 (2)`

## Guideline 5.1.1(i) and 5.1.2(i)

Version 1.0 does not send user check-ins, HealthKit data, voice transcripts, profile details, or other personal data to a third-party AI service.

Code changes made:

- Removed the unused remote AI service stub and placeholder third-party endpoint.
- Added an AI privacy disclosure in Settings.
- Added an AI privacy disclosure on the Voice Coach screen before response generation.

Suggested App Review reply:

```text
Thank you for the review. VitalOS AI version 1.0 does not send personal data to any third-party AI service. Check-ins, HealthKit data, voice transcripts, and profile details remain in the app and are used for local educational wellness guidance only. We removed an unused remote AI service placeholder from the binary and added in-app disclosures in Settings and on the Voice Coach screen clarifying that no personal data is sent to a third-party AI provider in version 1.0.

If remote AI processing is added in a future version, VitalOS AI will identify the provider, disclose the data categories, update the privacy policy, and ask for permission before sending personal data.
```

## Guideline 2.1(b) - Purchase flow

Code changes made:

- Replaced the placeholder paywall selection with StoreKit 2 product loading.
- Added real `Product.purchase()` purchase flow.
- Added current entitlement refresh and transaction update handling.
- Added Restore Purchases.
- Added visible error copy if products are unavailable in sandbox/App Store Connect.

Required App Store Connect actions:

- Confirm the Paid Apps Agreement is active.
- Complete missing subscription metadata.
- Upload App Review screenshots for each in-app purchase product.
- Submit the in-app purchase products for review with the new app binary.
- Upload new build `1.0 (2)` after these code changes.

Suggested note for App Review Information:

```text
Subscriptions use StoreKit 2. The paywall loads these product IDs:

- vitalos.premium.monthly
- vitalos.premium.yearly
- vitalos.elite.monthly

The subscription screen is available from Settings > Subscription. Purchase buttons call StoreKit `Product.purchase()` and Restore Purchases calls `AppStore.sync()`.
```
