# Dairy Farm Management System - Requirements Specification & Traceability Matrix

## 1. Document Overview & Baseline

This document specifies the exact functional, technical, and operational requirements for the **Dairy Farm Management System**, synthesized directly from:
- **Proposal Document:** `Dairy_Farm_App_Proposal and Cost Estimation.docx` (Dated 10 October 2026, reference for Kaivalya Dairy, Dandiri, Odisha)
- **Video Reference 1 (V1):** `WhatsApp Video 2026-10-08 at 1.15.49 PM.mp4` (Duration: 04:21) – Covering *Section B: Milk to Market*
- **Video Reference 2 (V2):** `WhatsApp Video 2026-10-08 at 1.16.12 PM.mp4` (Duration: 03:59) – Covering *Section A: Your Dairy*
- **Video Reference 3 (V3):** `WhatsApp Video 2026-10-08 at 1.16.12.mp4` (Duration: 03:43) – Covering *Section C: Business & Settings*

---

## 2. Business Modules Hierarchy

The system is organized into three major business areas comprising **24 distinct modules**:

### A. Your Dairy (Farm & Herd Management)
1. **Overview (Dashboard)**: Farm KPIs, herd count, milk yield, daily operating costs, period comparisons, alerts.
2. **Herd & Calves**: Cattle registry, lifecycle stage tracking, lineage, body metrics.
3. **Milking Log**: Per-cow morning/evening milking session tracking and milk disposition.
4. **Health & Vaccination**: Treatments, vaccinations, deworming, veterinarian care, milk withdrawal periods.
5. **Breeding & Calving**: Heat tracking, artificial insemination, pregnancy checks, expected calving.
6. **Feed & Ration Planning**: Target concentrate calculation rules, daily feed issues and consumption logging.
7. **Unit Costing**: Automated daily cost per litre calculator, cost allocations.

### B. Milk to Market (Processing & Distribution)
8. **BMC & Milk Intake**: Bulk Milk Cooler intake from internal farm vs. external suppliers with QC acceptance.
9. **Production Batches**: Conversion of milk into dairy products (Milk, Paneer, Khoya, Ghee, Dahi, Butter), LPG usage.
10. **Packaging**: Packaging runs into pouches, bottles, cans; stock deduction of packaging materials.
11. **Quality Records**: Laboratory & quality parameter testing linked to intake or production batches.
12. **Material Issues**: Allocation of consumables, cleaning materials, LPG, and spare parts.
13. **Electricity Readings**: Departmental electricity meter readings, daily kWh tracking and tariffs.
14. **Orders & Dispatch**: Customer sales order booking and fulfillment tracking.
15. **Sales**: Retail and wholesale dispatches, order linkage, and invoice totals.
16. **Customer Payments**: Accounts receivable collection against past sales.

### C. Business (Operations, Governance & Compliance)
17. **Common Inventory**: Central materials and packaging stock ledger, purchase receipts, low stock alerts.
18. **Biogas Fertiliser**: Wet slurry drying, packaging into standard bags, cost allocation.
19. **Wastage & Losses**: Spoilage, handling, leakage, and expiration records across BMC and goods.
20. **Costs & Expenses**: Operating expenses and ledger entries categorized by cost centre.
21. **Employees**: Staff registry, departments, monthly salary tracking, and daily labor rate allocation.
22. **FSSAI & Licences**: Regulatory licence registry, expiry dates, and automated renewal reminders.
23. **Reports & Exports**: Period cost reconciliations, CSV downloads, full JSON backup.
24. **Farm Settings**: Global operational constants (BMC capacity, feed rules, default power, tariff).

---

## 3. Requirement Traceability Matrix (RTM)

