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

---

## 4. Orders, Dispatches, Sales Returns & Payment Allocation (Phase 10)

### 4.1 Customer Sales Returns & Restocking Disposition
* **Context:** A customer returns dispatched dairy products (e.g., delivered milk curdled during transit or customer over-ordered).
* **Unresolved Rule:** Can returned dairy goods ever be returned to active finished inventory, or must they be sent to `wastage_records` with an audit reason?
* **Open Options:**
  - Option A: Perishable dairy items (pasteurized milk, paneer, dahi) cannot be re-sold and must be recorded as wastage; non-perishables (ghee tins, dry bio-manure bags) may be restocked upon QC inspection.
  - Option B: All returns require credit notes and route directly to wastage.
* **Current Action:** Re-stocking of returned perishables is prohibited; return adjustments create an audit log and credit receivable balance adjustment.

### 4.2 Unallocated Customer Overpayments & Advance Float Allocation
* **Context:** A customer deposits lump-sum payments (e.g. advance of ₹5,000) that exceed current outstanding invoices, or pays without referencing a specific dispatch.
* **Unresolved Rule:** Should the system automatically apply FIFO cascading allocation to settle the oldest outstanding sales dispatches, or hold the amount as an unallocated customer credit balance?
* **Open Options:**
  - Option A: Automatic FIFO cascading allocation against unpaid dispatches ordered by `record_date ASC`.
  - Option B: Hold unallocated payments as a customer account credit, leaving individual dispatches open unless explicitly settled by reference.
* **Current Action:** Payments can reference a specific `dispatch_id` to reduce its `balance_due`; general payments credit `customers.current_balance` directly without mutating past dispatch line records.

### 4.3 Order Partial Fulfillment Expiry & Remainder Cancellation Policy
* **Context:** An order is placed for 100 pouches; 80 are dispatched (`PARTIALLY_FULFILLED`).
* **Unresolved Rule:** If the remaining 20 cannot be fulfilled, does the order auto-cancel after the delivery date, or must a sales manager explicitly close/cancel the remaining balance?
* **Current Action:** An order remains `PARTIALLY_FULFILLED` until explicitly closed or fully fulfilled; cancellation is blocked once fulfillment has commenced without supervisor sign-off.

### 4.4 Emergency Negative Stock Policy
* **Context:** High-throughput dispatch or material usage occurs before an inbound supplier delivery invoice has been keyed in by the storekeeper.
* **Unresolved Rule:** Should negative stock ever be allowed under emergency flags, or must physical receipts always precede physical dispatches?
* **Current Action:** Negative stock is strictly prohibited across all inventory categories. Any attempt to issue or dispatch stock beyond `current_stock` results in an HTTP `400 Bad Request` (`INSUFFICIENT_STOCK`).

---

## 5. Biogas Fertiliser, Wastage & Losses and Costs & Expenses (Phase 11)

### 5.1 Biogas Slurry Sourcing & Internal Transfer Valuation
* **Context:** Biogas digesters consume cow dung slurry produced by the cattle herd to generate bio-methane fuel and dry bio-fertiliser.
* **Unresolved Rule:** Should the slurry input carry an internal transfer cost credited to the herd cost center and debited to the biogas cost center, or is slurry treated as an uncosted operational by-product?
* **Open Options:**
  - Option A: Value slurry at a fixed nominal rate (e.g. ₹0.20/kg) as an internal transfer between herd and biogas.
  - Option B: Treat slurry as zero-cost farm by-product; cost dry bio-fertiliser purely on packaging materials, labour, and utility expenses.
* **Current Action:** Treated as uncosted operational by-product with zero raw material debit; only downstream packaging and utilities constitute explicit cost components.

### 5.2 Wastage Salvage Disposition & Secondary Income
* **Context:** Curdled BMC milk or rejected batch dairy products are sometimes sold to local piggeries, soapmakers, or compost pits at discounted salvage rates.
* **Unresolved Rule:** Should salvage sales directly credit the wastage loss ledger, or must wastage remain an immutable loss record with salvage proceeds booked under miscellaneous revenue?
* **Open Options:**
  - Option A: Net-off salvage income against `wastage_records.estimated_loss_cost`.
  - Option B: Keep `wastage_records.estimated_loss_cost` at full cost of production and record salvage proceeds in customer cash payments / miscellaneous revenue.
