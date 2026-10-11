# Dairy Farm Management System - Open Questions & Technical Clarifications

## 1. Domain Calculations & Costing Formulas

1. **Asset Depreciation & Capital Expenditure:**
   * *Observation:* The current daily farm milk costing formula includes feed, medicines, consumables, electricity, direct labor, and operating expenses:
     $$\text{Daily Farm Cost} = \text{Feed} + \text{Meds} + \text{Materials} + \text{Salaries} + \text{Power} + \text{Expenses}$$
   * *Question:* Should long-term capital assets (cattle acquisition depreciation, milking parlor machinery, chilling plant capital depreciation) be factored into the daily unit cost per litre, or is the client operating strictly on cash operational expenditure (OpEx)?
2. **Dynamic Concentrate Target Calculation:**
   * *Observation:* Video 2 states concentrate rule uses average yield on recorded days over the last 7 days:
     $$\text{Target} = \min(1.0 + (\text{AvgYield} \times 0.4), 8.0)$$
   * *Question:* For newly calved cows or heifers with fewer than 7 days of historical milking records, how should the concentrate formula initialize? (e.g., use lifetime average or default base of 1.0 kg?).
3. **By-Product Economic Value Allocation:**
   * *Observation:* During paneer, khoya, or ghee production, by-products (whey, buttermilk) are recorded in kilograms.
   * *Question:* Does whey have a monetary credit value offset against the main batch cost, or is it treated solely as zero-value agricultural waste / biogas slurry feedstock?

---

## 2. Inventory & Stock Rules

1. **Inventory Valuation Methodology:**
   * *Observation:* Common Inventory displays "average purchase price" from stock receipts.
   * *Question:* Should material deductions (e.g. feed issues, packaging consumption) strictly execute on **Periodic Weighted Average Cost (WAC)** or **First-In, First-Out (FIFO)** lot depletion?
2. **Packaging Scrap & Tare Weight:**
   * *Observation:* Packaging forms allow entering packaging items and net pack weight.
   * *Question:* Is a fixed scrap allowance percentage (e.g. 2% pouch bursting tolerance on packaging machine) permitted, or should all broken packaging materials be logged explicitly through the *Wastage & Losses* module?

---

## 3. Quality Parameters & Quality Gates

1. **FSSAI Parameter Enforcement:**
   * *Observation:* BMC intake modal accepts manual `Decision: Accepted / Rejected` alongside Fat %, SNF %, CLR, pH, and Temperature.
   * *Question:* Should the system automatically enforce rejection if parameters fall below FSSAI statutory standards (e.g. Cow milk Fat < 3.2% or SNF < 8.3%), or is the operator permitted to override and accept?
2. **Quality Release Gate on Production Batches:**
   * *Observation:* Production batches are created with `Quality release: Hold`.
   * *Question:* Does an unreleased batch strictly block packaging and sales dispatch on the backend API, or does it trigger an advisory warning?

---

## 4. User Roles & Multi-Tenancy Scope

1. **Multi-Role Assignment:**
   * *Observation:* On smaller dairy farms, a single person (e.g. Farm Manager) often performs veterinary entries, stock receipts, and production supervision.
   * *Question:* Can individual user accounts hold multiple roles concurrently, and if so, how should the UI drawer adapt (show all assigned options)?
2. **Platform & Offline Sync Scope:**
   * *Observation:* Farm rural environments frequently experience intermittent 4G/WiFi connectivity.
   * *Question:* Should the Flutter application incorporate local SQLite/Hive caching with offline draft queuing and background synchronization, or does the contract baseline assume online-first REST API connectivity?
