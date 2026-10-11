-- ============================================================================
-- Dairy Farm Management System - Dashboard & Operational Dev Seed Data
-- Seed: 003_seed_dev_dashboard.sql
-- ⚠️ WARNING: FOR LOCAL DEV & TEST PURPOSE ONLY
-- ============================================================================

SET FOREIGN_KEY_CHECKS = 0;

-- 1. Animals (Herd Registry)
INSERT INTO `animals` (`id`, `ear_tag`, `name`, `breed`, `sex`, `date_of_birth`, `status`, `body_weight_kg`, `dam_tag`, `last_calving_date`, `body_condition_score`, `notes`, `created_at`, `updated_at`) VALUES
('c-01', 'TAG-101', 'Gauri', 'HOLSTEIN_FRIESIAN', 'FEMALE', DATE_SUB(CURDATE(), INTERVAL 4 YEAR), 'LACTATING', 480.00, NULL, DATE_SUB(CURDATE(), INTERVAL 60 DAY), 3.5, 'High yield prime cow', NOW(), NOW()),
('c-02', 'TAG-102', 'Kamadhenu', 'JERSEY', 'FEMALE', DATE_SUB(CURDATE(), INTERVAL 3 YEAR), 'LACTATING', 420.00, NULL, DATE_SUB(CURDATE(), INTERVAL 45 DAY), 3.7, 'Consistently healthy', NOW(), NOW()),
('c-03', 'TAG-103', 'Radha', 'GIR', 'FEMALE', DATE_SUB(CURDATE(), INTERVAL 5 YEAR), 'LACTATING', 460.00, NULL, DATE_SUB(CURDATE(), INTERVAL 90 DAY), 3.4, 'Indigenous A2 line', NOW(), NOW()),
('c-04', 'TAG-104', 'Surabhi', 'SAHIWAL', 'FEMALE', DATE_SUB(CURDATE(), INTERVAL 4 YEAR), 'LACTATING', 440.00, NULL, DATE_SUB(CURDATE(), INTERVAL 30 DAY), 3.6, 'Calved recently', NOW(), NOW()),
('c-05', 'TAG-105', 'Nandini', 'HOLSTEIN_FRIESIAN', 'FEMALE', DATE_SUB(CURDATE(), INTERVAL 6 YEAR), 'DRY', 510.00, NULL, DATE_SUB(CURDATE(), INTERVAL 310 DAY), 3.2, 'Dry period resting', NOW(), NOW()),
('c-06', 'TAG-106', 'Yamuna', 'MURRAH', 'FEMALE', DATE_SUB(CURDATE(), INTERVAL 4 YEAR), 'PREGNANT', 550.00, NULL, DATE_SUB(CURDATE(), INTERVAL 270 DAY), 3.8, 'Expected calving soon', NOW(), NOW()),
('c-07', 'TAG-107', 'Kapila', 'GIR', 'FEMALE', DATE_SUB(CURDATE(), INTERVAL 2 YEAR), 'HEIFER', 310.00, 'TAG-103', NULL, 3.5, 'First service upcoming', NOW(), NOW()),
('c-08', 'TAG-108', 'Champa', 'JERSEY', 'FEMALE', DATE_SUB(CURDATE(), INTERVAL 8 MONTH), 'CALF', 110.00, 'TAG-102', NULL, 3.5, 'Healthy female calf', NOW(), NOW()),
('c-09', 'TAG-109', 'Nandi', 'GIR', 'MALE', DATE_SUB(CURDATE(), INTERVAL 5 YEAR), 'BULL', 680.00, NULL, NULL, 4.0, 'Breeding stud bull', NOW(), NOW())
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `status` = VALUES(`status`);

