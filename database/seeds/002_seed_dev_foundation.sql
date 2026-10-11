-- ============================================================================
-- Dairy Farm Management System - Foundation & Dev Master Seed Data
-- Seed: 002_seed_dev_foundation.sql
-- ⚠️ WARNING: THIS SCRIPT IS FOR LOCAL DEVELOPMENT AND TESTING ONLY.
-- DO NOT EXECUTE AGAINST PRODUCTION SYSTEMS.
-- ============================================================================

-- 0. Ensure 12 Standard Roles (including Read-only Auditor / Consultant)
INSERT INTO `roles` (`id`, `code`, `name`, `description`) VALUES
('role-01', 'FARM_OWNER', 'Farm Owner / Super Admin', 'Full unrestricted administrative access across all 24 modules'),
('role-02', 'FARM_MANAGER', 'Farm Manager', 'Day-to-day farm management, operations, and supervisory access'),
('role-03', 'ANIMAL_CARE', 'Herd / Animal Care Staff', 'Herd registry, milking, veterinary health, breeding, and feed planning'),
('role-04', 'MILKING_STAFF', 'Milking Staff', 'Shift milking logs and milk yield entries'),
('role-05', 'BMC_OPERATOR', 'Milk Intake / BMC Operator', 'Bulk Milk Cooler intake and reception testing'),
('role-06', 'PRODUCTION_OPERATOR', 'Production / Packaging Operator', 'Production batch execution, packaging, and fuel logging'),
('role-07', 'QC_STAFF', 'Quality Control Staff', 'Quality inspection parameters and batch release approvals'),
('role-08', 'STOREKEEPER', 'Storekeeper / Inventory Staff', 'Common inventory stock receipts, issues, and wastage entries'),
('role-09', 'SALES_STAFF', 'Sales / Dispatch Staff', 'Customer orders, dispatch dispatches, and sales records'),
('role-10', 'ACCOUNTANT', 'Accountant / Finance Staff', 'Payments, operating costs, costing, and financial reports'),
('role-11', 'HR_ADMIN', 'HR / Employee Administrator', 'Staff directory, payroll allocation, and personnel records'),
('role-12', 'AUDITOR', 'Read-only Auditor / Consultant', 'Independent view-only inspection and compliance audit access')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `description` = VALUES(`description`);

-- 1. Standard Units of Measurement
INSERT INTO `units_of_measurement` (`id`, `code`, `name`, `dimension`, `conversion_factor`, `base_unit_code`, `is_active`, `created_at`) VALUES
('uom-ltr', 'LTR', 'Litre', 'VOLUME', 1.000000, 'LTR', 1, NOW()),
('uom-ml', 'ML', 'Millilitre', 'VOLUME', 0.001000, 'LTR', 1, NOW()),
('uom-kg', 'KG', 'Kilogram', 'MASS', 1.000000, 'KG', 1, NOW()),
('uom-gm', 'GM', 'Gram', 'MASS', 0.001000, 'KG', 1, NOW()),
('uom-unit', 'UNIT', 'Unit / Piece', 'COUNT', 1.000000, 'UNIT', 1, NOW()),
('uom-pkt', 'PKT', 'Packet', 'COUNT', 1.000000, 'UNIT', 1, NOW()),
('uom-box', 'BOX', 'Box', 'COUNT', 1.000000, 'UNIT', 1, NOW()),
('uom-can', 'CAN', 'Milk Can (40L)', 'VOLUME', 40.000000, 'LTR', 1, NOW()),
('uom-kwh', 'KWH', 'Kilowatt Hour', 'ENERGY', 1.000000, 'KWH', 1, NOW()),
('uom-hr', 'HR', 'Hour', 'TIME', 1.000000, 'HR', 1, NOW())
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `conversion_factor` = VALUES(`conversion_factor`);

-- 2. Lookup Categories
INSERT INTO `lookup_categories` (`id`, `code`, `name`, `description`, `created_at`) VALUES
('cat-breed', 'ANIMAL_BREED', 'Animal Breeds', 'Standard breeds for cows and buffaloes', NOW()),
('cat-species', 'ANIMAL_SPECIES', 'Animal Species', 'Taxonomic or livestock animal species', NOW()),
('cat-health', 'HEALTH_DIAGNOSIS', 'Health Diagnoses', 'Common dairy livestock ailments', NOW()),
('cat-feed', 'FEED_TYPE', 'Feed Categorization', 'Categories of cattle feeds and concentrates', NOW()),
('cat-paymode', 'PAYMENT_MODE', 'Payment Modes', 'Supported financial settlement modes', NOW()),
('cat-qgrade', 'QUALITY_GRADE', 'Milk Quality Grades', 'Milk quality categorization grades', NOW())
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

