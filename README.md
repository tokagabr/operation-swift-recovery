# 🛡️ Operation Swift Recovery — Cyberstorm Attack Analysis

> A forensic analysis of a real-world-style multi-vector cyber attack on a financial institution, built as a complete incident response simulation.

---

## 📌 Project Overview

**Operation Swift Recovery** is a data-driven cybersecurity incident analysis project simulating a coordinated multi-vector attack on **GlobalTrust Bank** — March 15, 2024 (02:00–05:00 UTC).

The project answers one core question:  
**Was this a planned, coordinated attack — or random internet noise?**  
The data answers it conclusively.

---

## 📊 Attack Statistics at a Glance

| Metric | Value |
|---|---|
| Total Attack Events | 15,500 |
| Unique Attacker IPs | 550 |
| Countries Involved | 13 |
| Attack Duration | 3 hours |
| Customers Affected | 340,000 |
| Direct Financial Loss | $890,000 |
| Overall Block Rate | 88.4% |

---

## 🔍 Analysis Scope (11 Questions Answered)

### Q1 — Proof of Coordination
- All 5 attack vectors launched within **27.8 seconds** of each other
- **74.9%** of IPs used all 5 attack types simultaneously
- Attack followed structured phases: buildup → peak → retreat

### Q2 — Frequency vs. Danger
- Most frequent: **DDoS SYN Flood** (~5,000 events)
- Most dangerous: **SQL Injection** (19× more impactful than DDoS)
- SQL WAF bypass rate: **24.2%** — 1 in 4 requests passed through

### Q3 — Peak Timing & Attacker Intent
- Peak at **02:58 UTC** — 178 events/minute (4.1× above average)
- Timed to exploit minimum overnight SOC staffing
- 4-phase attack structure with a controlled retreat at 04:30 UTC

### Q4 — Geography & Attack Origin
- **Russia** = top source (22.6% of attacks, avg threat score 75.5)
- RU + CN + KP + IR combined = **36.3%** of all traffic
- 13 countries mapped via IP geolocation analysis

### Q5 — Anonymization (Correct Set Union Method)
- **55%** of attackers used at least one anonymization tool
- TOR: 40.5% | Proxy: 18.1% | VPN: 2.8%
- 995 IPs used multiple tools simultaneously (overlap corrected via Set Union)

### Q6 — State-Sponsored Activity Indicators
- 77 IPs linked to known APT groups (15% of all traffic)
- All 6 professional APT indicators present (timing, targeting, techniques, clustering)
- Confidence level: **Moderate** — cannot confirm specific nation without additional signals

### Q7 — Top 10 Most Dangerous IPs
- Ranked by composite threat score (attack volume × success rate × APT flag × anonymization)
- Top IP: `123.160.109.221` (RU) — 1,306 attacks, dominated by SQL injection

### Q8 — Campaign or Coincidence?
- **Verdict: ONE organized campaign**
- All attackers active for the same duration with synchronized start/stop times

### Q9 — ISP-Level Response
- **PJSC MegaFon (RU)**: Fully blocked
- **Rostelecom**: Rate-limited + monitored
- Others: Monitored only (to avoid false positives for legitimate users)

### Q10 — Service Restoration Priority
- **High-risk (delayed restore)**: Core Banking DB (578 breaches), Auth Service (471 breaches)
- **Low-risk (early restore)**: Internal tools with minimal threat scores

### Q11 — IP Blocking Criteria (3-Tier System)
| Tier | Criteria | IPs Affected |
|---|---|---|
| Permanent Block | Threat Score > 70 or APT_SUSPECTED | 157 IPs |
| 30-Day Block | Threat Score > 50 + High Volume | 37 IPs |
| Monitor Only | Low-risk traffic | 356 IPs |

---

## 🔧 Remediation Plan

| Priority | Fix | Cost | Timeline |
|---|---|---|---|
| 🔴 Critical | Tune WAF rules for SQL Injection | $50K | 1 month |
| 🔴 Critical | Hire dedicated night-shift SOC staff | $200K/yr | 3 months |
| 🟠 High | Upgrade DDoS protection capacity | $150K/yr | 1 month |
| 🟠 High | Anomaly detection on Core Banking DB | $150K | 3 months |
| 🟡 Medium | APT Threat Intelligence Feed subscription | $75K/yr | 2 months |
| 🟡 Medium | Automate geo-blocking rules | $20K | 2 weeks |

**Total investment: $575K → reduces repeat-attack risk from 40% to <10%**

---

## 🧰 Tools & Technologies

- **Python** — data analysis, statistical modeling
- **Pandas / NumPy** — data wrangling and aggregation
- **Matplotlib / Seaborn** — attack visualization and charting
- **Jupyter Notebook** — interactive analysis environment
- **IP Geolocation APIs** — country and ISP mapping
- **Set theory (Union logic)** — correct anonymization rate calculation

---

## 📁 Repository Structure

```
operation-swift-recovery/
│
├── operation_swift_recovery.ipynb   # Full analysis notebook
├── README.md                        # This file
└── presentation/
    └── Cyberstorm_Attack_Analysis.pdf  # Slide deck (board-ready)
```

---

## 👥 Team

| Name | Role |
|---|---|
| Toka Gbr | Attack timeline & phase analysis |
| Jana Mohamed | Geography & ISP investigation |
| Toka Mohamed | Anonymization & APT indicators |
| Nour Gomaa | Danger scoring & remediation plan |
| Saleh Hossam | Service restoration & IP blocking |

---

## 🏆 Key Findings Summary

✅ **High Confidence**
- No data was stolen
- Attack was coordinated, not random
- Timing deliberately targeted minimum staffing hours

⚠️ **Moderate Confidence**
- State-sponsored involvement (6/6 APT indicators present)

❌ **Low Confidence**
- Cannot confirm a specific nation-state actor

---

## 📄 License

This project is for **educational and portfolio purposes only**.  
All data used is **simulated** — no real customer or financial data was involved.

---

*Built as part of the Cyberstorm: Attack Analysis & Response initiative*
