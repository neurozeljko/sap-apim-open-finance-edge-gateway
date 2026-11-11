# ADR-025: Edge Gateway Traffic Management & API Monetization for Open Finance

## Status
Accepted & Deployed

## Context
Exposing SAP Cloud Integration flows or S/4HANA core banking services directly to external Open Finance Third-Party Providers (TPPs) introduces severe denial-of-service risks, unthrottled compute consumption, and a lack of per-transaction billing visibility.

## Decision
Implement a dedicated SAP API Management Reverse Proxy (`OpenFinance_CreditScoring_Edge_Proxy`) as a perimeter Edge Gateway upstream of SAP Cloud Integration (`OpenFinance_CreditScoring_EdgeGateway_v1`):
1. Enforce `SpikeArrest_DDoS_Guard` (`100ps` per `client.ip`) in `ProxyEndpoint -> PreFlow (Request)` to mitigate burst and DDoS traffic.
2. Enforce `Quota_Monthly_Tiering` (`10,000` requests/month per `client.ip`) in `ProxyEndpoint -> PreFlow (Request)` to govern Tier-1 B2B consumer SLAs.
3. Enforce `Assign_Monetization_Headers` in `ProxyEndpoint -> PostFlow (Response)` to inject EU PSD3 compliance indicators and per-call metering headers (`$0.05 USD`).

## Consequences
- **Security & Resilience:** Backend integration worker nodes are completely insulated from traffic volatility and volumetric attacks.
- **Cost Governance:** Over-quota and burst traffic are rejected at the network edge with `HTTP 429 Too Many Requests` without consuming CPI message processing units.
- **Regulatory & Billing Readiness:** Every successful API response carries standardized EU PSD3 compliance metadata and unit-cost billing headers for downstream financial reconciliation.
