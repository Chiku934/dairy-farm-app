# Dairy Farm Management System - Approved Reports & Export Specifications

This document defines the approved operational and financial reports for the Dairy Farm Management System, their source data schemas, filtering parameters, aggregation formulas, permitted columns, and role-based data visibility boundaries.

---

## 1. Security & Export Privacy Standards

1. **Server-Side Authorization**: Every report endpoint and export stream verifies bearer JWT tokens and granular RBAC permissions.
2. **Formula Injection Sanitization (CWE-1236)**:
   - All user-controlled text fields exported to CSV or spreadsheet formats are strictly sanitized.
   - Any value beginning with `=`, `+`, `-`, `@`, `\t`, or `\r` is escaped with a prepended single quote (`'`) to prevent formula execution in spreadsheet software (Microsoft Excel, LibreOffice, Google Sheets).
   - Values containing commas, quotes, or line breaks are escaped in standard RFC 4180 format.
3. **Sensitive Data Protection**:
   - Wage and salary fields (`monthly_salary`, `daily_salary_rate`) are restricted strictly to `FARM_OWNER`, `HR_ADMIN`, and `ACCOUNTANT`.
   - Unauthorized requests attempting to export salary reports receive HTTP `403 Forbidden`.

---

## 2. Approved Report Catalogue

### 2.1 Milk Production & Shift Yield Report
* **Report Key:** `milk-production`
* **Required Permission:** `milking:read` (Owner, Manager, Animal Care, Milker, Auditor)
* **Source Tables:** `milking_records`, `milking_shifts`, `animals`
* **Filters:**
  - `startDate` (YYYY-MM-DD): Filter records on or after date.
  - `endDate` (YYYY-MM-DD): Filter records on or before date.
  - `session`: `MORNING` | `EVENING`.
  - `disposition`: `ELIGIBLE` | `WITHHELD` | `CALF_FEEDING`.
  - `animalId` (UUID): Specific cow ear tag filter.
* **Aggregation Rules:**
  - $\text{TotalYieldLitres} = \sum \text{yield\_litres}$
  - $\text{AvgFat} = \frac{\sum (\text{yield\_litres} \times \text{fat\_pct})}{\text{TotalYieldLitres}}$
  - $\text{AvgSNF} = \frac{\sum (\text{yield\_litres} \times \text{snf\_pct})}{\text{TotalYieldLitres}}$
  - $\text{WithheldVolumeLitres} = \sum_{\text{disposition} = \text{'WITHHELD'}} \text{yield\_litres}$
* **Permitted Columns:**
  `record_date`, `session`, `ear_tag`, `animal_name`, `yield_litres`, `fat_pct`, `snf_pct`, `disposition`, `notes`

---

### 2.2 Sales & Customer Revenue Report
* **Report Key:** `sales`
* **Required Permission:** `sales:read` or `finance:read` (Owner, Manager, Sales, Accountant, Auditor)
* **Source Tables:** `sales_records`, `sales_lines`, `customer_payments`, `customers`
* **Filters:**
  - `startDate` (YYYY-MM-DD), `endDate` (YYYY-MM-DD)
  - `customerId` (UUID): Specific customer account.
  - `customerType`: `RETAIL` | `WHOLESALE`.
  - `paymentMethod`: `CASH` | `UPI` | `BANK_TRANSFER` | `CHEQUE` | `CREDIT`.
* **Aggregation Rules:**
  - $\text{TotalGrossSales} = \sum \text{total\_amount}$
  - $\text{TotalPaymentsCollected} = \sum \text{amount\_received}$
  - $\text{TotalOutstandingReceivables} = \text{TotalGrossSales} - \text{TotalPaymentsCollected}$
* **Permitted Columns:**
  `sales_number`, `order_date`, `customer_name`, `customer_type`, `total_amount`, `paid_amount`, `balance_amount`, `payment_method`, `status`

---

### 2.3 Operating Expenses & P&L Cost Allocation Report
* **Report Key:** `expenses`
* **Required Permission:** `finance:read` (Owner, Manager, Accountant, Auditor)
* **Source Tables:** `operating_expenses`, `production_batches`
* **Filters:**
  - `startDate` (YYYY-MM-DD), `endDate` (YYYY-MM-DD)
  - `costCentre`: `FARM` | `PRODUCTION` | `BIOGAS`.
  - `category`: `FEED_SUPPLEMENT` | `VET` | `ELECTRICITY` | `TRANSPORT` | `MAINTENANCE` | `LABOUR` | etc.
