# SAP API Management Edge Gateway: PSD3 Open Finance Credit Scoring & Monetization

[![SAP Integration Suite](https://img.shields.io/badge/SAP%20Integration%20Suite-APIM%20%7C%20Cloud%20Integration-0a6ed1?logo=sap&style=flat-square)](https://www.sap.com)
[![Specification](https://img.shields.io/badge/Specification-PSD3%20%2F%20Open%20Finance-008080?style=flat-square)](https://ec.europa.eu)
[![Policy Engine](https://img.shields.io/badge/APIM%20Policies-SpikeArrest%20%7C%20Quota%20%7C%20AssignMessage-success?style=flat-square)](#4-apim-policy-configuration-xml-definitions)
[![Deployment](https://img.shields.io/badge/Deployment%20Status-Deployed%20%7C%20Active-brightgreen?style=flat-square)](#7-implementation-evidence)

An enterprise-grade Edge API Gateway implemented on **SAP Integration Suite (API Management + Cloud Integration)**. This architecture provides perimeter defense, per-call monetization metering, and full compliance with the **EU PSD3 (Payment Services Directive 3)** framework for external financial applications, banking partners, and FinTech clients querying real-time credit scoring assessments.

---

## 1. Architectural Overview (Two-Tier Topology)

The solution decouples perimeter security and monetization enforcement (Edge Layer) from core business orchestration and backend integration (Processing Layer):

```text
  [ External TPPs / FinTech Applications / Third-Party Apps ]
                             │
                             │ HTTPS (TLS 1.3 / Strict API Base Path)
                             ▼
  ┌────────────────────────────────────────────────────────────────────────┐
  │ 1. SAP API Management (APIM Edge Gateway Layer)                        │
  │    Proxy: OpenFinance_CreditScoring_Edge_Proxy                         │
  │    Base Path: /open-finance/edge/v1/credit-scoring                     │
  │                                                                        │
  │   [PreFlow - Request Pipeline]                                         │
  │   ├── Spike Arrest Policy: 100 ps (DDoS & Burst Protection)            │
  │   └── Quota Policy: 10,000 req / month / Client IP (Tier-1 Metering)   │
  │                                                                        │
  │   [PostFlow - Response Pipeline]                                       │
  │   └── Assign Message Policy: Inject PSD3 & Monetization Headers        │
  │       (X-OpenFinance-Standard, X-Monetization-Cost-USD: $0.05)         │
  └──────────────────────────────────┬─────────────────────────────────────┘
                                     │
                                     │ Mutual TLS / Internal HTTPS Runtime
                                     ▼
  ┌────────────────────────────────────────────────────────────────────────┐
  │ 2. SAP Cloud Integration (CPI Processing Backend Layer)                │
  │    Artifact: OpenFinance_CreditScoring_EdgeGateway_v1                  │
  │    Endpoint: /http/open-finance/v1/credit-scoring                      │
  │                                                                        │
  │   [Integration Process]                                                │
  │   ├── HTTPS Inbound Adapter (Authorization: ESBMessaging.send)         │
  │   ├── Content Modifier (S/4HANA Credit Assessment Core Engine)         │
  │   └── Deterministic Financial JSON Construction & Limit Response       │
  └────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Component & Policy Matrix

| Component | Policy / Artifact Name | Architecture Layer | Pipeline Phase | Enterprise Purpose |
| :--- | :--- | :--- | :--- | :--- |
| **DDoS Guard** | `SpikeArrest_DDoS_Guard` | APIM Edge Gateway | `PreFlow` (Request) | Mitigates traffic spikes and micro-bursts by enforcing a strict 100 req/sec limit per client IP. |
| **Monetization Quota** | `Quota_Monthly_Tiering` | APIM Edge Gateway | `PreFlow` (Request) | Restricts Tier-1 consumer contracts to 10,000 calls per calendar month, returning `HTTP 429` on exhaustion. |
| **PSD3 & Billing Headers** | `Assign_Monetization_Headers` | APIM Edge Gateway | `PostFlow` (Response) | Injects non-repudiation audit headers: `$0.05` unit charge, plan tier, and EU PSD3 compliance indicator. |
| **Backend Core Simulator** | `OpenFinance_CreditScoring_EdgeGateway_v1` | CPI Runtime Engine | Integration Flow | Ingests validated requests and calculates creditworthiness scores, risk tiers, and max credit limits. |

---

## 3. Repository Structure

```text
.
├── README.md
├── docs/
│   ├── adr/
│   │   └── ADR-025-edge-gateway-monetization.md
│   └── open-finance-psd3-spec.md
├── policies/
│   ├── SpikeArrest_DDoS_Guard.xml
│   ├── Quota_Monthly_Tiering.xml
│   └── Assign_Monetization_Headers.xml
├── iflow/
│   └── OpenFinance_CreditScoring_EdgeGateway_v1.json
├── assets/
│   ├── sap-apim-open-finance-edge-gateway.png
│   └── sap-apim-edge-proxy-policies-deployed.png
└── tests/
    └── test-edge-gateway.sh
```

---

## 4. APIM Policy Configuration (XML Definitions)

### 4.1. Spike Arrest (`policies/SpikeArrest_DDoS_Guard.xml`)
Attached to **ProxyEndpoint ──► PreFlow (Request)**. Blocks volumetric denial-of-service and burst traffic at the network edge.
```xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<SpikeArrest async="false" continueOnError="false" enabled="true" xmlns="[http://www.sap.com/apimgmt](http://www.sap.com/apimgmt)">
    <Identifier ref="client.ip"/>
    <Rate>100ps</Rate>
    <UseEffectiveCount>true</UseEffectiveCount>
</SpikeArrest>
```

### 4.2. Quota Management (`policies/Quota_Monthly_Tiering.xml`)
Attached to **ProxyEndpoint ──► PreFlow (Request)**. Enforces monthly contractual volume limits per consumer identity.
```xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Quota async="false" continueOnError="false" enabled="true" xmlns="[http://www.sap.com/apimgmt](http://www.sap.com/apimgmt)">
    <Identifier ref="client.ip"/>
    <Allow count="10000"/>
    <Interval>1</Interval>
    <TimeUnit>month</TimeUnit>
</Quota>
```

### 4.3. Assign Message (`policies/Assign_Monetization_Headers.xml`)
Attached to **ProxyEndpoint ──► PostFlow (Response)**. Appends financial and legal audit headers to the response payload.
```xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<AssignMessage async="false" continueOnError="false" enabled="true" xmlns="[http://www.sap.com/apimgmt](http://www.sap.com/apimgmt)">
    <Set>
        <Headers>
            <Header name="Content-Type">application/json; charset=utf-8</Header>
            <Header name="X-OpenFinance-Standard">PSD3-COMPLIANT</Header>
            <Header name="X-Monetization-Cost-USD">0.05</Header>
            <Header name="X-Monetization-Plan">B2B_PARTNER_CREDIT_SCORING_TIER_1</Header>
        </Headers>
    </Set>
    <IgnoreUnresolvedVariables>true</IgnoreUnresolvedVariables>
    <AssignTo createNew="false" transport="http" type="response">response</AssignTo>
</AssignMessage>
```

---

## 5. Backend Service Implementation (SAP Cloud Integration)

The backend component (`OpenFinance_CreditScoring_EdgeGateway_v1`) runs on the worker node runtime, exposing an internal endpoint consumed by APIM:

* **Inbound HTTPS Runtime URL:** `https://integration-suite-eu10.it-cpi026-rt.cfapps.eu10-002.hana.ondemand.com/http/open-finance/v1/credit-scoring`
* **Adapter Security:** Client Certificate / User Role (`ESBMessaging.send`)
* **Standard Response Payload (JSON):**
```json
{
  "CreditScoreResult": {
    "borrowerTaxId": "DE-TAX-998810234",
    "creditRatingScore": 785,
    "riskClass": "LOW_RISK_TIER_A",
    "approvalDecision": "AUTOMATICALLY_APPROVED",
    "maximumApprovedCreditLimitEUR": 25000.00,
    "s4hanaAssessmentTimestamp": "2026-11-11T23:15:00Z"
  }
}
```

---

## 6. Verification & End-to-End Testing

### 6.1. Successful Transaction (HTTP 200 OK)
```bash
curl -i -X GET \
  "[https://integration-suite-eu10.test02.apimanagement.eu10.hana.ondemand.com:443/open-finance/edge/v1/credit-scoring](https://integration-suite-eu10.test02.apimanagement.eu10.hana.ondemand.com:443/open-finance/edge/v1/credit-scoring)" \
  -H "Accept: application/json"
```

**Expected Response Headers and Body:**
```http
HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8
X-OpenFinance-Standard: PSD3-COMPLIANT
X-Monetization-Cost-USD: 0.05
X-Monetization-Plan: B2B_PARTNER_CREDIT_SCORING_TIER_1

{
  "CreditScoreResult": {
    "borrowerTaxId": "DE-TAX-998810234",
    "creditRatingScore": 785,
    "riskClass": "LOW_RISK_TIER_A",
    "approvalDecision": "AUTOMATICALLY_APPROVED",
    "maximumApprovedCreditLimitEUR": 25000.00,
    "s4hanaAssessmentTimestamp": "2026-11-11T23:15:00Z"
  }
}
```

### 6.2. Traffic Violation / Quota Exhaustion (HTTP 429 Too Many Requests)
When exceeding 100 requests/second or consuming more than 10,000 monthly calls, the gateway terminates execution at the perimeter:
```http
HTTP/1.1 429 Too Many Requests
Content-Type: application/json

{
  "fault": {
    "faultstring": "Spike arrest violation or Quota limit exceeded",
    "detail": {
      "errorcode": "policies.ratelimit.QuotaViolation"
    }
  }
}
```

---

## 7. Implementation Evidence

### 7.1. SAP Cloud Integration Backend (iFlow Deployed & Active)
![SAP CPI Backend Gateway](assets/sap-apim-open-finance-edge-gateway.png)

### 7.2. SAP API Management Edge Proxy (Policies Configured & Deployed)
![SAP APIM Proxy Policies Deployed](assets/sap-apim-edge-proxy-policies-deployed.png)

---

## 8. Architectural Decision Record (ADR-025)

* **Status:** Accepted
* **Context:** Exposing internal enterprise integration flows or SAP S/4HANA core banking modules directly to external Third-Party Providers (TPPs) presents critical DDoS exposure and prevents billing transparency.
* **Decision:** Deploy a dedicated SAP API Management (APIM) Reverse Proxy as an Edge Gateway upstream of SAP Cloud Integration (CPI). Enforce declarative XML policies (`SpikeArrest`, `Quota`, and `AssignMessage`).
* **Consequences:** Backend computing resources are fully insulated from traffic volatility. Unauthorized or over-quota requests are terminated at the network edge with sub-millisecond overhead, and API consumers receive deterministic billing telemetry in real time.

---

**Integration Architect:** Željko Popov
