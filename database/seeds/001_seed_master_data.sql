-- ============================================================================
-- Dairy Farm Management System - Master Seed Data
-- Seed: 001_seed_master_data.sql
-- ============================================================================

-- Seed 11 Standard Logical Roles
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
('role-10', 'ACCOUNTANT', 'Accountant / Finance Staff', 'Payments, operating costs, costing, and reports'),
('role-11', 'HR_ADMIN', 'HR / Employee Administrator', 'Staff directory, payroll allocation, and records')
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`);

-- Seed Default Farm Settings
INSERT INTO `farm_settings` (`id`, `bmc_capacity_litres`, `feed_base_kg`, `feed_rate_per_litre`, `feed_max_cap_kg`, `electricity_tariff`, `farm_default_kwh`, `production_default_kwh`, `mgmt_salary_to_farm_pct`, `operator_name`, `timezone`)
VALUES (1, 2000.00, 1.00, 0.40, 8.00, 1.40, 50.00, 200.00, 50.00, 'Kaivalya team', 'Asia/Kolkata')
ON DUPLICATE KEY UPDATE `operator_name`=VALUES(`operator_name`);

-- Seed Standard Stock Items from Video Prototype
INSERT INTO `stock_items` (`id`, `name`, `used_by`, `category`, `unit`, `current_stock`, `weighted_avg_price`, `reorder_level`) VALUES
('item-01', 'Maize', 'FARM', 'FEED', 'kg', 0.00, 22.00, 100.00),
('item-02', 'Mineral mixture', 'FARM', 'FEED', 'kg', 203.00, 40.00, 50.00),
('item-03', 'Salt', 'FARM', 'FEED', 'kg', 100.00, 10.00, 25.00),
('item-04', 'LPG 19kg cylinder', 'PRODUCTION', 'LPG', 'kg', 38.00, 110.00, 19.00),
('item-05', 'Milk packaging roller', 'PRODUCTION', 'PACKAGING', 'rolls', 10.00, 450.00, 2.00),
('item-06', 'Paneer packaging pouch', 'PRODUCTION', 'PACKAGING', 'units', 500.00, 2.50, 100.00)
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`);