-- 3. Lookup Values
INSERT INTO `lookup_values` (`id`, `category_code`, `code`, `label`, `sort_order`, `is_active`, `metadata`, `created_at`) VALUES
-- Breeds
('val-br-hf', 'ANIMAL_BREED', 'HOLSTEIN_FRIESIAN', 'Holstein Friesian (HF)', 1, 1, '{"origin": "Europe"}', NOW()),
('val-br-jersey', 'ANIMAL_BREED', 'JERSEY', 'Jersey', 2, 1, '{"origin": "UK"}', NOW()),
('val-br-gir', 'ANIMAL_BREED', 'GIR', 'Gir Indigenous', 3, 1, '{"origin": "India"}', NOW()),
('val-br-sahiwal', 'ANIMAL_BREED', 'SAHIWAL', 'Sahiwal', 4, 1, '{"origin": "India"}', NOW()),
('val-br-murrah', 'ANIMAL_BREED', 'MURRAH', 'Murrah Buffalo', 5, 1, '{"origin": "India"}', NOW()),
-- Species
('val-sp-cow', 'ANIMAL_SPECIES', 'COW', 'Cow / Cattle', 1, 1, NULL, NOW()),
('val-sp-buf', 'ANIMAL_SPECIES', 'BUFFALO', 'Buffalo', 2, 1, NULL, NOW()),
-- Health Diagnoses
('val-hl-mastitis', 'HEALTH_DIAGNOSIS', 'MASTITIS', 'Mastitis', 1, 1, '{"severity": "HIGH"}', NOW()),
('val-hl-fever', 'HEALTH_DIAGNOSIS', 'FEVER', 'Bovine Fever', 2, 1, '{"severity": "MEDIUM"}', NOW()),
('val-hl-footrot', 'HEALTH_DIAGNOSIS', 'FOOT_ROT', 'Foot Rot', 3, 1, '{"severity": "MEDIUM"}', NOW()),
('val-hl-indigestion', 'HEALTH_DIAGNOSIS', 'INDIGESTION', 'Acidosis / Indigestion', 4, 1, '{"severity": "LOW"}', NOW()),
('val-hl-vac', 'HEALTH_DIAGNOSIS', 'ROUTINE_VACCINE', 'Routine Preventive Vaccination', 5, 1, '{"severity": "PREVENTIVE"}', NOW()),
-- Feed types
('val-fd-green', 'FEED_TYPE', 'GREEN_FODDER', 'Green Fodder', 1, 1, NULL, NOW()),
('val-fd-dry', 'FEED_TYPE', 'DRY_FODDER', 'Dry Fodder / Straw', 2, 1, NULL, NOW()),
('val-fd-conc', 'FEED_TYPE', 'CONCENTRATE', 'Concentrate Pellets / Mash', 3, 1, NULL, NOW()),
('val-fd-min', 'FEED_TYPE', 'MINERALS', 'Mineral & Salt Supplements', 4, 1, NULL, NOW()),
-- Payment Modes
('val-pm-cash', 'PAYMENT_MODE', 'CASH', 'Cash Payment', 1, 1, NULL, NOW()),
('val-pm-bank', 'PAYMENT_MODE', 'BANK_TRANSFER', 'NEFT / RTGS / Bank Transfer', 2, 1, NULL, NOW()),
('val-pm-upi', 'PAYMENT_MODE', 'UPI', 'Unified Payments Interface (UPI)', 3, 1, NULL, NOW()),
('val-pm-cheque', 'PAYMENT_MODE', 'CHEQUE', 'Cheque Deposit', 4, 1, NULL, NOW()),
-- Quality Grades
('val-qg-a', 'QUALITY_GRADE', 'GRADE_A', 'Grade A (Premium - Low MBRT, High FAT)', 1, 1, NULL, NOW()),
('val-qg-b', 'QUALITY_GRADE', 'GRADE_B', 'Grade B (Standard Acceptable)', 2, 1, NULL, NOW()),
('val-qg-c', 'QUALITY_GRADE', 'GRADE_C', 'Grade C (Borderline / Lower Price)', 3, 1, NULL, NOW()),
('val-qg-rej', 'QUALITY_GRADE', 'REJECTED', 'Rejected / Sour / Substandard', 4, 1, NULL, NOW())
ON DUPLICATE KEY UPDATE `label` = VALUES(`label`);

