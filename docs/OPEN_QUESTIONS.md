# Dairy Farm Management System - Open Questions & Unresolved Calculation Rules

## 1. Domain Calculations & Costing Formulas

### 1.1 BMC Intake Milk Solids-Not-Fat (SNF) Empirical Formula
* **Context:** Milk testing at reception records Fat %, CLR (Corrected Lactometer Reading at 20°C / 29°C), and computes SNF %.
* **Unresolved Rule:** There are multiple empirical standards in Indian dairy practice:
  1. *Richmond's Formula:* $\text{SNF} = 0.25 \times \text{CLR} + 0.20 \times \text{Fat} + 0.36$
  2. *BIS Standard (IS:11833):* $\text{SNF} = 0.25 \times \text{CLR} + 0.21 \times \text{Fat} + 0.36$ (for cow milk) and $\text{SNF} = 0.25 \times \text{CLR} + 0.22 \times \text{Fat} + 0.72$ (for buffalo milk).
* **Current Action:** The system allows manual or measured entry of SNF % and does not hardcode an unapproved auto-calculation formula until the client confirms their calibrated lactometer standard.

### 1.2 Fresh Calver Daily Concentrate Ration Initialization
* **Context:** The standard target concentrate formula uses the 7-day average milk yield:
  $$\text{Target} = \min(\text{FeedBase} + (\text{AvgYield}_{7d} \times \text{FeedRate}), \text{FeedMaxCap})$$
* **Unresolved Rule:** For cows or heifers in their first 1 to 6 days post-calving, no 7-day historical milking average exists.
* **Open Options:**
  - Option A: Use the average of available recorded days since calving.
  - Option B: Use the base ration ($\text{FeedBase} = 1.0\text{ kg}$) until day 7.
  - Option C: Use a fixed fresh-cow transition allowance (e.g. 3.0 kg).
* **Current Action:** Target is computed as base ration when historical records are under 3 days, pending farm nutritionist approval.

### 1.3 Biogas Dung-to-Dry-Fertiliser Conversion Factor
* **Context:** Digested slurry outputs from biogas digestion are dried into packaged organic fertiliser.
* **Unresolved Rule:** Slurry is ~90% moisture, and dry organic fertiliser is ~15-20% moisture. The client prototype mentions dry fertiliser output without specifying the exact loss evaporation factor or curing time cycle.
* **Current Action:** Dry fertilizer production is entered manually as measured output from drying beds, not auto-calculated from raw slurry.

### 1.4 Overhead Utility Allocation During Meter Outages
* **Context:** Electricity tariff default is ₹1.40/kWh, split between Farm (50 kWh default) and Production (200 kWh default).
* **Unresolved Rule:** In the event of meter reading failure or sub-meter breakdown, should the system fall back strictly to farm settings defaults or proportionally scale to milk volume processed?
* **Current Action:** Uses farm settings explicit defaults (`farm_default_kwh`, `production_default_kwh`) with audit logging.

---

## 2. Inventory & Valuation Methods

### 2.1 Perpetual Weighted Average Cost (WAC) vs FIFO Depletion
* **Context:** Inbound stock receipts record unit purchase prices which fluctuate across vendor deliveries.
* **Unresolved Rule:** Does the farm accountant require strict batch-level FIFO tracking (depleting oldest lots first) or moving Weighted Average Cost (`current_stock` updated on each receipt)?
* **Current Action:** Database supports moving Weighted Average Cost via `weighted_avg_price` on `stock_items` and double-entry ledger in `stock_ledger_entries`.

### 2.2 Packaging Scrap & Bursting Allowance
* **Context:** Milk pouch rolls and paneer vacuum pouches frequently incur ~1-2% machine setup scrap.
* **Unresolved Rule:** Should scrap be auto-deducted as an invisible operational percentage, or must operators log burst pouches through the explicit *Wastage & Losses* module?
* **Current Action:** Operators log actual packaging units consumed in packaging runs; discrepancies are reported in `wastage_records`.

---

## 3. Statutory & Quality Gates

### 3.1 Statutory Rejection Override Authority
* **Context:** FSSAI statutory minimums require Cow milk Fat $\ge 3.2\%$ and $\text{SNF} \ge 8.3\%$.
* **Unresolved Rule:** If an incoming milk batch fails these parameters, can a privileged role (e.g. `FARM_MANAGER` or `FARM_OWNER`) manually override and accept the milk at a discounted rate, or is it a hard system block?
* **Current Action:** System records `decision: REJECTED` with organoleptic notes and permits manual manager approval override with full audit trail entry.
