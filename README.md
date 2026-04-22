# 🏥 Healthcare Analytics — Hospital Patient Stay Analysis
**Tools:** MySQL · SQL  
**Dataset:** [AV Healthcare Analytics II — Kaggle](https://www.kaggle.com/datasets/nehaprabhavalkar/av-healthcare-analytics-ii)  
**Rows Analysed:** 318,438 patient records

---

## Project Overview

This project analyses hospital patient data to uncover patterns in patient stay duration, readmission risk, and resource utilisation across departments, ward types, and hospitals. The goal is to help healthcare administrators identify high-burden areas and optimise patient flow.

---

## Dataset Description

| Column | Description |
|---|---|
| `case_id` | Unique case ID per hospital visit |
| `Hospital_code` | Unique hospital identifier |
| `Department` | Department handling the case |
| `Type_of_Admission` | Emergency / Trauma / Urgent |
| `Severity_of_Illness` | Minor / Moderate / Extreme |
| `Age` | Patient age group (0-10 to 91-100) |
| `Stay` | Length of stay in days (target variable) |
| `Admission_Deposit` | Deposit paid at admission |
| `Visitors_with_Patient` | Number of visitors accompanying the patient |
| `Ward_Type` | Ward assigned to the patient |

---

## Key Business Questions Answered

### 1. Which department has the highest long-stay patient rate?

```sql
SELECT Department,
       COUNT(*) AS total_patients,
       ROUND(SUM(CASE WHEN Stay IN ('51-60','61-70','71-80','81-90','91-100','More than 100 Days') 
             THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS long_stay_pct
FROM train_data
GROUP BY Department
ORDER BY long_stay_pct DESC;
```

**Finding:** Surgery has the highest long-stay rate at **29.73%** — nearly 1 in 3 surgery patients stays more than 50 days, followed by Radiotherapy at 22.07%.

---

### 2. Does illness severity predict deposit amount?

```sql
SELECT Severity_of_Illness,
       COUNT(*) AS total_patients,
       ROUND(AVG(Admission_Deposit), 2) AS avg_deposit
FROM train_data
GROUP BY Severity_of_Illness
ORDER BY avg_deposit DESC;
```

**Finding:** Counterintuitively, **Minor illness patients pay the highest average deposit (₹4,982)**, while Extreme cases pay the least (₹4,747). This suggests elective/minor procedures are priced higher upfront, while emergency extreme cases may receive deposit flexibility.

---

### 3. Which age group has the most extreme stays (100+ days)?

```sql
SELECT Age,
       COUNT(*) AS total_patients,
       SUM(CASE WHEN Stay = 'More than 100 Days' THEN 1 ELSE 0 END) AS over_100_days,
       RANK() OVER (ORDER BY SUM(CASE WHEN Stay = 'More than 100 Days' THEN 1 ELSE 0 END) DESC) AS risk_rank
FROM train_data
GROUP BY Age
ORDER BY risk_rank;
```

**Finding:** **Middle-aged adults (41-60) account for the most 100+ day stays**, not the elderly as commonly assumed. The 41-50 group leads with 1,307 extreme stays, followed by 51-60 with 1,199.

---

### 4. How does admission type relate to illness severity?

```sql
SELECT Type_of_Admission,
       Severity_of_Illness,
       COUNT(*) AS total,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY Type_of_Admission), 2) AS pct_within_type
FROM train_data
GROUP BY Type_of_Admission, Severity_of_Illness
ORDER BY Type_of_Admission, pct_within_type DESC;
```

**Finding:** Moderate severity is the most common across all admission types, including Emergency admissions — highlighting that not all emergency cases are extreme.

---

### 5. Which ward type carries the highest extreme stay burden?

```sql
SELECT Ward_Type,
       COUNT(*) AS total_patients,
       SUM(CASE WHEN Stay = 'More than 100 Days' THEN 1 ELSE 0 END) AS extreme_stays,
       ROUND(SUM(CASE WHEN Stay = 'More than 100 Days' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS extreme_pct
FROM train_data
GROUP BY Ward_Type
ORDER BY extreme_pct DESC;
```

**Finding:** **Ward S has the highest extreme stay rate at 4.04%** — more than 4x higher than Ward Q (1.02%), suggesting Ward S handles the most critical and complex patient cases.

---

### 6. Which hospitals have the highest long-stay burden?

```sql
SELECT Hospital_code,
       COUNT(*) AS total_patients,
       ROUND(SUM(CASE WHEN Stay IN ('51-60','61-70','71-80','81-90','91-100','More than 100 Days') 
             THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS long_stay_pct
FROM train_data
GROUP BY Hospital_code
ORDER BY long_stay_pct DESC
LIMIT 10;
```

**Finding:** **Hospital 25 has the highest long-stay rate at 34.85%**, while Hospital 20 handles the most patient volume (14,054) with a 31.6% long-stay rate — flagging it as a key operational bottleneck.

---

### 7. Does deposit range affect visitor support?

```sql
SELECT 
  CASE 
    WHEN Admission_Deposit < 2000 THEN 'Under 2000'
    WHEN Admission_Deposit < 4000 THEN '2000-3999'
    WHEN Admission_Deposit < 6000 THEN '4000-5999'
    WHEN Admission_Deposit < 8000 THEN '6000-7999'
    ELSE 'Above 8000'
  END AS deposit_range,
  COUNT(*) AS total_patients,
  ROUND(AVG(Visitors_with_Patient), 1) AS avg_visitors,
  SUM(CASE WHEN Severity_of_Illness = 'Extreme' THEN 1 ELSE 0 END) AS extreme_cases
FROM train_data
GROUP BY deposit_range
ORDER BY total_patients DESC;
```

**Finding:** **Lower-deposit patients (Under 2000) have the highest average visitor count (5.7)**, suggesting stronger family support networks among lower-income patients. The majority of patients (218,184) fall in the ₹4,000–5,999 deposit range.

---

## Summary of Insights

| # | Insight |
|---|---|
| 1 | Surgery department has the highest long-stay rate (29.73%) |
| 2 | Minor illness patients pay higher deposits than Extreme cases — counterintuitive pricing pattern |
| 3 | Middle-aged adults (41-60) have more 100+ day stays than elderly patients |
| 4 | Ward S handles the most critical cases with a 4x higher extreme stay rate vs Ward Q |
| 5 | Hospital 25 flags as highest long-stay burden; Hospital 20 is the biggest volume bottleneck |
| 6 | Lower-income patients bring more family visitors — higher social support |

---

## SQL Skills Demonstrated

- Aggregate functions: `COUNT`, `SUM`, `AVG`, `MIN`, `MAX`
- Conditional aggregation: `CASE WHEN`
- Window functions: `RANK()`, `SUM() OVER (PARTITION BY)`
- Data binning with `CASE WHEN` ranges
- `GROUP BY`, `HAVING`, `ORDER BY`
- Data loading with `LOAD DATA INFILE`
- Data cleaning: handling nulls, truncation warnings, duplicate removal