-- 4. Granular Permissions
INSERT INTO `permissions` (`id`, `code`, `name`, `module`, `description`, `created_at`) VALUES
('perm-01', 'farm:settings:read', 'Read Farm Settings', 'FARM_SETTINGS', 'View farm identity, rates and configuration', NOW()),
('perm-02', 'farm:settings:write', 'Update Farm Settings', 'FARM_SETTINGS', 'Modify farm identity, rates and system flags', NOW()),
('perm-03', 'users:read', 'Read Users & Roles', 'USERS', 'View staff users, roles and assignment', NOW()),
('perm-04', 'users:write', 'Manage Users & Roles', 'USERS', 'Create, update, activate or deactivate user accounts', NOW()),
('perm-05', 'master_data:read', 'Read Master Data', 'MASTER_DATA', 'View UOMs, lookups and reference data', NOW()),
('perm-06', 'master_data:write', 'Manage Master Data', 'MASTER_DATA', 'Create and edit UOMs and lookup values', NOW()),
('perm-07', 'audit:read', 'Read Audit Logs', 'AUDIT_LOGS', 'Access compliance and system audit trails', NOW()),
('perm-08', 'animals:read', 'Read Animal Herd', 'ANIMALS', 'View cattle registry and lifecycle info', NOW()),
('perm-09', 'animals:write', 'Manage Animals', 'ANIMALS', 'Register and edit livestock records', NOW()),
('perm-10', 'milking:read', 'Read Milking Logs', 'MILKING', 'View shift milking and yield totals', NOW()),
('perm-11', 'milking:write', 'Record Milking Logs', 'MILKING', 'Create and modify milking entries', NOW()),
('perm-12', 'feed:read', 'Read Feed Logs', 'FEED', 'View daily feed rations and distribution', NOW()),
('perm-13', 'feed:write', 'Record Feed Logs', 'FEED', 'Submit feed allocation entries', NOW()),
('perm-14', 'health:read', 'Read Health Records', 'HEALTH', 'View veterinary vaccinations and treatments', NOW()),
('perm-15', 'health:write', 'Record Health Logs', 'HEALTH', 'Add diagnoses, prescriptions and procedures', NOW()),
('perm-16', 'breeding:read', 'Read Breeding Records', 'BREEDING', 'View AI services, heat cycles and calvings', NOW()),
('perm-17', 'breeding:write', 'Record Breeding Logs', 'BREEDING', 'Record heat detection, inseminations and pregnancy', NOW()),
('perm-18', 'bmc:read', 'Read BMC Intake', 'BMC', 'View bulk milk cooler intake logbooks', NOW()),
('perm-19', 'bmc:write', 'Record BMC Intake', 'BMC', 'Log milk reception, fat/SNF tests and volume', NOW()),
('perm-20', 'production:read', 'Read Production Batches', 'PRODUCTION', 'View dairy processing and packaging logs', NOW()),
('perm-21', 'production:write', 'Record Production', 'PRODUCTION', 'Execute batches and packaging runs', NOW()),
('perm-22', 'quality:read', 'Read Quality Tests', 'QUALITY', 'View lab testing results and release notes', NOW()),
('perm-23', 'quality:write', 'Record Quality Tests', 'QUALITY', 'Submit fat, SNF, acidity and release decisions', NOW()),
('perm-24', 'inventory:read', 'Read Inventory', 'INVENTORY', 'View stock balances, reorder status and ledger', NOW()),
('perm-25', 'inventory:write', 'Manage Inventory', 'INVENTORY', 'Receive stock, issue materials and record wastage', NOW()),
('perm-26', 'sales:read', 'Read Sales & Orders', 'SALES', 'View customer orders, delivery dispatches', NOW()),
('perm-27', 'sales:write', 'Manage Sales', 'SALES', 'Book orders, record dispatches and invoices', NOW()),
('perm-28', 'finance:read', 'Read Financials', 'FINANCE', 'View customer payments, operating expenses and summaries', NOW()),
('perm-29', 'finance:write', 'Manage Financials', 'FINANCE', 'Record payments, settle bills and expenses', NOW()),
('perm-30', 'hr:read', 'Read HR Directory', 'HR', 'View employee roster and attendance', NOW()),
('perm-31', 'hr:write', 'Manage HR & Payroll', 'HR', 'Manage staff records and salary allocations', NOW()),
('perm-32', 'utilities:read', 'Read Utilities', 'UTILITIES', 'View electricity and biogas generation readings', NOW()),
('perm-33', 'utilities:write', 'Record Utilities', 'UTILITIES', 'Log electricity kWh and biogas operations', NOW())
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

-- 5. Role Permissions Mapping
-- Super Admin / Farm Owner (role-01) has all permissions
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT 'role-01', `id` FROM `permissions`;

-- Farm Manager (role-02) has operational, animal, inventory, sales, production, quality, hr permissions
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT 'role-02', `id` FROM `permissions`
WHERE `code` NOT IN ('audit:read', 'farm:settings:write', 'users:write');

-- Herd / Animal Care Staff (role-03)
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT 'role-03', `id` FROM `permissions`
WHERE `module` IN ('ANIMALS', 'MILKING', 'FEED', 'HEALTH', 'BREEDING')
   OR `code` IN ('master_data:read');