-- 2. Master Stock Items
INSERT INTO `stock_items` (`id`, `name`, `used_by`, `category`, `unit`, `current_stock`, `weighted_avg_price`, `reorder_level`, `notes`) VALUES
('stk-conc', 'Standard Cattle Concentrate Pellets', 'FARM', 'FEED', 'KG', 850.00, 24.50, 200.00, 'Daily feed concentrate'),
('stk-green', 'Green Napier Grass / Fodder', 'FARM', 'FEED', 'KG', 2400.00, 3.50, 500.00, 'Fresh cut green fodder'),
('stk-dry', 'Dry Wheat Straw / Bhusa', 'FARM', 'FEED', 'KG', 1800.00, 6.00, 400.00, 'Dry roughage'),
('stk-med-anti', 'Veterinary Ceftiofur Antibiotic 100ml', 'FARM', 'MEDICINE', 'UNIT', 3.00, 480.00, 10.00, 'Safety withdrawal 72h'),
('stk-lpg', 'Commercial LPG Cylinder 19kg', 'PRODUCTION', 'LPG', 'UNIT', 8.00, 1750.00, 3.00, 'Paneer and ghee processing'),
('stk-pouch-500', 'Milk Pouches Food-Grade 500ml', 'PRODUCTION', 'PACKAGING', 'UNIT', 3200.00, 1.25, 500.00, 'Retail milk pouch film'),
('stk-jar-1k', 'Ghee Glass Jars with Lid 1kg', 'PRODUCTION', 'PACKAGING', 'UNIT', 450.00, 26.00, 100.00, 'Premium ghee jar packaging')
ON DUPLICATE KEY UPDATE `current_stock` = VALUES(`current_stock`), `reorder_level` = VALUES(`reorder_level`);

-- 3. Milking Logs (Today and Past 6 Days)
-- Cow 1: ~24L/day, Cow 2: ~18L/day, Cow 3: ~14L/day, Cow 4: ~16L/day
INSERT INTO `milking_logs` (`id`, `animal_id`, `record_date`, `session`, `yield_litres`, `disposition`, `withheld_reason`, `notes`, `created_at`) VALUES
-- Today
('ml-001', 'c-01', CURDATE(), 'MORNING', 13.50, 'ELIGIBLE', NULL, 'Normal morning milking', NOW()),
('ml-002', 'c-01', CURDATE(), 'EVENING', 11.00, 'ELIGIBLE', NULL, 'Normal evening milking', NOW()),
('ml-003', 'c-02', CURDATE(), 'MORNING', 10.00, 'ELIGIBLE', NULL, 'Normal morning milking', NOW()),
('ml-004', 'c-02', CURDATE(), 'EVENING', 8.50, 'ELIGIBLE', NULL, 'Normal evening milking', NOW()),
('ml-005', 'c-03', CURDATE(), 'MORNING', 8.00, 'ELIGIBLE', NULL, 'Normal morning milking', NOW()),
('ml-006', 'c-03', CURDATE(), 'EVENING', 6.50, 'ELIGIBLE', NULL, 'Normal evening milking', NOW()),
('ml-007', 'c-04', CURDATE(), 'MORNING', 9.50, 'WITHHELD', 'Active antibiotic safety withdrawal', 'Diverted to non-commercial pool', NOW()),
('ml-008', 'c-04', CURDATE(), 'EVENING', 7.50, 'WITHHELD', 'Active antibiotic safety withdrawal', 'Diverted to non-commercial pool', NOW()),

-- Yesterday (CURDATE() - 1)
('ml-011', 'c-01', DATE_SUB(CURDATE(), INTERVAL 1 DAY), 'MORNING', 13.00, 'ELIGIBLE', NULL, 'Milking yesterday AM', NOW()),
('ml-012', 'c-01', DATE_SUB(CURDATE(), INTERVAL 1 DAY), 'EVENING', 11.20, 'ELIGIBLE', NULL, 'Milking yesterday PM', NOW()),
('ml-013', 'c-02', DATE_SUB(CURDATE(), INTERVAL 1 DAY), 'MORNING', 9.80, 'ELIGIBLE', NULL, 'Milking yesterday AM', NOW()),
('ml-014', 'c-02', DATE_SUB(CURDATE(), INTERVAL 1 DAY), 'EVENING', 8.20, 'ELIGIBLE', NULL, 'Milking yesterday PM', NOW()),
('ml-015', 'c-03', DATE_SUB(CURDATE(), INTERVAL 1 DAY), 'MORNING', 7.80, 'ELIGIBLE', NULL, 'Milking yesterday AM', NOW()),
('ml-016', 'c-03', DATE_SUB(CURDATE(), INTERVAL 1 DAY), 'EVENING', 6.40, 'ELIGIBLE', NULL, 'Milking yesterday PM', NOW()),
('ml-017', 'c-04', DATE_SUB(CURDATE(), INTERVAL 1 DAY), 'MORNING', 9.00, 'ELIGIBLE', NULL, 'Pre-treatment milking', NOW()),
('ml-018', 'c-04', DATE_SUB(CURDATE(), INTERVAL 1 DAY), 'EVENING', 7.00, 'ELIGIBLE', NULL, 'Pre-treatment milking', NOW()),

