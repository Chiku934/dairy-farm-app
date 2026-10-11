# Dairy Farm Management System - Approved Domain Formulas & Mathematical Models

This document formally specifies and standardizes the mathematical formulas, calculations, and rounding rules approved for **Phase 7: Milking Log, Feed & Ration Planning, and Unit Costing** in accordance with `docs/REQUIREMENTS.md` (`REQ-YD-03`, `REQ-YD-06`, `REQ-YD-07`).

---

## 1. Feed & Ration Calculations

### 1.1 Ration Formulation Costing Formula
A ration definition consists of $N$ feed ingredients ($i = 1, \dots, N$) selected from the farm's feed stock inventory (`stock_items` where `category = 'FEED'`).

* **Total Ration Quantity ($Q_{\text{total}}$):**
  $$Q_{\text{total}} = \sum_{i=1}^N Q_i \quad (\text{kg})$$

* **Total Ration Cost ($C_{\text{total}}$):**
  $$C_{\text{total}} = \sum_{i=1}^N \Big( Q_i \times P_i \Big) \quad (\text{₹})$$
  * Where $Q_i$ is the quantity of ingredient $i$ in kilograms ($\text{DECIMAL}(8,2)$).
  * Where $P_i$ is the perpetual weighted average purchase cost of ingredient $i$ from `stock_items.weighted_avg_price` ($\text{DECIMAL}(10,2)$ in ₹/kg).

* **Ration Unit Cost per Kilogram ($C_{\text{unit}}$):**
  $$C_{\text{unit}} = \frac{C_{\text{total}}}{Q_{\text{total}}} \quad (\text{₹/kg})$$
  * If $Q_{\text{total}} = 0$, $C_{\text{unit}} = 0.00$.
  * Rounded to 2 decimal places ($\text{DECIMAL}(10,2)$).

### 1.2 Milk-Linked Target Concentrate Formula
In accordance with `REQ-YD-06`, lactating cows receive a daily concentrate ration proportional to their 7-day average milk production:

$$\text{Target Concentrate (kg/day)} = \min\Big(\text{Base Concentrate} + \big(\text{Average Daily Yield (L)} \times \text{Concentrate Increment Factor}\big), \text{Max Concentrate Cap}\Big)$$

* **Operational Constants from `farm_settings`:**
  * $\text{Base Concentrate} = 1.00\text{ kg}$ (`feed_base_kg`)
  * $\text{Concentrate Increment Factor} = 0.40\text{ kg/L}$ (`feed_rate_per_litre`)
  * $\text{Max Concentrate Cap} = 8.00\text{ kg/day}$ (`feed_max_cap_kg`)

* **7-Day Average Yield Determination:**
  * Average daily milk yield is calculated from all recorded milking sessions across the preceding 7 calendar days for the cow:
    $$\text{Average Daily Yield} = \frac{\sum_{d=1}^k \text{Daily Yield}_d}{k} \quad (\text{where } k \le 7 \text{ recorded days})$$
  * **Fresh Cow Rule (`docs/OPEN_QUESTIONS.md` §1.2):** If the animal has fewer than 3 recorded milking days (e.g. fresh calver), the target falls back to the safe $\text{Base Concentrate}$ ($1.00\text{ kg}$).

---

## 2. Milking Log & Milk Disposition Rules

### 2.1 Shift Aggregation & Duplicates
* Daily milking sessions are recorded under two standard operational shifts: `MORNING` and `EVENING`.
* **Individual Cow Uniqueness Rule:** An animal can have at most **one** entry per calendar date and shift:
  $$\text{Unique Key: } (\text{animal\_id}, \text{record\_date}, \text{session})$$
  Attempts to insert a duplicate session for the same cow reject with an HTTP `409 Conflict` error and prompt the operator to update the existing entry if revising yield.
* **Group Milking Uniqueness Rule:** For group or bulk milking entries (`animal_id` is null, `group_name` is set):
  $$\text{Unique Key: } (\text{group\_name}, \text{record\_date}, \text{session})$$