| Req ID | Source & Ref Timestamp | Business Module | Expected Behavior | Data Required | API Needed | Permission Required | Acceptance Test | Open Questions |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **REQ-YD-01** | Proposal p.2; V2 [00:00-00:30] | A. Your Dairy: Overview | Display live farm KPIs (Milk recorded, Sales revenue, Operating cost, Dry fertiliser output). Support Daily/Monthly/Custom period filter. Compare with prior period. Show active alert count. | Period range, date, aggregation metrics | `GET /api/v1/dashboard/overview` | `FARM_OWNER`, `FARM_MANAGER` | Select date range; verify KPI totals match underlying transactions within ±0.01 tolerance. | Clarify if period comparison should compare calendar days or moving averages when leap periods occur. |
| **REQ-YD-02** | Proposal p.2; V2 [00:35-01:07] | A. Your Dairy: Herd & Calves | Maintain cattle registry with status chips (Lactating, Dry, Pregnant, Heifer, Calf, Bull, Sold, Deceased). Provide search, export, and 'Add Animal' form. | Ear Tag/ID (unique), Name, Breed, Sex, DOB, Lifecycle Status, Weight (kg), Dam Tag, Last Calving Date, Body Condition Score (1-5), Notes | `GET /api/v1/herd`, `POST /api/v1/herd`, `GET /api/v1/herd/:id`, `PATCH /api/v1/herd/:id` | `FARM_OWNER`, `FARM_MANAGER`, `ANIMAL_CARE` | Create cow with tag `210385`, verify listed under Lactating chip; edit status to `Dry`, verify chip count updates. | What are the mandatory breeds list? Is microchip/RFID tag format strictly alphanumeric? |
| **REQ-YD-03** | Proposal p.2; V2 [01:13-01:25] | A. Your Dairy: Milking Log | Log individual cow milking sessions (Morning / Evening). Flag disposition (`Eligible for collection`, `Withheld`, `Calf feeding`). Reject entries if cow is under active withdrawal. | Record Date, Animal Tag, Session (AM/PM), Yield (L), Disposition, Notes | `GET /api/v1/milking`, `POST /api/v1/milking` | `FARM_OWNER`, `FARM_MANAGER`, `MILKING_STAFF` | Log 15 L Morning for cow; verify only `Eligible` milk sums up to farm BMC intake pool. | Can a cow be milked 3 times a day (Afternoon shift) if required? |
| **REQ-YD-04** | Proposal p.2; V2 [01:28-02:30] | A. Your Dairy: Health & Vaccination | Track health events, vaccine schedules, treatments, and safety withdrawal periods. Auto-withhold milk from collection until withdrawal date expires. | Record Date, Animal Tag, Care Type (`Treatment`, `Vaccination`, `Deworming`, `Examination`), Medicine/Vaccine, Dose, Vet, Next Due Date, Milk Withdrawal Until Date, Medicine Stock Item, Stock Used, Notes | `GET /api/v1/health`, `POST /api/v1/health` | `FARM_OWNER`, `FARM_MANAGER`, `ANIMAL_CARE` | Log antibiotic treatment with withdrawal until Oct 15; verify milking log for that cow warns or forces `Withheld` disposition. | Should veterinary prescription images/PDF attachments be supported? |
| **REQ-YD-05** | Proposal p.2; V2 [02:35-02:49] | A. Your Dairy: Breeding & Calving | Record breeding lifecycle: Heat, Insemination, Pregnancy Check, Calving, Dry Off. Auto-calculate gestation alerts (~280 days). | Record Date, Animal Tag, Event, Sire/Semen ID, Next Check / Expected Calving Date, Calf Tag, Notes | `GET /api/v1/breeding`, `POST /api/v1/breeding` | `FARM_OWNER`, `FARM_MANAGER`, `ANIMAL_CARE` | Record AI event with sire ID; verify next check reminder appears in Upcoming Calving dashboard. | Is heat detection protocol standard 21-day recurrence automated? |
| **REQ-YD-06** | Proposal p.2; V2 [02:51-03:04] | A. Your Dairy: Feed & Ration Planning | Calculate milk-linked concentrate target ($1\text{ kg base} + 0.4\text{ kg per L milk}$, max $8\text{ kg/day}$). Issue feed from stock and deduct inventory. | Record Date, Animal Tag, Feed Stock Item, Feed Issued (kg), Feed Type (`Concentrate`, `Green Fodder`, `Dry Fodder`, `Mineral Mixture`, `Salt`, `Maize`, `Calf Starter`), Notes | `GET /api/v1/feed`, `POST /api/v1/feed`, `GET /api/v1/feed/rules` | `FARM_OWNER`, `FARM_MANAGER`, `ANIMAL_CARE` | For a 25 L/day cow, verify target is $\min(1 + 0.4 \times 25, 8) = 8\text{ kg}$; log 7 kg issued and check inventory decreased by 7 kg. | Does feed planning support group feeding/TMR (Total Mixed Ration) or only individual animal feeds? |
| **REQ-YD-07** | Proposal p.2; V2 [03:07-03:26] | A. Your Dairy: Unit Costing | Compute daily farm cost per litre: $\frac{\text{Feed} + \text{Meds} + \text{Salaries} + \text{Electricity} + \text{Overhead}}{\text{Eligible Farm Milk Recorded}}$. Show warning if milk is 0. | Date, Feed consumed (₹), Medicines used (₹), Other materials (₹), Farm salaries/day (₹), Electricity (₹), Other farm expenses (₹) | `GET /api/v1/costing/daily-milk` | `FARM_OWNER`, `FARM_MANAGER`, `ACCOUNTANT` | When day has 100 L milk and ₹2,500 total farm costs, verify cost/litre is ₹25.00. | How should depreciation of machinery or cattle assets be incorporated? |
| **REQ-MM-08** | Proposal p.2; V1 [00:09-00:18] | B. Milk to Market: BMC & Intake | Record milk collection from Farm or External Supplier. Record fat %, SNF %, CLR, pH, temp. Update BMC tank live balance if accepted. Reject to separate log. | Record Date, Collection Source (`Farm`, `External`), Supplier/Route, Quantity (L), Cost (₹ for external), Decision (`Accepted`, `Rejected`), Temp, Fat %, SNF %, CLR, pH, Notes | `GET /api/v1/bmc/intake`, `POST /api/v1/bmc/intake`, `GET /api/v1/bmc/balance` | `FARM_OWNER`, `FARM_MANAGER`, `BMC_OPERATOR` | Accept 500 L farm milk; verify BMC tank balance increments by 500 L. Reject 100 L; verify tank does not increment but rejection is logged. | Is tank temperature monitored in real-time or purely on intake entry? |
| **REQ-MM-09** | Proposal p.2; V1 [01:00-01:13] | B. Milk to Market: Production Batches | Convert BMC milk into finished product (Milk, Paneer, Khoya, Ghee, Dahi, Butter, Biogas dry fertiliser). Record LPG used (kg), by-products, process record, expiry date, release status (`Hold`, `Released`). Deduct BMC milk and LPG stock. | Date, Product, BMC Milk Consumed (L), Finished Qty (L/kg), LPG Stock Item, LPG Used (kg), By-product Qty, Process Record, Expiry Date, Release Status, Notes | `GET /api/v1/production/batches`, `POST /api/v1/production/batches` | `FARM_OWNER`, `PRODUCTION_OPERATOR`, `QC_STAFF` | Create batch of Paneer using 100 L milk and 2 kg LPG; verify BMC milk drops by 100 L and LPG stock by 2 kg; paneer bulk batch created. | Are product conversion efficiency formulas (e.g. 100 L milk $\approx$ 18 kg paneer) strictly validated or advisory? |
| **REQ-MM-10** | Proposal p.2; V1 [01:48-02:00] | B. Milk to Market: Packaging | Deduct bulk production batch and packaging material (pouches, bottles, cartons, caps, labels) to create saleable packaged stock. | Date, Production Batch ID, Pack Size (e.g. 0.5 L, 1 kg), Number of Packs, Packaging Stock Item, Material Consumed (blank = 1/pack), Notes | `GET /api/v1/packaging/runs`, `POST /api/v1/packaging/runs` | `PRODUCTION_OPERATOR`, `STOREKEEPER`, `FARM_MANAGER` | Package 100 L milk into 200 packs of 0.5 L; verify 200 pouches and 200 labels deducted; 200 packaged units available for sales. | How are packaging line breakages/defects recorded during the run? |
| **REQ-MM-11** | Proposal p.2; V1 [02:30-02:44] | B. Milk to Market: Quality Records | Record quality test parameters linked to intake or production batch. Manage release decisions (`Pending`, `Approved`, `Rejected`). | Date, Batch Ref, Fat %, SNF %, CLR, pH, Temp (°C), Test Results, Release Decision, Tested By, Notes | `GET /api/v1/quality/records`, `POST /api/v1/quality/records` | `QC_STAFF`, `FARM_MANAGER`, `AUDITOR` | Log test for Batch KD-IN-20261001-0001; when Approved, batch is unlocked for packaging/dispatch. | What are the mandatory minimum thresholds for Fat % and SNF % under local regulatory standards (e.g. FSSAI)? |
| **REQ-MM-12** | Proposal p.2; V1 [03:08-03:16] | B. Milk to Market: Material Issues | Record issue and consumption of ingredients, cleaning agents, packaging, or spare parts to Farm, Production, or Biogas cost centres. | Date, Used By (`Farm`, `Production`, `Biogas`), Stock Item, Quantity, Production Batch (optional), Notes | `GET /api/v1/materials/issues`, `POST /api/v1/materials/issues` | `PRODUCTION_OPERATOR`, `STOREKEEPER`, `FARM_MANAGER` | Issue 5 kg caustic soda to Production; verify inventory decrements and Production cost centre accumulates material cost. | Can materials be returned to stock if unused? |
| **REQ-MM-13** | Proposal p.2; V1 [03:20-03:32] | B. Milk to Market: Electricity Readings | Record actual daily electricity meter units (kWh) and tariff. If missing, system falls back to configured default units from Farm Settings. | Date, Department (`Farm`, `Production`, `Biogas`), Electricity Units (kWh), Tariff (₹/unit), Notes | `GET /api/v1/electricity`, `POST /api/v1/electricity` | `PRODUCTION_OPERATOR`, `FARM_MANAGER`, `ACCOUNTANT` | Input 60 units @ ₹1.4 for Farm; verify daily farm electricity cost becomes ₹84. | Do meters have sub-meter multipliers or peak/off-peak TOD tariffs? |
| **REQ-MM-14** | Proposal p.2; V1 [03:44-03:52] | B. Milk to Market: Orders & Dispatch | Book customer sales orders with target delivery dates and quantities. Show order fulfillment status. | Date, Customer Name, Phone, Product, Pack Size, Packs Ordered, Price Per Pack (₹), Delivery Date, Notes | `GET /api/v1/orders`, `POST /api/v1/orders`, `PATCH /api/v1/orders/:id/status` | `SALES_STAFF`, `FARM_MANAGER` | Book order of 50 packs of 1 kg Ghee; verify listed in pending dispatch. | Should partial order dispatches be supported? |
| **REQ-MM-15** | Proposal p.2; V1 [03:58-04:05] | B. Milk to Market: Sales | Dispatch packaged stock to customer. Link to booked order if applicable. Deduct packaged stock ledger. Create accounts receivable entry. | Date, Packaging Batch, Packs Sold, Customer Name, Price Per Pack (₹), Amount Received (₹), Order Reference, Notes | `GET /api/v1/sales`, `POST /api/v1/sales` | `SALES_STAFF`, `ACCOUNTANT`, `FARM_MANAGER` | Dispatch 20 packs @ ₹50; customer pays ₹500 advance; verify packaged stock drops by 20, revenue recorded ₹1,000, outstanding ₹500. | Is a printable PDF delivery challan / receipt required? |
| **REQ-MM-16** | Proposal p.2; V1 [04:08-04:15] | B. Milk to Market: Customer Payments | Record later cash/UPI/bank receipts against outstanding customer sales balances. | Date, Sale Reference, Amount Received (₹), Payment Method (`Cash`, `UPI`, `Bank Transfer`, `Cheque`), Notes | `GET /api/v1/payments`, `POST /api/v1/payments` | `ACCOUNTANT`, `SALES_STAFF`, `FARM_OWNER` | Pay remaining ₹500 against prior sale; verify sale outstanding becomes ₹0. | Should overpayments/customer advances be credited to a customer ledger? |
| **REQ-BS-17** | Proposal p.2; V3 [00:00-00:32] | C. Business: Common Inventory | Central multi-category inventory (Feed, Medicine, Packaging, LPG, Cleaning, Consumable, Spare parts, Other). Manage stock items, receipts, and low-stock reorder triggers. | Item Name, Used By, Category, Unit, Reorder Level, Notes; Receipt: Date, Item, Qty, Supplier, Lot, Expiry, Total Cost (₹) | `GET /api/v1/inventory`, `POST /api/v1/inventory/items`, `POST /api/v1/inventory/receipts` | `STOREKEEPER`, `FARM_MANAGER`, `FARM_OWNER` | Receive 500 kg Maize @ ₹20/kg; verify stock = 500 kg; weighted average purchase price updated. | Does inventory use FIFO or weighted average cost for valuation? |
| **REQ-BS-18** | Proposal p.2; V3 [00:38-01:23] | C. Business: Biogas Fertiliser | Track digestate drying process $\to$ bulk dry fertiliser $\to$ packaging into $1\text{ kg}, 5\text{ kg}, 25\text{ kg}, 50\text{ kg}$ bags. Allocate dedicated electricity and costs. | Slurry/Digestate Input (kg), Moisture %, Dry Output Qty (kg), Packaging Run (bag size, bag count, packaging bags deducted), Costs | `GET /api/v1/biogas`, `POST /api/v1/biogas/production`, `POST /api/v1/biogas/packaging` | `FARM_MANAGER`, `ASSIGNED_OPERATOR`, `ACCOUNTANT` | Record 1,000 kg wet digestate producing 200 kg dry fertiliser; package into 8 bags of 25 kg; verify 8 bags ready for sale. | Is biogas methane gas production (cubic meters) tracked or only solid fertiliser? |
| **REQ-BS-19** | Proposal p.2; V3 [01:54-02:07] | C. Business: Wastage & Losses | Record operational losses against BMC tank, bulk product, packaged stock, or supplies with audit reason. | Date, Stock Type (`BMC`, `Bulk product`, `Packaged product`, `Supply`), Batch/Item Ref, Lost Qty, Reason (`Spoilage`, `Handling`, `Leakage`, `Loss`), Notes | `GET /api/v1/wastage`, `POST /api/v1/wastage` | `STOREKEEPER`, `PRODUCTION_OPERATOR`, `FARM_MANAGER` | Log 10 L milk lost due to pipe leakage; verify BMC tank drops by 10 L and appears in milk reconciliation audit. | Should supervisor sign-off/approval be required for wastage above a threshold? |
| **REQ-BS-20** | Proposal p.2; V3 [02:10-02:19] | C. Business: Costs & Expenses | Record operating expenditures categorized by Cost Centre (`Farm`, `Production`, `Biogas`) and Category (`Electricity`, `Vet`, `Transport`, `Maintenance`, `Cold room`, `Cleaning`, `Labour`, `Other`). | Date, Cost Centre, Category, Amount (₹), Production Batch (optional), Payee, Notes | `GET /api/v1/expenses`, `POST /api/v1/expenses` | `ACCOUNTANT`, `FARM_OWNER`, `FARM_MANAGER` | Add ₹1,200 tractor fuel to Farm; verify farm daily cost includes ₹1,200. | Can expenses be split across multiple cost centres automatically? |
| **REQ-BS-21** | Proposal p.3; V1 [00:32-00:45], V3 [02:24-02:34] | C. Business: Employees | Manage employee directory, department (`Farm`, `Production`, `Biogas`, `Management`), job title, monthly salary. Auto-derive daily payroll ($\text{Monthly Salary} \div 30$) for daily costing. | Full Name, Employee ID/Code, Department, Job Title, Joining Date, Last Working Day, Monthly Salary (₹), Status, Email, Phone, Notes | `GET /api/v1/employees`, `POST /api/v1/employees`, `PATCH /api/v1/employees/:id` | `HR_ADMIN`, `FARM_OWNER`, `FARM_MANAGER` | Add Manager @ ₹25,000/mo and Laborer @ ₹13,000/mo; verify daily payroll is $\frac{38000}{30} = ₹1,266.67$. | Is attendance tracked daily or is salary assumed 100% active unless status is inactive? |
| **REQ-BS-22** | Proposal p.3; V3 [02:36-02:45] | C. Business: FSSAI & Licences | Track food safety licence, pollution board, trade licences. Notify alerts based on configured `Reminder days before expiry` (default: 30 days). | Licence Name, Licence Number, Issuing Authority, Licence Holder, Issue Date, Expiry Date, Reminder Days, Status, Notes | `GET /api/v1/licences`, `POST /api/v1/licences` | `FARM_OWNER`, `FARM_MANAGER`, `AUDITOR` | Add FSSAI licence expiring in 25 days; verify active warning banner shown on dashboard. | Should renewal document upload (PDF/PNG) be supported? |
| **REQ-BS-23** | Proposal p.3; V3 [02:49-03:08] | C. Business: Reports & Exports | Provide date-range operational summaries, milk reconciliation (intake vs production vs wastage vs balance), and CSV export generators (Costs, Materials, Packaging, Staff, Licences) plus JSON full backup. | Date range (From, To) | `GET /api/v1/reports/summary`, `GET /api/v1/reports/export/:type`, `GET /api/v1/reports/backup/json` | `FARM_OWNER`, `FARM_MANAGER`, `ACCOUNTANT` | Generate Costs CSV for Oct 1-10; verify file downloads with valid headers and matching transactional sums. | Should exports be emailed or directly saved to device storage? |
| **REQ-BS-24** | Proposal p.3; V3 [03:11-03:31] | C. Business: Farm Settings | Manage master operational constants: BMC capacity, concentrate formula parameters (base, rate, cap), operator name, electricity tariff, default daily consumption, management salary split. | BMC Capacity (L), Base concentrate (kg), Additional concentrate/L, Max concentrate, Operator Name, Electricity Tariff (₹/unit), Farm default units, Production default units, Management salary allocation % to Farm | `GET /api/v1/settings`, `PUT /api/v1/settings` | `FARM_OWNER` (Super Admin only) | Change tariff to ₹2.0; verify new electricity entries default to ₹2.0/unit. | Can historical costing be recalculated if settings change, or only future entries? |

