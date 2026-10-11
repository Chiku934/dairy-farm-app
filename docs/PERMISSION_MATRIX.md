# Dairy Farm Management System - Role-Based Access Control (RBAC) Permission Matrix

## 1. Security Architecture & Principles

1. **Server-Side Enforcement is Primary:** UI button disabling or menu hiding in the Flutter client is purely for user experience. Every API request is strictly verified by `JwtAuthGuard`, `RolesGuard`, and `PermissionsGuard` in NestJS.
2. **Principle of Least Privilege:** Operational staff accounts (e.g. Milkers, BMC Operators, Animal Care Staff, Storekeepers) are restricted to their operational domains and denied access to financial data, salaries, user administration, and enterprise settings.
3. **Sensitive Domain Isolation:**
   * **Salaries & Payroll:** Restricted strictly to `HR_ADMIN`, `ACCOUNTANT` (read-only), and `FARM_OWNER`.
   * **Financial Ledgers & Cash Flow:** Restricted strictly to `ACCOUNTANT` and `FARM_OWNER`.
   * **User & Credential Administration:** Restricted strictly to `FARM_OWNER`.
   * **Independent Auditor Access:** `AUDITOR` role receives strictly read-only access (`*:read`) across all modules with **zero** write, create, edit, approve, or admin rights.

---

## 2. Logical Roles Definition

| Role ID | Role Code | Display Title | Description & Operational Scope |
| :--- | :--- | :--- | :--- |
| `role-01` | `FARM_OWNER` | Farm Owner / Super Admin | Unrestricted administrative and financial authority over all 24 modules. |
| `role-02` | `FARM_MANAGER` | Farm Manager | Operational supervision across herd, milking, feed, processing, sales, and labor. Excludes sensitive user admin and audit logs. |
| `role-03` | `ANIMAL_CARE` | Herd / Animal Care Staff | Cattle registration, veterinary health logs, artificial insemination/breeding, and daily feed logging. |
| `role-04` | `MILKING_STAFF` | Milking Staff | Shift milking logs, individual cow yield recording, and milk withholding tags. |
| `role-05` | `BMC_OPERATOR` | Milk Intake / BMC Operator | Bulk Milk Cooler reception, lactometer tests (Fat, SNF, CLR), route intakes, and quality acceptance gates. |
| `role-06` | `PRODUCTION_OPERATOR`| Production / Packaging Operator | Dairy processing batches (paneer, khoya, ghee), retail packaging runs, and fuel logging. |
| `role-07` | `QC_STAFF` | Quality Control Staff | Laboratory analysis, batch testing parameters, organoleptic checks, and batch release/hold gates. |
| `role-08` | `STOREKEEPER` | Storekeeper / Inventory Staff | Common inventory stock receipts, stock issues, and spoilage/wastage recording. |
| `role-09` | `SALES_STAFF` | Sales / Dispatch Staff | Customer delivery dispatches, order fulfillment, and wholesale order booking. |
| `role-10` | `ACCOUNTANT` | Accountant / Finance Staff | Customer payment receipts, operating cash expenses, cost allocation, and financial P&L summaries. |
| `role-11` | `HR_ADMIN` | HR / Employee Administrator | Staff roster directory, daily labor allocation, and salary record administration. |
| `role-12` | `AUDITOR` | Read-only Auditor / Consultant | External inspection, compliance verification, and read-only financial/audit trail reporting. |

---

## 3. Granular Permission Matrix

| Permission Code | Capability / Scope | OWNER | MGR | ANIMAL | MILK | BMC | PROD | QC | STORE | SALES | ACCT | HR | AUDIT |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| `farm:settings:read` | View farm identity & tariffs | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ |
| `farm:settings:write`| Modify farm parameters & tariffs | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `users:read` | View user directory & roles | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| `users:write` | Create, edit, deactive users | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `master_data:read` | View UOMs & taxonomy lookups | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | ✅ |
| `master_data:write` | Create UOMs & lookup options | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `audit:read` | View immutable audit trail logs | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| `animals:read` | View cattle registry & status | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| `animals:write` | Register, edit, retire cattle | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `milking:read` | View shift yields & milk logs | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| `milking:write` | Record morning/evening milkings | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `feed:read` | View feed rations & targets | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| `feed:write` | Issue cattle feed entries | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `health:read` | View health & vaccination logs | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| `health:write` | Record treatments & withdrawal | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `breeding:read` | View AI & calving records | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| `breeding:write` | Record heat & insemination | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `bmc:read` | View BMC intake records | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ |
| `bmc:write` | Log milk intake & test results | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `production:read` | View dairy processing batches | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ |
| `production:write` | Execute processing & packaging | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `quality:read` | View lab test parameter records | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ |
| `quality:write` | Record fat/SNF & approve/hold | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `inventory:read` | View perpetual stock balances | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ | ✅ | ✅ | ❌ | ✅ |
| `inventory:write` | Receive stock, issues & wastage | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ |
| `sales:read` | View orders & delivery dispatches | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ | ✅ |
| `sales:write` | Book orders & log dispatches | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |
| `finance:read` | View revenue, costs & payments | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ |
| `finance:write` | Record customer payments & exp | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ |
| `hr:read` | View staff directory & salary | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ |
| `hr:write` | Manage personnel & wage rates | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ |
| `utilities:read` | View power & biogas readings | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| `utilities:write` | Log meter units & biogas runs | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |

---

## 4. Administrative Security Boundaries

1. **Role Escalation Protection:**
   * Only callers with `FARM_OWNER` role may assign or modify role memberships on any user account.
   * A user can never escalate their own permissions or grant permissions outside their assigned role profile.
2. **Account Deactivation Immediate Revocation:**
   * When an administrative deactivation occurs (`PATCH /api/v1/users/:id/status` with `isActive: false`), the backend transaction immediately sets `is_revoked = 1` for all active refresh token sessions belonging to that user.
   * Subsequent API requests with cached tokens fail validation immediately upon database verification.
3. **Sensitive Rate Limiting:**
   * `POST /api/v1/auth/login`: Strictly throttled to a maximum of **5 attempts per minute per IP address**.
   * `POST /api/v1/auth/refresh`: Throttled to **10 attempts per minute per IP address**.
   * Exceeding the rate limit returns `HTTP 429 Too Many Requests`.