-- 2 Days Ago (CURDATE() - 2)
('ml-021', 'c-01', DATE_SUB(CURDATE(), INTERVAL 2 DAY), 'MORNING', 13.20, 'ELIGIBLE', NULL, 'AM session', NOW()),
('ml-022', 'c-01', DATE_SUB(CURDATE(), INTERVAL 2 DAY), 'EVENING', 10.80, 'ELIGIBLE', NULL, 'PM session', NOW()),
('ml-023', 'c-02', DATE_SUB(CURDATE(), INTERVAL 2 DAY), 'MORNING', 10.10, 'ELIGIBLE', NULL, 'AM session', NOW()),
('ml-024', 'c-02', DATE_SUB(CURDATE(), INTERVAL 2 DAY), 'EVENING', 8.40, 'ELIGIBLE', NULL, 'PM session', NOW())
ON DUPLICATE KEY UPDATE `yield_litres` = VALUES(`yield_litres`);

-- 4. BMC Intake Logs
INSERT INTO `bmc_intake_logs` (`id`, `batch_number`, `record_date`, `source`, `supplier_route`, `quantity_litres`, `external_total_cost`, `decision`, `temperature_c`, `fat_percentage`, `snf_percentage`, `clr`, `ph`, `notes`, `created_at`) VALUES
('bmc-01', 'BMC-INT-202610-01', CURDATE(), 'FARM', 'Direct Milking Parlour', 57.50, 0.00, 'ACCEPTED', 3.8, 4.20, 8.65, 29.50, 6.65, 'Morning farm milk received', NOW()),
('bmc-02', 'BMC-INT-202610-02', DATE_SUB(CURDATE(), INTERVAL 1 DAY), 'FARM', 'Direct Milking Parlour', 72.40, 0.00, 'ACCEPTED', 4.0, 4.15, 8.60, 29.00, 6.68, 'Yesterday farm milk pooled', NOW()),
('bmc-03', 'BMC-INT-202610-03', DATE_SUB(CURDATE(), INTERVAL 1 DAY), 'EXTERNAL', 'Dandiri Route Collection', 150.00, 5250.00, 'ACCEPTED', 4.2, 4.00, 8.50, 28.50, 6.70, 'External route milk', NOW()),
('bmc-04', 'BMC-INT-202610-04', DATE_SUB(CURDATE(), INTERVAL 2 DAY), 'EXTERNAL', 'Sub-Centre B', 40.00, 1400.00, 'REJECTED', 12.5, 3.20, 7.80, 24.00, 6.10, 'Rejected due to high temperature and acidity', NOW())
ON DUPLICATE KEY UPDATE `quantity_litres` = VALUES(`quantity_litres`);

-- 5. Production Batches
INSERT INTO `production_batches` (`id`, `batch_number`, `record_date`, `product_type`, `bmc_milk_consumed_l`, `finished_quantity`, `unit_of_measure`, `lpg_used_kg`, `byproduct_quantity_kg`, `expiry_date`, `quality_release`, `notes`, `created_at`) VALUES
('pb-01', 'BATCH-MILK-001', CURDATE(), 'MILK', 50.00, 100.00, 'LITRE', 0.00, 0.00, DATE_ADD(CURDATE(), INTERVAL 3 DAY), 'APPROVED', 'Pasteurised 500ml pouches', NOW()),
('pb-02', 'BATCH-PAN-001', DATE_SUB(CURDATE(), INTERVAL 1 DAY), 'PANEER', 120.00, 21.60, 'KG', 2.50, 95.00, DATE_ADD(CURDATE(), INTERVAL 7 DAY), 'APPROVED', 'Fresh malai paneer batch', NOW())
ON DUPLICATE KEY UPDATE `finished_quantity` = VALUES(`finished_quantity`);

-- 6. Wastage Records (BMC / Spoilage)
INSERT INTO `wastage_records` (`id`, `record_date`, `stock_type`, `reference_id`, `quantity_lost`, `unit`, `reason`, `estimated_loss_cost`, `notes`, `created_by`, `created_at`) VALUES
('wst-01', DATE_SUB(CURDATE(), INTERVAL 1 DAY), 'BMC', 'TANK-01', 4.50, 'L', 'LEAKAGE', 157.50, 'Transfer valve gasket drip during cleaning', 'usr-dev-manager', NOW())
ON DUPLICATE KEY UPDATE `quantity_lost` = VALUES(`quantity_lost`);