* **Aggregation Rules:**
  - $\text{TotalExpenses} = \sum \text{amount}$
  - Cost Centre Breakdown: $\sum \text{amount}_{\text{FARM}}$, $\sum \text{amount}_{\text{PRODUCTION}}$, $\sum \text{amount}_{\text{BIOGAS}}$
* **Permitted Columns:**
  `expense_number`, `record_date`, `cost_centre`, `category`, `amount`, `payee`, `invoice_number`, `payment_method`, `notes`

---

### 2.4 Herd Inventory & Biological Status Report
* **Report Key:** `herd`
* **Required Permission:** `animals:read` (Owner, Manager, Animal Care, Milker, Auditor)
* **Source Tables:** `animals`, `health_records`, `breeding_records`
* **Filters:**
  - `status`: `LACTATING` | `DRY` | `PREGNANT` | `HEIFER` | `CALF` | `BULL` | `SOLD` | `DECEASED`.
  - `breed`: `GIR` | `SAHIWAL` | `HF` | `JERSEY` | `MURRAH`.
  - `isActive`: Boolean flag.
* **Aggregation Rules:**
  - Head Count by Status: $\text{Count}(status)$
  - Medically Withheld Animal Count: $\text{Count}(\text{withholding\_end\_date} \ge D_{\text{today}})$
* **Permitted Columns:**
  `ear_tag`, `name`, `breed`, `sex`, `status`, `date_of_birth`, `lactation_stage`, `active_withdrawal`, `withdrawal_end_date`

---

### 2.5 Feed & Inventory Valuation Report
* **Report Key:** `inventory`
* **Required Permission:** `inventory:read` (Owner, Manager, Storekeeper, Accountant, Auditor)
* **Source Tables:** `stock_items`, `stock_ledger_entries`
* **Filters:**
  - `usedBy`: `FARM` | `PRODUCTION` | `BIOGAS` | `GENERAL`.
  - `category`: `FEED` | `MEDICINE` | `PACKAGING` | `CONSUMABLE` | etc.
  - `lowStockOnly`: Boolean flag where `current_stock <= reorder_level`.
* **Aggregation Rules:**
  - $\text{TotalStockValuation} = \sum (\text{current\_stock} \times \text{weighted\_avg\_price})$
  - $\text{LowStockItemCount} = \sum [\text{current\_stock} \le \text{reorder\_level}]$
* **Permitted Columns:**
  `item_name`, `category`, `unit`, `current_stock`, `reorder_level`, `weighted_avg_price`, `stock_valuation`, `is_low_stock`

---

### 2.6 Staff Directory & Wage Rate Report (SENSITIVE / RESTRICTED)
* **Report Key:** `staff-payroll`
* **Required Clearance:** `hr:read` AND role in `{FARM_OWNER, HR_ADMIN, ACCOUNTANT}`
* **Source Tables:** `employees`
* **Filters:**
  - `department`: `FARM` | `PRODUCTION` | `BIOGAS` | `MANAGEMENT`.
  - `status`: `ACTIVE` | `ON_LEAVE` | `TERMINATED` | `RESIGNED`.
  - `isActive`: Boolean flag.
* **Aggregation Rules:**
  - Total Permanent Headcount: $\text{Count}(status = \text{'ACTIVE'})$
  - Total Monthly Salary Budget: $\sum \text{monthly\_salary}$
  - Total Daily Wage Liability: $\sum \text{daily\_salary\_rate}$
* **Permitted Columns (Authorized HR/Finance Roles Only):**
  `employee_code`, `full_name`, `department`, `job_title`, `joining_date`, `status`, `monthly_salary`, `daily_salary_rate`, `phone`, `email`
* **Security Enforcement:** Operational roles without salary clearance receive HTTP `403 Forbidden` on salary report/export endpoints.

---

### 2.7 Regulatory Licences Compliance Status Report
* **Report Key:** `licences`
* **Required Permission:** `farm:settings:read` (Owner, Manager, Accountant, Auditor)
* **Source Tables:** `regulatory_licences`
* **Filters:**
  - `licenceType`: `FSSAI` | `POLLUTION_CONTROL` | `TRADE_LICENSE` | etc.
  - `status`: `ACTIVE` | `EXPIRING_SOON` | `EXPIRED` | `SUSPENDED`.
* **Aggregation Rules:**
  - Total Licences: $\text{Count}(id)$
  - Expiring Licences Count: $\sum [\text{status} = \text{'EXPIRING\_SOON'}]$
  - Non-Compliant Expired Count: $\sum [\text{status} = \text{'EXPIRED'}]$
* **Permitted Columns:**
  `licence_name`, `licence_type`, `licence_number`, `issuing_authority`, `licence_holder`, `issue_date`, `expiry_date`, `status`, `reminder_status`
