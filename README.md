# 🛡️ Operation Swift Recovery — Cyberstorm Attack Analysis

> A forensic analysis of a real-world-style multi-vector cyber attack on a financial institution,  
> powered by a **MySQL database** queried and analyzed entirely through **Python**.

---

## 📌 Project Overview

**Operation Swift Recovery** is a data-driven cybersecurity incident analysis project simulating a coordinated multi-vector attack on **GlobalTrust Bank** — March 15, 2024 (02:00–05:00 UTC).

The project answers one core question:  
**Was this a planned, coordinated attack — or random internet noise?**  
The data answers it conclusively.

---

## 🗄️ Database Architecture (MySQL → Python Pipeline)

The entire analysis is powered by a **MySQL database** (`globaltrust_incident`) connected to Python via **SQLAlchemy** and queried into **Pandas DataFrames**.

### Database Schema — 4 Tables

| Table | Rows | Description |
|---|---|---|
| `attack_logs` | 15,500 | Every attack event — timestamp, source IP, attack type, payload hash, blocked status, target service |
| `ip_intelligence` | 550 | Threat-intel per attacker IP — country, ISP, ASN, TOR/VPN/Proxy flags, threat score |
| `affected_services` | 10 | Bank's internal services — criticality rating, recovery time objective, status |
| `incident_timeline` | 21 | SOC response actions — chronological log of every defensive action taken |

### Table Relationships (Joins)

```
attack_logs.source_ip          →  ip_intelligence.ip_address    (geographic & threat context)
attack_logs.target_service_id  →  affected_services.service_id  (business impact context)
```

### Python ↔ MySQL Connection

```python
# Secure connection using environment variables — no hardcoded credentials
from sqlalchemy import create_engine
import os
from dotenv import load_dotenv

load_dotenv()

engine = create_engine(
    f"mysql+mysqlconnector://"
    f"{os.getenv('DB_USER')}:{os.getenv('DB_PASSWORD')}"
    f"@{os.getenv('DB_HOST')}/{os.getenv('DB_NAME')}"
)

# Pull each table directly into a Pandas DataFrame
df_attacks  = pd.read_sql("SELECT * FROM attack_logs", engine)
df_ip_intel = pd.read_sql("SELECT * FROM ip_intelligence", engine)
df_services = pd.read_sql("SELECT * FROM affected_services", engine)
df_timeline = pd.read_sql("SELECT * FROM incident_timeline", engine)
```

### Enriched Master DataFrame

All four tables were merged into one enriched DataFrame for cross-table analysis:

```python
df = df_attacks.merge(df_ip_intel,  left_on='source_ip',        right_on='ip_address', how='left')
df = df.merge(df_services,          left_on='target_service_id', right_on='service_id', how='left')
```

This enabled queries like:  
*"Which ISPs sent the most SQL Injection attacks against critical services from TOR exit nodes?"*

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
- 13 countries mapped via IP geolocation from `ip_intelligence` table

### Q5 — Anonymization (Correct Set Union Method)
- **55%** of attackers used at least one anonymization tool
- TOR: 40.5% | Proxy: 18.1% | VPN: 2.8%
- 995 IPs used multiple tools — overlap corrected via Set Union (not naive sum)

```python
# Correct approach — Set Union, not sum
anonymized = df_ip_intel[
    (df_ip_intel['is_tor'] == 1) |
    (df_ip_intel['is_vpn'] == 1) |
    (df_ip_intel['is_proxy'] == 1)
]
rate = len(anonymized) / len(df_ip_intel)  # → 55%, not 61.4%
```

### Q6 — State-Sponsored Activity Indicators
- 77 IPs linked to known APT groups (15% of all traffic)
- All 6 professional APT indicators present
- Confidence level: **Moderate**

### Q7 — Top 10 Most Dangerous IPs
- Composite threat score: attack volume × success rate × APT flag × anonymization
- Top IP: `123.160.109.221` (RU) — 1,306 attacks, SQL injection dominated

### Q8 — Campaign or Coincidence?
- **Verdict: ONE organized campaign** — synchronized start/stop, uniform duration across all 550 IPs

### Q9 — ISP-Level Response
| ISP | Action |
|---|---|
| PJSC MegaFon (RU) | Full block |
| Rostelecom (RU) | Rate-limit + monitor |
| Others | Monitor only |

### Q10 — Service Restoration Priority
- **Delayed restore**: Core Banking DB (578 breaches), Auth Service (471 breaches)
- **Early restore**: Internal tools with low threat scores

### Q11 — IP Blocking Criteria (3-Tier System)
| Tier | Criteria | IPs |
|---|---|---|
| Permanent Block | Threat Score > 70 or APT_SUSPECTED | 157 |
| 30-Day Block | Threat Score > 50 + High Volume | 37 |
| Monitor Only | Low-risk traffic | 356 |

---

## 🔧 Remediation Plan

| Priority | Fix | Cost | Timeline |
|---|---|---|---|
| 🔴 Critical | Tune WAF rules for SQL Injection | $50K | 1 month |
| 🔴 Critical | Hire dedicated night-shift SOC staff | $200K/yr | 3 months |
| 🟠 High | Upgrade DDoS protection capacity | $150K/yr | 1 month |
| 🟠 High | Anomaly detection on Core Banking DB | $150K | 3 months |
| 🟡 Medium | APT Threat Intelligence Feed | $75K/yr | 2 months |
| 🟡 Medium | Automate geo-blocking rules | $20K | 2 weeks |

**$575K investment → repeat-attack risk drops from 40% to <10%**

---

## 🧰 Tech Stack

| Layer | Technology |
|---|---|
| **Database** | MySQL (`globaltrust_incident`) |
| **ORM / Connector** | SQLAlchemy + `mysql-connector-python` |
| **Data Analysis** | Python, Pandas, NumPy |
| **Visualization** | Matplotlib, Seaborn |
| **Environment** | Jupyter Notebook |
| **Secrets Management** | `python-dotenv` (.env file) |

---

## 📁 Repository Structure

```
operation-swift-recovery/
│
├── operation_swift_recovery.ipynb    # Full analysis notebook (SQL + Python)
├── .env.example                      # Template — copy to .env and fill credentials
├── README.md                         # This file
└── presentation/
    └── Cyberstorm_Attack_Analysis.pdf
```

### ⚠️ Setup

```bash
# 1. Copy the env template
cp .env.example .env

# 2. Fill in your MySQL credentials in .env
DB_USER=your_username
DB_PASSWORD=your_password
DB_HOST=127.0.0.1
DB_NAME=globaltrust_incident

# 3. Install Python dependencies
pip install pandas numpy matplotlib seaborn sqlalchemy mysql-connector-python python-dotenv

# 4. Open the notebook
jupyter notebook operation_swift_recovery.ipynb
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

## 🏆 Key Findings

✅ **High Confidence** — No data stolen · Coordinated attack confirmed · Deliberate night-shift timing  
⚠️ **Moderate Confidence** — State-sponsored involvement (6/6 APT indicators)  
❌ **Low Confidence** — Specific nation-state actor (cannot confirm without further attribution)

---

## 📄 License

Educational and portfolio purposes only. All data is simulated — no real customer or financial data.
