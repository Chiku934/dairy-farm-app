-- ============================================================================
-- Dairy Farm Management System - Foundation & Complete Domain Relational Schema
-- Migration: 002_foundation_and_domain_schema.sql
-- Engine: InnoDB | Character Set: utf8mb4 | Collation: utf8mb4_unicode_ci
-- Enforces strict DECIMAL types for currency and measurements, ACID foreign keys,
-- query-pattern indices, audit logging, and role-based permissions.
-- ============================================================================

SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------------------------------------------------------
-- 1. Farm Settings & Identity Enhancements
-- ----------------------------------------------------------------------------
ALTER TABLE `farm_settings`
  ADD COLUMN IF NOT EXISTS `farm_name` VARCHAR(120) NOT NULL DEFAULT 'Kaivalya Dairy',
  ADD COLUMN IF NOT EXISTS `address` VARCHAR(255) NOT NULL DEFAULT 'Dandiri',
  ADD COLUMN IF NOT EXISTS `district` VARCHAR(80) NOT NULL DEFAULT 'Koraput',
  ADD COLUMN IF NOT EXISTS `state` VARCHAR(80) NOT NULL DEFAULT 'Odisha',
  ADD COLUMN IF NOT EXISTS `pincode` VARCHAR(10) NOT NULL DEFAULT '764036',
  ADD COLUMN IF NOT EXISTS `contact_phone` VARCHAR(20) NOT NULL DEFAULT '+91 9876543210',
  ADD COLUMN IF NOT EXISTS `contact_email` VARCHAR(100) NOT NULL DEFAULT 'contact@kaivalyadairy.com',
  ADD COLUMN IF NOT EXISTS `currency_code` VARCHAR(10) NOT NULL DEFAULT 'INR',
  ADD COLUMN IF NOT EXISTS `currency_symbol` VARCHAR(5) NOT NULL DEFAULT '₹';

