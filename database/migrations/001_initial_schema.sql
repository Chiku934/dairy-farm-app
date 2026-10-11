-- ============================================================================
-- Dairy Farm Management System - Initial Relational Schema
-- Migration: 001_initial_schema.sql
-- Engine: InnoDB | Character Set: utf8mb4 | Collation: utf8mb4_unicode_ci
-- Enforces strict DECIMAL for all currency amounts and measured quantities.
-- ============================================================================

SET FOREIGN_KEY_CHECKS = 0;

-- 1. Identity & RBAC
CREATE TABLE IF NOT EXISTS `users` (
  `id` VARCHAR(36) NOT NULL,
  `email` VARCHAR(120) NOT NULL UNIQUE,
  `password_hash` VARCHAR(255) NOT NULL,
  `full_name` VARCHAR(100) NOT NULL,
  `phone` VARCHAR(20) NULL,
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `roles` (
  `id` VARCHAR(36) NOT NULL,
  `code` VARCHAR(50) NOT NULL UNIQUE,
  `name` VARCHAR(100) NOT NULL,
  `description` TEXT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `user_roles` (
  `user_id` VARCHAR(36) NOT NULL,
  `role_id` VARCHAR(36) NOT NULL,
  PRIMARY KEY (`user_id`, `role_id`),
  CONSTRAINT `fk_user_roles_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_user_roles_role` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Domain A: Your Dairy
CREATE TABLE IF NOT EXISTS `animals` (
  `id` VARCHAR(36) NOT NULL,
  `ear_tag` VARCHAR(50) NOT NULL UNIQUE,
  `name` VARCHAR(100) NULL,
  `breed` VARCHAR(50) NOT NULL,
  `sex` ENUM('FEMALE', 'MALE') NOT NULL DEFAULT 'FEMALE',
  `date_of_birth` DATE NULL,
  `status` ENUM('LACTATING', 'DRY', 'PREGNANT', 'HEIFER', 'CALF', 'BULL', 'SOLD', 'DECEASED') NOT NULL DEFAULT 'LACTATING',
  `body_weight_kg` DECIMAL(6,2) NULL,
  `dam_tag` VARCHAR(50) NULL,
  `last_calving_date` DATE NULL,
  `body_condition_score` DECIMAL(3,1) NULL,
  `notes` TEXT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_animals_status` (`status`),
  INDEX `idx_animals_ear_tag` (`ear_tag`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `milking_logs` (
  `id` VARCHAR(36) NOT NULL,
  `animal_id` VARCHAR(36) NOT NULL,
  `record_date` DATE NOT NULL,
  `session` ENUM('MORNING', 'EVENING') NOT NULL,
  `yield_litres` DECIMAL(6,2) NOT NULL,
  `disposition` ENUM('ELIGIBLE', 'WITHHELD', 'CALF_FEEDING') NOT NULL DEFAULT 'ELIGIBLE',
  `withheld_reason` VARCHAR(255) NULL,
  `notes` TEXT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_milking_date` (`record_date`),
  CONSTRAINT `fk_milking_animal` FOREIGN KEY (`animal_id`) REFERENCES `animals` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `health_records` (
  `id` VARCHAR(36) NOT NULL,
  `animal_id` VARCHAR(36) NOT NULL,
  `record_date` DATE NOT NULL,
  `care_type` ENUM('TREATMENT', 'VACCINATION', 'DEWORMING', 'EXAMINATION') NOT NULL,
  `medicine_vaccine` VARCHAR(120) NOT NULL,
  `prescribed_dose` VARCHAR(100) NOT NULL,
  `veterinarian` VARCHAR(100) NULL,
  `next_due_date` DATE NULL,
  `withdrawal_until` DATE NULL,
  `notes` TEXT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_health_withdrawal` (`withdrawal_until`),
  CONSTRAINT `fk_health_animal` FOREIGN KEY (`animal_id`) REFERENCES `animals` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Inventory & Master Stock
CREATE TABLE IF NOT EXISTS `stock_items` (
  `id` VARCHAR(36) NOT NULL,
  `name` VARCHAR(120) NOT NULL UNIQUE,
  `used_by` ENUM('FARM', 'PRODUCTION', 'BIOGAS', 'BOTH') NOT NULL,
  `category` ENUM('FEED', 'MEDICINE', 'PACKAGING', 'LPG', 'CLEANING', 'PROCESSING_INGREDIENT', 'CONSUMABLE', 'SPARE_PART', 'OTHER') NOT NULL,
  `unit` VARCHAR(20) NOT NULL,
  `current_stock` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  `weighted_avg_price` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  `reorder_level` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  `notes` TEXT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Domain B: Milk to Market
CREATE TABLE IF NOT EXISTS `bmc_intake_logs` (
  `id` VARCHAR(36) NOT NULL,
  `batch_number` VARCHAR(50) NOT NULL UNIQUE,
  `record_date` DATE NOT NULL,
  `source` ENUM('FARM', 'EXTERNAL') NOT NULL,
  `supplier_route` VARCHAR(120) NULL,
  `quantity_litres` DECIMAL(8,2) NOT NULL,
  `external_total_cost` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  `decision` ENUM('ACCEPTED', 'REJECTED') NOT NULL,
  `temperature_c` DECIMAL(4,1) NULL,
  `fat_percentage` DECIMAL(4,2) NULL,
  `snf_percentage` DECIMAL(4,2) NULL,
  `clr` DECIMAL(5,2) NULL,
  `ph` DECIMAL(3,2) NULL,
  `notes` TEXT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_bmc_date` (`record_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `production_batches` (
  `id` VARCHAR(36) NOT NULL,
  `batch_number` VARCHAR(50) NOT NULL UNIQUE,
  `record_date` DATE NOT NULL,
  `product_type` ENUM('MILK', 'PANEER', 'KHOYA', 'GHEE', 'DAHI', 'BUTTER', 'BIOGAS_FERTILISER') NOT NULL,
  `bmc_milk_consumed_l` DECIMAL(8,2) NOT NULL,
  `finished_quantity` DECIMAL(8,2) NOT NULL,
  `unit_of_measure` ENUM('LITRE', 'KG') NOT NULL,
  `lpg_used_kg` DECIMAL(6,2) NOT NULL DEFAULT 0.00,
  `byproduct_quantity_kg` DECIMAL(8,2) NOT NULL DEFAULT 0.00,
  `expiry_date` DATE NOT NULL,
  `quality_release` ENUM('HOLD', 'APPROVED', 'REJECTED') NOT NULL DEFAULT 'HOLD',
  `notes` TEXT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. Business Settings
CREATE TABLE IF NOT EXISTS `farm_settings` (
  `id` INT NOT NULL DEFAULT 1,
  `bmc_capacity_litres` DECIMAL(8,2) NOT NULL DEFAULT 2000.00,
  `feed_base_kg` DECIMAL(4,2) NOT NULL DEFAULT 1.00,
  `feed_rate_per_litre` DECIMAL(4,2) NOT NULL DEFAULT 0.40,
  `feed_max_cap_kg` DECIMAL(4,2) NOT NULL DEFAULT 8.00,
  `electricity_tariff` DECIMAL(6,2) NOT NULL DEFAULT 1.40,
  `farm_default_kwh` DECIMAL(6,2) NOT NULL DEFAULT 50.00,
  `production_default_kwh` DECIMAL(6,2) NOT NULL DEFAULT 200.00,
  `mgmt_salary_to_farm_pct` DECIMAL(5,2) NOT NULL DEFAULT 50.00,
  `operator_name` VARCHAR(100) NOT NULL DEFAULT 'Kaivalya team',
  `timezone` VARCHAR(50) NOT NULL DEFAULT 'Asia/Kolkata',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;