### 2.2 Milk Disposition Categories
1. `ELIGIBLE`: Milk cleared for commercial farm collection and BMC tank intake pool.
2. `WITHHELD`: Milk unsuitable for collection due to veterinary treatment, antibiotics, or colostrum.
3. `CALF_FEEDING`: Milk diverted directly for on-farm calf nutrition.

### 2.3 Active Milk Safety Withdrawal Gate (`REQ-YD-04`)
* When logging a milking entry, the system inspects active health records for the cow:
  $$\text{Has Active Withdrawal} \iff \exists\, \text{health\_record where } \text{withdrawal\_until} \ge \text{record\_date}$$
* If active withdrawal exists:
  * Disposition `ELIGIBLE` is **strictly prohibited**.
  * The system automatically enforces `WITHHELD` disposition, recording `withheld_reason: "Active safety withdrawal period until YYYY-MM-DD"`.

---

## 3. Daily Farm Milk Unit Costing (`REQ-YD-07`)

### 3.1 Daily Farm Operating Cost Breakdown
$$\text{Daily Farm Cost} = C_{\text{feed}} + C_{\text{meds}} + C_{\text{materials}} + C_{\text{salaries}} + C_{\text{electricity}} + C_{\text{expenses}}$$

1. **Feed Consumed ($C_{\text{feed}}$):**
   $$C_{\text{feed}} = \sum \Big( \text{feed\_entries.quantity\_kg} \times \text{stock\_items.weighted\_avg\_price} \Big) \quad \text{for date } D$$

2. **Veterinary Medicines ($C_{\text{meds}}$):**
   $$C_{\text{meds}} = \sum \text{Medicine costs issued or recorded against FARM health events on date } D$$

3. **Other Farm Materials ($C_{\text{materials}}$):**
   $$C_{\text{materials}} = \sum \text{Material issue costs to cost centre 'FARM' on date } D$$

4. **Farm Daily Salaries ($C_{\text{salaries}}$):**
   Derived from the monthly payroll of active employees prorated over 30 days:
   $$C_{\text{salaries}} = \sum_{\text{emp} \in \text{FARM}} \frac{\text{Monthly Salary}}{30} + \Big(\frac{\text{mgmt\_split\_pct}}{100} \times \sum_{\text{emp} \in \text{MANAGEMENT}} \frac{\text{Monthly Salary}}{30}\Big)$$
   * Where $\text{mgmt\_split\_pct} = 50\%$ from `farm_settings.mgmt_salary_to_farm_pct`.

5. **Farm Electricity ($C_{\text{electricity}}$):**
   $$C_{\text{electricity}} = \begin{cases}
   \text{Meter Units (kWh)} \times \text{Tariff (₹)} & \text{if reading exists for 'FARM' on date } D \\
   \text{farm\_default\_kwh (50)} \times \text{Tariff (₹1.40)} = ₹70.00 & \text{if meter reading missing}
   \end{cases}$$

6. **Other Farm Operational Expenses ($C_{\text{expenses}}$):**
   $$C_{\text{expenses}} = \sum \text{operating\_expenses.amount where cost\_centre = 'FARM' on date } D$$

### 3.2 Unit Cost per Litre Calculation
$$\text{Eligible Farm Milk Recorded (L)} = \sum \text{milking\_logs.yield\_litres where disposition = 'ELIGIBLE' on date } D$$

$$\text{Cost per Litre (₹/L)} = \frac{\text{Daily Farm Cost (₹)}}{\text{Eligible Farm Milk Recorded (L)}}$$

### 3.3 Zero Eligible Milk Reconciliation Rule
* If $\text{Eligible Farm Milk Recorded} = 0$:
  * Status: `'INCOMPLETE'`
  * `costPerLitre`: `null`
  * Warning Message: `"No eligible milk recorded for this date. Cost per litre cannot be computed."`
* If $\text{Eligible Farm Milk Recorded} > 0$:
  * Status: `'COMPLETE'`
  * `costPerLitre`: Calculated to 2 decimal places ($\text{DECIMAL}(10,2)$).