* **Current Action:** Full loss value is captured in `wastage_records`; any secondary liquidation is processed via separate sales receipts without mutating loss records.

### 5.3 Utility Readings vs. Operating Expense Invoices Integration
* **Context:** Electricity consumption is logged in `electricity_readings` with calculated total cost based on tariff rates. State electricity board utility power bills arrive monthly as consolidated financial invoices.
* **Unresolved Rule:** Should meter readings automatically generate corresponding entries in `operating_expenses`, or are operating expenses strictly reserved for audited cash/bank invoice payments?
* **Open Options:**
  - Option A: Automated accrual expense generation upon meter entry.
  - Option B: Distinct operational meter log vs. financial expense ledger; finance records actual utility invoices in `operating_expenses` for cash-flow accounting.
* **Current Action:** Meter logs and expense entries remain distinct; electricity bills are entered under `operating_expenses` (`category = 'ELECTRICITY'`) upon actual payment settlement.

---

## 6. Employees, Payroll, Statutory Filings & Licence Renewals (Phase 12)

### 6.1 Payroll & Statutory Deductions (EPF, ESI, Professional Tax, TDS)
* **Context:** Dairy farms in Odisha employ both regular salaried operational staff and seasonal casual milkers/fodder cutters. Indian labor codes require Employees' Provident Fund (EPF), Employees' State Insurance (ESI), Professional Tax, and Income Tax TDS under certain headcount and wage thresholds.
* **Unresolved Rule:** Should automated monthly payroll computation, attendance-based salary slips, and statutory deduction schedules be calculated by the app, or should employee records be restricted to HR profiles and monthly salary rates?
* **Open Options:**
  - Option A: Implement full payroll calculation engine with PF/ESI contribution schedules, payslip PDF generation, and deduction ledgers.
  - Option B: Keep Phase 12 strictly scoped to employee identity, department allocation, and approved base salary profile; defer automated payroll and statutory filing until formal business approval.
* **Current Action:** Option B is enforced. No payroll generation or statutory filing services are implemented; salary fields serve strictly as reference profile data with strict RBAC privacy protection.

### 6.2 External Licence Renewal Portal Integration
* **Context:** Dairy commercial operations require FSSAI food safety licenses, State Pollution Control Board (SPCB) consent-to-operate, fire safety NOC, and local gram panchayat trade licenses.
* **Unresolved Rule:** Should the application interface directly with government single-window portals (e.g. FoSCoS for FSSAI) to fetch live licence status or initiate renewal applications?
* **Open Options:**
  - Option A: Build custom API connectors or webhooks to government compliance portals.
  - Option B: Maintain an internal compliance tracking register with document URL attachments, expiry reminders, and manual administrative updates upon renewal receipt.
* **Current Action:** Option B is enforced. No external automated renewal or governmental portal integrations are implemented; licence records remain internal compliance registers with explicitly configured local reminder triggers.

### 6.3 Contractor / Daily Wage Casual Labor Billing
* **Context:** Seasonal farm tasks (e.g., harvesting fodder grass or repairing cow sheds) occasionally rely on third-party daily contractors rather than permanent staff on payroll.
* **Unresolved Rule:** Should casual labor be registered as temporary employees in `employees`, or should casual wage disbursements be booked directly under `operating_expenses` (`category = 'LABOUR'`) without creating employee master records?
* **Open Options:**
  - Option A: Create short-term `employees` records with daily wage rates.
  - Option B: Book ad-hoc casual labor directly in `operating_expenses` under `LABOUR`, reserving `employees` for contracted personnel.
* **Current Action:** Permanent/contract personnel are registered in `employees`; informal ad-hoc labor payouts are recorded directly in `operating_expenses` under `LABOUR`.



