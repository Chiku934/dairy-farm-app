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

---

## 4. BMC & Milk Intake and Production Batches (`REQ-MM-08`, `REQ-MM-09`)

### 4.1 BMC Tank Live Stock Ledger Equation
$$\text{Live Available BMC Milk (L)} = \sum \text{Accepted Intake (L)} - \sum \text{Consumed in Production (L)} - \sum \text{BMC Wastage (L)}$$

* **Accepted Intake Pool:**
  $$\sum \text{Accepted Intake} = \sum_{\text{decision} = \text{'ACCEPTED'}} \text{bmc\_intake\_logs.quantity\_litres}$$
  * Rejected milk records are strictly excluded from the tank balance.
* **Production Consumption:**
  $$\sum \text{Consumed in Production} = \sum_{\text{status} \ne \text{'CANCELLED'}} \text{production\_batches.bmc\_milk\_consumed\_l}$$
* **BMC Wastage & Spoilage:**
  $$\sum \text{BMC Wastage} = \sum_{\text{stock\_type} = \text{'BMC'}} \text{wastage\_records.quantity\_lost}$$
* **Tank Utilization Percentage:**
  $$\text{Utilization \%} = \frac{\text{Live Available BMC Milk}}{\text{farm\_settings.bmc\_capacity\_litres}} \times 100$$
  * Normal: $< 75\%$
  * Warning: $75\% - 89.9\%$
  * Critical / High: $\ge 90\%$

### 4.2 Quality Control (QC) Milk Intake Acceptance Rules
Intake milk must satisfy standard quality criteria for acceptance into the commercial tank:
* **Temperature:** $\le 10.0^\circ\text{C}$ (ideal $\le 4.5^\circ\text{C}$)
* **Fat Percentage:** $3.2\% \le \text{Fat} \le 10.0\%$
* **SNF (Solids-Not-Fat) Percentage:** $8.0\% \le \text{SNF} \le 12.0\%$
* **Corrected Lactometer Reading (CLR):** $26.0 \le \text{CLR} \le 34.0$
* **pH / Acidity:** $6.40 \le \text{pH} \le 6.85$
* **Decision Gate:** If any core quality metric fails severely or if the operator rejects the lot, decision is marked `'REJECTED'`, mandatory `rejection_reason` is captured, and the volume is segregated without altering the live BMC tank balance.

### 4.3 Production Batch Conversion Yield & Efficiency Rules
Each product type has documented conversion ratios and permissible yield ranges:

$$\text{Batch Yield \%} = \frac{\text{Finished Output Quantity (kg or L)}}{\text{BMC Milk Consumed (L)}} \times 100$$

| Product Type | Unit of Measure | Standard Expected Yield | Permissible Yield Range | Max Cap Guard | Expected By-Products |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`PANEER`** | `KG` | $18.0\%$ ($0.18\,\text{kg/L}$) | $14.0\% - 22.0\%$ | $\le 25.0\%$ | Whey ($\approx 70\% - 85\%$ of milk volume) |
| **`KHOYA`** | `KG` | $20.0\%$ ($0.20\,\text{kg/L}$) | $16.0\% - 24.0\%$ | $\le 28.0\%$ | Steam / moisture loss |
| **`GHEE`** | `KG` | $6.0\%$ ($0.06\,\text{kg/L}$) | $5.0\% - 7.5\%$ | $\le 9.0\%$ | Skim milk / buttermilk |
| **`DAHI`** | `KG` | $98.0\%$ ($0.98\,\text{kg/L}$) | $92.0\% - 100.0\%$ | $\le 100.0\%$ | Negligible / whey separation |
| **`BUTTER`** | `KG` | $7.5\%$ ($0.075\,\text{kg/L}$) | $5.5\% - 9.5\%$ | $\le 11.0\%$ | Buttermilk ($\approx 90\%$ of cream) |
| **`MILK`** (Pouches) | `LITRE` | $99.0\%$ ($0.99\,\text{L/L}$) | $95.0\% - 100.0\%$ | $\le 100.0\%$ | Handling / packaging loss |
| **`BIOGAS_FERTILISER`** | `KG` | Varies by slurry input | Variable | Variable | Dry organic bio-manure |

* **Precision & Integrity Rules:**
  * Quantities are stored as exact decimals (`DECIMAL(8,2)`), never truncated or rounded down before storage.
  * Inputs with negative, zero, NaN, or physically impossible yields exceeding the Max Cap Guard are rejected with HTTP `422 Unprocessable Entity` or `400 Bad Request`.

### 4.4 End-to-End Traceability Model
Each finished production batch traces its lineage back to the contributing raw milk intake lots:
$$\text{Production Batch} \xleftarrow{\text{production\_batch\_intakes}} \text{BMC Intake Lots} \xleftarrow{\text{source}} \{\text{Internal Farm Shifts}, \text{External Supplier Routes}\}$$
* Records include:
  1. Intake Batch ID, Date, Shift (`AM`/`PM`), Source (`FARM`/`EXTERNAL`), Supplier/Route.
  2. Intake QC parameters (Fat, SNF, Temp, CLR, pH) and Operator.
  3. Processing details: Milk Consumed (L), Finished Yield (kg/L), LPG Consumed (kg), By-products (kg), Process Operator, Batch Expiry Date.
  4. Final Quality Release Status (`HOLD`, `APPROVED`, `REJECTED`).