-- 7. Commercial Customers & Sales Dispatches
INSERT INTO `customers` (`id`, `name`, `phone`, `email`, `address`, `customer_type`, `credit_limit`, `current_balance`, `is_active`, `created_at`) VALUES
('cust-01', 'Koraput Fresh Dairy Outlet', '+91 9437012345', 'outlet@koraputfresh.com', 'Main Bazaar, Koraput', 'WHOLESALE', 25000.00, 3200.00, 1, NOW()),
('cust-02', 'Aditi Verma', '+91 9861054321', 'aditi.v@gmail.com', 'NH Colony, Dandiri', 'RETAIL', 0.00, 0.00, 1, NOW())
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

INSERT INTO `sales_dispatches` (`id`, `dispatch_number`, `order_id`, `customer_id`, `record_date`, `packaging_run_id`, `product_type`, `packs_sold`, `price_per_pack`, `total_amount`, `amount_received`, `balance_due`, `payment_method`, `notes`, `created_by`, `created_at`) VALUES
('dsp-01', 'DSP-202610-001', NULL, 'cust-01', CURDATE(), NULL, 'MILK', 80, 32.00, 2560.00, 2560.00, 0.00, 'UPI', 'Morning dispatch of fresh pouches', 'usr-dev-admin', NOW()),
('dsp-02', 'DSP-202610-002', NULL, 'cust-02', CURDATE(), NULL, 'PANEER', 2, 90.00, 180.00, 180.00, 0.00, 'CASH', 'Retail paneer sale', 'usr-dev-admin', NOW()),
('dsp-03', 'DSP-202610-003', NULL, 'cust-01', DATE_SUB(CURDATE(), INTERVAL 1 DAY), NULL, 'MILK', 100, 32.00, 3200.00, 2000.00, 1200.00, 'BANK_TRANSFER', 'Yesterday morning route delivery', 'usr-dev-admin', NOW())
ON DUPLICATE KEY UPDATE `total_amount` = VALUES(`total_amount`);

-- 8. Operating Expenses & Electricity Readings
INSERT INTO `operating_expenses` (`id`, `record_date`, `cost_centre`, `category`, `amount`, `production_batch_id`, `payee`, `payment_method`, `notes`, `created_by`, `created_at`) VALUES
('exp-01', CURDATE(), 'FARM', 'MAINTENANCE', 350.00, NULL, 'Local Hardware Dandiri', 'CASH', 'Milking parlour washdown nozzle repair', 'usr-dev-manager', NOW()),
('exp-02', DATE_SUB(CURDATE(), INTERVAL 1 DAY), 'FARM', 'VET', 650.00, NULL, 'Dr. B. K. Panda (Veterinary surgeon)', 'UPI', 'Treatment and check-up for mastitis prevention', 'usr-dev-manager', NOW()),
('exp-03', DATE_SUB(CURDATE(), INTERVAL 1 DAY), 'PRODUCTION', 'CLEANING', 420.00, NULL, 'Chemical Supplies Koraput', 'CASH', 'CIP cleaning acid & sanitizer', 'usr-dev-manager', NOW())
ON DUPLICATE KEY UPDATE `amount` = VALUES(`amount`);

INSERT INTO `electricity_readings` (`id`, `record_date`, `department`, `units_kwh`, `tariff_rate`, `total_cost`, `notes`, `created_by`, `created_at`) VALUES
('el-01', CURDATE(), 'FARM', 48.00, 1.40, 67.20, 'Parlour meter reading', 'usr-dev-manager', NOW()),
('el-02', CURDATE(), 'PRODUCTION', 185.00, 1.40, 259.00, 'Cold room and processing meter', 'usr-dev-manager', NOW()),
('el-03', DATE_SUB(CURDATE(), INTERVAL 1 DAY), 'FARM', 52.00, 1.40, 72.80, 'Parlour meter reading', 'usr-dev-manager', NOW()),
('el-04', DATE_SUB(CURDATE(), INTERVAL 1 DAY), 'PRODUCTION', 190.00, 1.40, 266.00, 'Processing plant meter', 'usr-dev-manager', NOW())
ON DUPLICATE KEY UPDATE `total_cost` = VALUES(`total_cost`);

