# PayU CheckoutPro Integration Guide (iOS)

This app is wired for **PayU CheckoutPro SDK** (not hosted web checkout).

## 1) Add CheckoutPro SDK package

Add Swift Package in Xcode:

- URL: `https://github.com/payu-intrepos/PayUCheckoutPro-iOS`
- Add to app target: `Clevertap Sample App`

## 2) Add required `Info.plist` keys (app target)

- `PAYU_MERCHANT_KEY` = merchant key
- `PAYU_HASH_ENDPOINT` = backend endpoint for hash generation
- `PAYU_ENVIRONMENT` = `test` or `production`
- `PAYU_SUCCESS_URL` = success URL configured with PayU
- `PAYU_FAILURE_URL` = failure URL configured with PayU

Optional:

- `PAYU_USER_CREDENTIAL_PREFIX` = merchant key/identifier prefix for saved cards
- `PAYU_MERCHANT_DISPLAY_NAME` = name shown on checkout

## 3) Backend hash API (mandatory)

SDK hash callback sends these fields to backend:

```json
{
  "hashName": "payment_related_details_for_mobile_sdk",
  "hashString": "....",
  "postSalt": "....",
  "transactionId": "...."
}
```

Backend response:

```json
{
  "hash": "generated_hash"
}
```

Important:

- Never put salt/salt-v2/private key in app.
- Generate hash only on backend.

## 4) Runtime flow in this app

- User selects `PayU (Online)` in checkout.
- App opens CheckoutPro SDK.
- On payment success: order is placed in Firestore.
- On failure/cancel: order is not placed.

## 5) Production checklist

- `PAYU_ENVIRONMENT = production`
- production merchant key
- production hash backend using production salt-v2
- callback URLs configured in PayU dashboard