-- Milking Staff (role-04)
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT 'role-04', `id` FROM `permissions`
WHERE `module` IN ('MILKING') OR `code` IN ('animals:read');

-- Milk Intake / BMC Operator (role-05)
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT 'role-05', `id` FROM `permissions`
WHERE `module` IN ('BMC') OR `code` IN ('quality:read', 'quality:write', 'master_data:read');

-- Production / Packaging Operator (role-06)
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT 'role-06', `id` FROM `permissions`
WHERE `module` IN ('PRODUCTION') OR `code` IN ('inventory:read', 'master_data:read');

-- Quality Control Staff (role-07)
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT 'role-07', `id` FROM `permissions`
WHERE `module` IN ('QUALITY') OR `code` IN ('bmc:read', 'production:read', 'master_data:read');

-- Storekeeper / Inventory Staff (role-08)
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT 'role-08', `id` FROM `permissions`
WHERE `module` IN ('INVENTORY') OR `code` IN ('master_data:read');

-- Sales / Dispatch Staff (role-09)
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT 'role-09', `id` FROM `permissions`
WHERE `module` IN ('SALES') OR `code` IN ('inventory:read');

-- Accountant / Finance Staff (role-10)
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT 'role-10', `id` FROM `permissions`
WHERE `module` IN ('FINANCE') OR `code` IN ('sales:read', 'inventory:read', 'hr:read', 'master_data:read');

-- HR / Employee Administrator (role-11)
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT 'role-11', `id` FROM `permissions`
WHERE `module` IN ('HR') OR `code` IN ('users:read');

-- Read-only Auditor / Consultant (role-12) - STRICTLY READ-ONLY ACCESS ACROSS ALL DOMAINS
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT 'role-12', `id` FROM `permissions`
WHERE `code` LIKE '%:read';

-- 6. Development Users (Dev-Only with Bcrypt Hash for password: 'Password@123')
-- Hash: $2b$10$DUSMsCiD8nRTPegQpKXwAOR2Se3oNw6kauEddnjhpq8XZUkDZWvi6
INSERT INTO `users` (`id`, `email`, `password_hash`, `full_name`, `phone`, `is_active`, `created_at`, `updated_at`) VALUES
('usr-dev-admin', 'admin@dairyfarm.local', '$2b$10$DUSMsCiD8nRTPegQpKXwAOR2Se3oNw6kauEddnjhpq8XZUkDZWvi6', 'Arjun Patel', '+91 9876543210', 1, NOW(), NOW()),
('usr-dev-manager', 'manager@dairyfarm.local', '$2b$10$DUSMsCiD8nRTPegQpKXwAOR2Se3oNw6kauEddnjhpq8XZUkDZWvi6', 'Ramesh Kumar', '+91 9876543211', 1, NOW(), NOW()),
('usr-dev-store', 'store@dairyfarm.local', '$2b$10$DUSMsCiD8nRTPegQpKXwAOR2Se3oNw6kauEddnjhpq8XZUkDZWvi6', 'Sunil Verma', '+91 9876543212', 1, NOW(), NOW()),
('usr-dev-accountant', 'accountant@dairyfarm.local', '$2b$10$DUSMsCiD8nRTPegQpKXwAOR2Se3oNw6kauEddnjhpq8XZUkDZWvi6', 'Pooja Sharma', '+91 9876543213', 1, NOW(), NOW()),
('usr-dev-auditor', 'auditor@dairyfarm.local', '$2b$10$DUSMsCiD8nRTPegQpKXwAOR2Se3oNw6kauEddnjhpq8XZUkDZWvi6', 'Vikram Sen', '+91 9876543214', 1, NOW(), NOW())
ON DUPLICATE KEY UPDATE `full_name` = VALUES(`full_name`), `password_hash` = VALUES(`password_hash`);

-- Link Users to Roles
INSERT IGNORE INTO `user_roles` (`user_id`, `role_id`) VALUES
('usr-dev-admin', 'role-01'),
('usr-dev-manager', 'role-02'),
('usr-dev-store', 'role-08'),
('usr-dev-accountant', 'role-10'),
('usr-dev-auditor', 'role-12');

-- 7. Update Farm Settings Identity for Dev Farm
UPDATE `farm_settings`
SET `farm_name` = 'Kaivalya Dairy Farm & Processing',
    `address` = 'Dandiri, Near NH-26',
    `district` = 'Koraput',
    `state` = 'Odisha',
    `pincode` = '764036',
    `contact_phone` = '+91 9876543210',
    `contact_email` = 'support@kaivalyadairy.com',
    `currency_code` = 'INR',
    `currency_symbol` = '₹',
    `operator_name` = 'Kaivalya Team'
WHERE `id` = 1;