---

## 4. Analysis of Ambiguous Requirements & Key Domain Rules

### 4.1 Costing & Mathematical Formulas
1. **Daily Farm Milk Cost per Litre:**
   $$\text{Daily Farm Cost} = \text{Feed Consumed (₹)} + \text{Medicines Used (₹)} + \text{Other Farm Materials (₹)} + \text{Farm Daily Salaries (₹)} + \text{Farm Electricity (₹)} + \text{Other Farm Expenses (₹)}$$
   $$\text{Cost per Litre} = \frac{\text{Daily Farm Cost}}{\text{Eligible Farm Milk Recorded (L)}}$$
   *Rule:* If Eligible Farm Milk Recorded is 0, status is marked **Incomplete**, and cost per litre is undefined. Withheld milk is excluded from eligible yield.
2. **Management Salary Overhead Split:**
   * Default setting from Farm Settings: 50% allocated to Farm cost centre, 50% allocated to Production cost centre.
   * Daily individual salary $= \frac{\text{Monthly Salary}}{30}$.
3. **Feed Concentrate Calculation Formula:**
   $$\text{Target Concentrate (kg/day)} = \min\Big(\text{Base Concentrate (1 kg)} + \big(\text{Yield (L)} \times \text{Concentrate Factor (0.4 kg/L)}\big), \text{Max Concentrate (8 kg)}\Big)$$
   *Note:* Uses the cow's average yield over the recorded days in the last 7 days.
