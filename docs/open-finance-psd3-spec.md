# EU PSD3 & Open Finance Credit Scoring API Specification

## Endpoint Definition
- **Gateway Base Path:** `/open-finance/edge/v1/credit-scoring`
- **Target Backend Path:** `/http/open-finance/v1/credit-scoring`
- **Protocol:** HTTPS (TLS 1.3)
- **Method:** `GET`

## Compliance & Monetization Response Headers
| Header Name | Value | Description |
| :--- | :--- | :--- |
| `X-OpenFinance-Standard` | `PSD3-COMPLIANT` | Confirms adherence to EU PSD3 data access and transparency standards. |
| `X-Monetization-Cost-USD` | `0.05` | Unit transaction fee billed per successful API evaluation. |
| `X-Monetization-Plan` | `B2B_PARTNER_CREDIT_SCORING_TIER_1` | Active commercial tier governing monthly quota allocation. |