-- ----------------------------------------------------------------------------
-- 2. Permissions & Role Permissions
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `permissions` (
  `id` VARCHAR(36) NOT NULL,
  `code` VARCHAR(80) NOT NULL UNIQUE,
  `name` VARCHAR(120) NOT NULL,
  `module` VARCHAR(50) NOT NULL,
  `description` TEXT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_permissions_module` (`module`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `role_permissions` (
  `role_id` VARCHAR(36) NOT NULL,
  `permission_id` VARCHAR(36) NOT NULL,
  PRIMARY KEY (`role_id`, `permission_id`),
  CONSTRAINT `fk_role_permissions_role` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_role_permissions_permission` FOREIGN KEY (`permission_id`) REFERENCES `permissions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 3. Authentication Sessions & Refresh Tokens
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `user_sessions` (
  `id` VARCHAR(36) NOT NULL,
  `user_id` VARCHAR(36) NOT NULL,
  `refresh_token_hash` VARCHAR(255) NOT NULL,
  `ip_address` VARCHAR(45) NULL,
  `user_agent` VARCHAR(255) NULL,
  `is_revoked` BOOLEAN NOT NULL DEFAULT FALSE,
  `expires_at` DATETIME NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_sessions_user` (`user_id`),
  INDEX `idx_sessions_expires` (`expires_at`),
  CONSTRAINT `fk_user_sessions_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 4. Units of Measurement (UOM)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `units_of_measurement` (
  `id` VARCHAR(36) NOT NULL,
  `code` VARCHAR(20) NOT NULL UNIQUE,
  `name` VARCHAR(60) NOT NULL,
  `dimension` ENUM('VOLUME', 'MASS', 'COUNT', 'ENERGY', 'TIME', 'OTHER') NOT NULL,
  `conversion_factor` DECIMAL(12,6) NOT NULL DEFAULT 1.000000,
  `base_unit_code` VARCHAR(20) NULL,
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_uom_dimension` (`dimension`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 5. Shared Lookups / Master Data
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `lookup_categories` (
  `id` VARCHAR(36) NOT NULL,
  `code` VARCHAR(50) NOT NULL UNIQUE,
  `name` VARCHAR(100) NOT NULL,
  `description` TEXT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `lookup_values` (
  `id` VARCHAR(36) NOT NULL,
  `category_code` VARCHAR(50) NOT NULL,
  `code` VARCHAR(50) NOT NULL,
  `label` VARCHAR(100) NOT NULL,
  `sort_order` INT NOT NULL DEFAULT 0,
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
  `metadata` JSON NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_lookup_category_code` (`category_code`, `code`),
  INDEX `idx_lookup_category` (`category_code`),
  CONSTRAINT `fk_lookup_category` FOREIGN KEY (`category_code`) REFERENCES `lookup_categories` (`code`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 6. Central Audit Logging
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `audit_logs` (
  `id` VARCHAR(36) NOT NULL,
  `user_id` VARCHAR(36) NULL,
  `action` VARCHAR(50) NOT NULL,
  `entity_type` VARCHAR(60) NOT NULL,
  `entity_id` VARCHAR(36) NULL,
  `old_values` JSON NULL,
  `new_values` JSON NULL,
  `ip_address` VARCHAR(45) NULL,
  `user_agent` VARCHAR(255) NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_audit_entity` (`entity_type`, `entity_id`),
  INDEX `idx_audit_user` (`user_id`),
  INDEX `idx_audit_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 7. Domain A: Breeding & Calving, Feed Entries
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `breeding_records` (
  `id` VARCHAR(36) NOT NULL,
  `animal_id` VARCHAR(36) NOT NULL,
  `record_date` DATE NOT NULL,
  `event_type` ENUM('HEAT', 'INSEMINATION', 'PREGNANCY_CONFIRMED', 'PREGNANCY_CHECK', 'CALVING', 'DRY_OFF') NOT NULL,
  `sire_semen_id` VARCHAR(100) NULL,
  `expected_calving_date` DATE NULL,
  `calf_tag` VARCHAR(50) NULL,
  `notes` TEXT NULL,
  `created_by` VARCHAR(36) NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_breeding_animal` (`animal_id`),
  INDEX `idx_breeding_date` (`record_date`),
  INDEX `idx_breeding_expected_calving` (`expected_calving_date`),
  CONSTRAINT `fk_breeding_animal` FOREIGN KEY (`animal_id`) REFERENCES `animals` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `feed_entries` (
  `id` VARCHAR(36) NOT NULL,
  `animal_id` VARCHAR(36) NOT NULL,
  `record_date` DATE NOT NULL,
  `stock_item_id` VARCHAR(36) NOT NULL,
  `quantity_kg` DECIMAL(8,2) NOT NULL,
  `feed_type` ENUM('CONCENTRATE', 'GREEN_FODDER', 'DRY_FODDER', 'MINERAL_MIXTURE', 'SALT', 'MAIZE', 'CALF_STARTER') NOT NULL,
  `notes` TEXT NULL,
  `created_by` VARCHAR(36) NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_feed_animal` (`animal_id`),
  INDEX `idx_feed_date` (`record_date`),
  INDEX `idx_feed_stock_item` (`stock_item_id`),
  CONSTRAINT `fk_feed_animal` FOREIGN KEY (`animal_id`) REFERENCES `animals` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_feed_stock_item` FOREIGN KEY (`stock_item_id`) REFERENCES `stock_items` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 8. Domain B: Packaging Runs, Quality Records, Material Issues, Electricity
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `packaging_runs` (
  `id` VARCHAR(36) NOT NULL,
  `record_date` DATE NOT NULL,
  `production_batch_id` VARCHAR(36) NOT NULL,
  `pack_size` DECIMAL(6,2) NOT NULL,
  `pack_unit` ENUM('LITRE', 'KG') NOT NULL,
  `number_of_packs` INT NOT NULL,
  `packaging_item_id` VARCHAR(36) NOT NULL,
  `material_consumed` DECIMAL(8,2) NOT NULL,
  `notes` TEXT NULL,
  `created_by` VARCHAR(36) NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_pkg_batch` (`production_batch_id`),
  INDEX `idx_pkg_date` (`record_date`),
  CONSTRAINT `fk_pkg_prod_batch` FOREIGN KEY (`production_batch_id`) REFERENCES `production_batches` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_pkg_stock_item` FOREIGN KEY (`packaging_item_id`) REFERENCES `stock_items` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `quality_records` (
  `id` VARCHAR(36) NOT NULL,
  `record_date` DATE NOT NULL,
  `target_type` ENUM('INTAKE', 'PRODUCTION_BATCH', 'BMC') NOT NULL,
  `target_id` VARCHAR(50) NOT NULL,
  `fat_percentage` DECIMAL(4,2) NULL,
  `snf_percentage` DECIMAL(4,2) NULL,
  `clr` DECIMAL(5,2) NULL,
  `ph` DECIMAL(3,2) NULL,
  `temperature_c` DECIMAL(4,1) NULL,
  `decision` ENUM('PENDING', 'APPROVED', 'REJECTED') NOT NULL DEFAULT 'PENDING',
  `tested_by` VARCHAR(100) NULL,
  `notes` TEXT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_quality_target` (`target_type`, `target_id`),
  INDEX `idx_quality_date` (`record_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `material_issues` (
  `id` VARCHAR(36) NOT NULL,
  `record_date` DATE NOT NULL,
  `department` ENUM('FARM', 'PRODUCTION', 'BIOGAS') NOT NULL,
  `stock_item_id` VARCHAR(36) NOT NULL,
  `quantity` DECIMAL(10,2) NOT NULL,
  `production_batch_id` VARCHAR(36) NULL,
  `issued_to` VARCHAR(100) NULL,
  `notes` TEXT NULL,
  `created_by` VARCHAR(36) NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_material_dept` (`department`),
  INDEX `idx_material_date` (`record_date`),
  INDEX `idx_material_stock` (`stock_item_id`),
  CONSTRAINT `fk_material_stock_item` FOREIGN KEY (`stock_item_id`) REFERENCES `stock_items` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `electricity_readings` (
  `id` VARCHAR(36) NOT NULL,
  `record_date` DATE NOT NULL,
  `department` ENUM('FARM', 'PRODUCTION', 'BIOGAS') NOT NULL,
  `units_kwh` DECIMAL(8,2) NOT NULL,
  `tariff_rate` DECIMAL(6,2) NOT NULL,
  `total_cost` DECIMAL(10,2) NOT NULL,
  `notes` TEXT NULL,
  `created_by` VARCHAR(36) NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_elec_dept_date` (`record_date`, `department`),
  INDEX `idx_elec_date` (`record_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 9. Commercial: Customers, Orders, Dispatches & Payments
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `customers` (
  `id` VARCHAR(36) NOT NULL,
  `name` VARCHAR(120) NOT NULL,
  `phone` VARCHAR(20) NULL,
  `email` VARCHAR(120) NULL,
  `address` VARCHAR(255) NULL,
  `customer_type` ENUM('RETAIL', 'WHOLESALE') NOT NULL DEFAULT 'RETAIL',
  `credit_limit` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  `current_balance` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_customer_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sales_orders` (
  `id` VARCHAR(36) NOT NULL,
  `order_number` VARCHAR(50) NOT NULL UNIQUE,
  `customer_id` VARCHAR(36) NOT NULL,
  `order_date` DATE NOT NULL,
  `delivery_date` DATE NOT NULL,
  `status` ENUM('PENDING', 'FULFILLED', 'CANCELLED') NOT NULL DEFAULT 'PENDING',
  `total_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  `notes` TEXT NULL,
  `created_by` VARCHAR(36) NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_orders_customer` (`customer_id`),
  INDEX `idx_orders_date` (`order_date`),
  INDEX `idx_orders_status` (`status`),
  CONSTRAINT `fk_sales_orders_customer` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sales_dispatches` (
  `id` VARCHAR(36) NOT NULL,
  `dispatch_number` VARCHAR(50) NOT NULL UNIQUE,
  `order_id` VARCHAR(36) NULL,
  `customer_id` VARCHAR(36) NOT NULL,
  `record_date` DATE NOT NULL,
  `packaging_run_id` VARCHAR(36) NULL,
  `product_type` ENUM('MILK', 'PANEER', 'KHOYA', 'GHEE', 'DAHI', 'BUTTER', 'BIOGAS_FERTILISER') NOT NULL,
  `packs_sold` INT NOT NULL,
  `price_per_pack` DECIMAL(8,2) NOT NULL,
  `total_amount` DECIMAL(10,2) NOT NULL,
  `amount_received` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  `balance_due` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  `payment_method` ENUM('CASH', 'UPI', 'BANK_TRANSFER', 'CHEQUE', 'CREDIT') NOT NULL DEFAULT 'CASH',
  `notes` TEXT NULL,
  `created_by` VARCHAR(36) NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_dispatch_customer` (`customer_id`),
  INDEX `idx_dispatch_date` (`record_date`),
  CONSTRAINT `fk_dispatch_customer` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `customer_payments` (
  `id` VARCHAR(36) NOT NULL,
  `payment_number` VARCHAR(50) NOT NULL UNIQUE,
  `customer_id` VARCHAR(36) NOT NULL,
  `dispatch_id` VARCHAR(36) NULL,
  `record_date` DATE NOT NULL,
  `amount_received` DECIMAL(10,2) NOT NULL,
  `payment_method` ENUM('CASH', 'UPI', 'BANK_TRANSFER', 'CHEQUE') NOT NULL DEFAULT 'CASH',
  `reference_code` VARCHAR(100) NULL,
  `notes` TEXT NULL,
  `created_by` VARCHAR(36) NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_payment_customer` (`customer_id`),
  INDEX `idx_payment_date` (`record_date`),
  CONSTRAINT `fk_payment_customer` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 10. Inventory Receipts, Ledger & Wastage
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `stock_receipts` (
  `id` VARCHAR(36) NOT NULL,
  `receipt_number` VARCHAR(50) NOT NULL UNIQUE,
  `record_date` DATE NOT NULL,
  `stock_item_id` VARCHAR(36) NOT NULL,
  `quantity` DECIMAL(10,2) NOT NULL,
  `unit_price` DECIMAL(10,2) NOT NULL,
  `total_cost` DECIMAL(10,2) NOT NULL,
  `supplier_name` VARCHAR(120) NULL,
  `supplier_lot` VARCHAR(80) NULL,
  `expiry_date` DATE NULL,
  `notes` TEXT NULL,
  `created_by` VARCHAR(36) NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_receipt_item` (`stock_item_id`),
  INDEX `idx_receipt_date` (`record_date`),
  CONSTRAINT `fk_receipt_stock_item` FOREIGN KEY (`stock_item_id`) REFERENCES `stock_items` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `stock_ledger_entries` (
  `id` VARCHAR(36) NOT NULL,
  `stock_item_id` VARCHAR(36) NOT NULL,
  `record_date` DATE NOT NULL,
  `transaction_type` ENUM('RECEIPT', 'ISSUE', 'BATCH_CONSUMPTION', 'PACKAGING_CONSUMPTION', 'WASTAGE', 'ADJUSTMENT') NOT NULL,
  `reference_id` VARCHAR(50) NULL,
  `quantity_change` DECIMAL(10,2) NOT NULL,
  `balance_after` DECIMAL(10,2) NOT NULL,
  `unit_cost` DECIMAL(10,2) NOT NULL,
  `notes` TEXT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_ledger_item` (`stock_item_id`),
  INDEX `idx_ledger_date` (`record_date`),
  CONSTRAINT `fk_ledger_stock_item` FOREIGN KEY (`stock_item_id`) REFERENCES `stock_items` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `wastage_records` (
  `id` VARCHAR(36) NOT NULL,
  `record_date` DATE NOT NULL,
  `stock_type` ENUM('BMC', 'BULK_PRODUCT', 'PACKAGED_PRODUCT', 'SUPPLY') NOT NULL,
  `reference_id` VARCHAR(50) NOT NULL,
  `quantity_lost` DECIMAL(10,2) NOT NULL,
  `unit` VARCHAR(20) NOT NULL,
  `reason` ENUM('SPOILAGE', 'HANDLING', 'LEAKAGE', 'PROCESSING_LOSS', 'QUALITY_REJECTION', 'EXPIRY', 'OTHER') NOT NULL,
  `estimated_loss_cost` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  `notes` TEXT NULL,
  `created_by` VARCHAR(36) NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_wastage_date` (`record_date`),
  INDEX `idx_wastage_type` (`stock_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 11. Biogas, Operating Expenses, Employees, Licences
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `biogas_runs` (
  `id` VARCHAR(36) NOT NULL,
  `record_date` DATE NOT NULL,
  `slurry_input_kg` DECIMAL(10,2) NOT NULL,
  `dry_fertiliser_output_kg` DECIMAL(10,2) NOT NULL,
  `moisture_pct` DECIMAL(5,2) NULL,
  `bags_packed_1kg` INT NOT NULL DEFAULT 0,
  `bags_packed_5kg` INT NOT NULL DEFAULT 0,
  `bags_packed_25kg` INT NOT NULL DEFAULT 0,
  `bags_packed_50kg` INT NOT NULL DEFAULT 0,
  `notes` TEXT NULL,
  `created_by` VARCHAR(36) NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_biogas_date` (`record_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `operating_expenses` (
  `id` VARCHAR(36) NOT NULL,
  `record_date` DATE NOT NULL,
  `cost_centre` ENUM('FARM', 'PRODUCTION', 'BIOGAS') NOT NULL,
  `category` ENUM('ELECTRICITY', 'VET', 'TRANSPORT', 'MAINTENANCE', 'COLD_ROOM', 'CLEANING', 'LABOUR', 'OTHER') NOT NULL,
  `amount` DECIMAL(10,2) NOT NULL,
  `production_batch_id` VARCHAR(36) NULL,
  `payee` VARCHAR(120) NULL,
  `payment_method` ENUM('CASH', 'UPI', 'BANK_TRANSFER', 'CHEQUE') NOT NULL DEFAULT 'CASH',
  `notes` TEXT NULL,
  `created_by` VARCHAR(36) NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_expense_centre` (`cost_centre`),
  INDEX `idx_expense_date` (`record_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `employees` (
  `id` VARCHAR(36) NOT NULL,
  `employee_code` VARCHAR(20) NOT NULL UNIQUE,
  `full_name` VARCHAR(120) NOT NULL,
  `department` ENUM('FARM', 'PRODUCTION', 'BIOGAS', 'MANAGEMENT') NOT NULL,
  `job_title` VARCHAR(100) NOT NULL,
  `joining_date` DATE NOT NULL,
  `leaving_date` DATE NULL,
  `monthly_salary` DECIMAL(10,2) NOT NULL,
  `daily_salary_rate` DECIMAL(8,2) AS (`monthly_salary` / 30.00) STORED,
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
  `phone` VARCHAR(20) NULL,
  `email` VARCHAR(120) NULL,
  `notes` TEXT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_employee_dept` (`department`),
  INDEX `idx_employee_code` (`employee_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `regulatory_licences` (
  `id` VARCHAR(36) NOT NULL,
  `licence_name` VARCHAR(120) NOT NULL,
  `licence_number` VARCHAR(80) NOT NULL UNIQUE,
  `issuing_authority` VARCHAR(120) NOT NULL,
  `licence_holder` VARCHAR(120) NOT NULL,
  `issue_date` DATE NOT NULL,
  `expiry_date` DATE NOT NULL,
  `reminder_days_before` INT NOT NULL DEFAULT 30,
  `status` ENUM('ACTIVE', 'EXPIRING_SOON', 'EXPIRED') NOT NULL DEFAULT 'ACTIVE',
  `document_url` VARCHAR(255) NULL,
  `notes` TEXT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_licence_expiry` (`expiry_date`),
  INDEX `idx_licence_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;