-- 9. Active Employees (Farm Salaries)
INSERT INTO `employees` (`id`, `employee_code`, `full_name`, `department`, `job_title`, `joining_date`, `monthly_salary`, `is_active`, `phone`, `email`, `created_at`) VALUES
('emp-01', 'EMP-1001', 'Harihar Majhi', 'FARM', 'Senior Milker & Animal Attendant', DATE_SUB(CURDATE(), INTERVAL 2 YEAR), 15000.00, 1, '+91 9437100001', 'harihar@kaivalyadairy.com', NOW()),
('emp-02', 'EMP-1002', 'Bipin Behera', 'FARM', 'Fodder & Herd Caregiver', DATE_SUB(CURDATE(), INTERVAL 1 YEAR), 13500.00, 1, '+91 9437100002', 'bipin@kaivalyadairy.com', NOW()),
('emp-03', 'EMP-1003', 'Sunil Nayak', 'MANAGEMENT', 'Farm Operations Manager', DATE_SUB(CURDATE(), INTERVAL 3 YEAR), 30000.00, 1, '+91 9437100003', 'manager@kaivalyadairy.com', NOW())
ON DUPLICATE KEY UPDATE `monthly_salary` = VALUES(`monthly_salary`);

-- 10. Biogas Runs (Dry Fertiliser Output)
INSERT INTO `biogas_runs` (`id`, `record_date`, `slurry_input_kg`, `dry_fertiliser_output_kg`, `moisture_pct`, `bags_packed_1kg`, `bags_packed_5kg`, `bags_packed_25kg`, `bags_packed_50kg`, `notes`, `created_by`, `created_at`) VALUES
('bio-01', CURDATE(), 450.00, 75.00, 14.50, 0, 5, 2, 0, 'Morning drying bed batch', 'usr-dev-manager', NOW()),
('bio-02', DATE_SUB(CURDATE(), INTERVAL 1 DAY), 500.00, 85.00, 15.00, 10, 10, 1, 0, 'Yesterday solar drying cycle', 'usr-dev-manager', NOW())
ON DUPLICATE KEY UPDATE `dry_fertiliser_output_kg` = VALUES(`dry_fertiliser_output_kg`);

-- 11. Regulatory Licences (Expiring Alert Trigger)
INSERT INTO `regulatory_licences` (`id`, `licence_name`, `licence_number`, `issuing_authority`, `licence_holder`, `issue_date`, `expiry_date`, `reminder_days_before`, `status`, `notes`, `created_at`) VALUES
('lic-01', 'FSSAI Food Business Registration & Safety Licence', 'FSSAI-12023004000128', 'Food Safety and Standards Authority of India', 'Kaivalya Dairy', DATE_SUB(CURDATE(), INTERVAL 345 DAY), DATE_ADD(CURDATE(), INTERVAL 20 DAY), 30, 'EXPIRING_SOON', 'Renewal audit file submitted', NOW()),
('lic-02', 'Consent to Operate (Green Category Dairy Farm)', 'SPCB-KPT-2024-0089', 'State Pollution Control Board Odisha', 'Kaivalya Dairy Farm', DATE_SUB(CURDATE(), INTERVAL 1 YEAR), DATE_ADD(CURDATE(), INTERVAL 280 DAY), 60, 'ACTIVE', 'Valid environmental compliance certificate', NOW())
ON DUPLICATE KEY UPDATE `expiry_date` = VALUES(`expiry_date`), `status` = VALUES(`status`);

-- 12. Health & Veterinary Alerts (Milk Withdrawal Safety)
INSERT INTO `health_records` (`id`, `animal_id`, `record_date`, `care_type`, `medicine_vaccine`, `prescribed_dose`, `veterinarian`, `next_due_date`, `withdrawal_until`, `notes`, `created_at`) VALUES
('hl-01', 'c-04', DATE_SUB(CURDATE(), INTERVAL 1 DAY), 'TREATMENT', 'Ceftiofur Sodium Injection', '10ml IM', 'Dr. B. K. Panda', DATE_ADD(CURDATE(), INTERVAL 2 DAY), DATE_ADD(CURDATE(), INTERVAL 2 DAY), 'Mild udder inflammation. Milk withheld for 72h.', NOW())
ON DUPLICATE KEY UPDATE `withdrawal_until` = VALUES(`withdrawal_until`);

-- 13. Breeding Records (Upcoming Calving Alert)
INSERT INTO `breeding_records` (`id`, `animal_id`, `record_date`, `event_type`, `sire_semen_id`, `expected_calving_date`, `calf_tag`, `notes`, `created_by`, `created_at`) VALUES
('br-01', 'c-06', DATE_SUB(CURDATE(), INTERVAL 272 DAY), 'PREGNANCY_CONFIRMED', 'SIRE-GIR-PRIME-09', DATE_ADD(CURDATE(), INTERVAL 8 DAY), NULL, 'Cow Yamuna expected calving within 8 days', 'usr-dev-manager', NOW())
ON DUPLICATE KEY UPDATE `expected_calving_date` = VALUES(`expected_calving_date`);

SET FOREIGN_KEY_CHECKS = 1;