4. **Production Batch Overhead Sharing:**
   * Daily unlinked production expenses, production electricity, and production labor are shared across the day's batches proportionately based on **BMC Milk Consumed (L)**.
   * Linked expenses (entered directly against a batch ID) go directly to that batch.
   * Internal Farm Milk transfer price into Production uses the Farm's calculated Daily Cost per Litre to prevent double-counting in consolidated farm operating values.
5. **Electricity Consumption Defaults:**
   * If no manual meter reading is recorded for a date:
     * Farm defaults to **50 kWh/day** ($\times \text{tariff } ₹1.40 = ₹70.00/\text{day}$).
     * Production defaults to **200 kWh/day** ($\times \text{tariff } ₹1.40 = ₹280.00/\text{day}$).

### 4.2 Stock & Inventory Rules
1. **Material Ledger:** Double-entry perpetual inventory tracking stock-in (Receipts), stock-out (Feed issues, material issues, packaging consumption, batch fuel), and adjustments (Wastage).
2. **Valuation Method:** Weighted Average Cost based on verified purchase receipts.
3. **BMC Tank Stock Ledger:**
   $$\text{Closing BMC} = \text{Opening BMC} + \text{Accepted Intake} - \text{Sent to Production} - \text{BMC Wastage}$$
   *Rule:* Intake can be marked *Accepted* or *Rejected*. Only *Accepted* milk enters the tank.

### 4.3 User Roles & Authorization Hierarchy
The proposal defines 11 logical roles:
1. `FARM_OWNER` / Super Admin: Unrestricted permissions across all 24 modules, user management, farm settings.
2. `FARM_MANAGER`: Full operational read/write across herd, milking, production, stock, expenses, and reporting.
3. `ANIMAL_CARE`: Herd, Milking Log, Health, Breeding, Feed planning.
4. `BMC_OPERATOR`: BMC & Milk intake, tank volume inspection.
5. `PRODUCTION_OPERATOR`: Production Batches, Packaging, Material Issues.
6. `QC_STAFF`: Quality Records, Batch release approvals.
7. `STOREKEEPER`: Common Inventory, Stock Receipts, Material Issues, Wastage.
8. `SALES_STAFF`: Orders, Sales Dispatches, lookup payments.
9. `ACCOUNTANT`: Customer Payments, Costs & Expenses, Unit Costing, Reports/Exports.
10. `HR_ADMIN`: Employee Directory, salary records.
11. `AUDITOR`: Read-only access across compliance, records, and reports.

---

## 5. Scope Boundaries & Technical Non-Negotiables

- **Platform Scope:** Android-first mobile application in Flutter with tablet and landscape responsiveness.
- **Backend Stack:** Node.js, NestJS, TypeScript, TypeORM/Prisma with MySQL database, Swagger/OpenAPI.
- **Excluded by Proposal:**
  - Automated hardware integrations (IoT milk analyzers, digital BMC weigh scales, flow meters).
  - External banking/payment gateway APIs.
  - Statutory GST e-invoicing.
  - External biometrics/GPS tracking hardware.
