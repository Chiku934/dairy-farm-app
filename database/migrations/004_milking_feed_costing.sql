-- ============================================================================
-- Dairy Farm Management System - Phase 7 Migration
-- Migration: 004_milking_feed_costing.sql
-- Modules: Milking Log, Feed & Ration Planning, and Unit Costing
-- ============================================================================

SET FOREIGN_KEY_CHECKS = 0;

-- 1. Enhance Milking Logs Table
ALTER TABLE `milking_logs`
  MODIFY COLUMN `animal_id` VARCHAR(36) NULL,
  ADD COLUMN IF NOT EXISTS `group_name` VARCHAR(100) NULL AFTER `animal_id`,
  ADD COLUMN IF NOT EXISTS `operator_id` VARCHAR(36) NULL AFTER `withheld_reason`,
  ADD COLUMN IF NOT EXISTS `operator_name` VARCHAR(100) NULL AFTER `operator_id`,
  ADD COLUMN IF NOT EXISTS `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;

-- Add Unique Constraint for Date/Shift duplicate protection and operator index
-- Drop index first if re-running
SET @drop_uq = (SELECT IF(
  EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.STATISTICS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='milking_logs' AND INDEX_NAME='uq_milking_animal_date_session'),
  'ALTER TABLE `milking_logs` DROP INDEX `uq_milking_animal_date_session`',
  'SELECT 1'
));
PREPARE stmt FROM @drop_uq;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

ALTER TABLE `milking_logs`
  ADD UNIQUE KEY `uq_milking_animal_date_session` (`animal_id`, `record_date`, `session`),
  ADD INDEX IF NOT EXISTS `idx_milking_operator` (`operator_id`),
  ADD INDEX IF NOT EXISTS `idx_milking_group` (`group_name`, `record_date`, `session`);

-- 2. Create Ration Definitions Table
CREATE TABLE IF NOT EXISTS `ration_definitions` (
  `id` VARCHAR(36) NOT NULL,
  `name` VARCHAR(120) NOT NULL,
  `code` VARCHAR(50) NOT NULL UNIQUE,
  `target_stage` ENUM('LACTATING', 'DRY', 'PREGNANT', 'HEIFER', 'CALF', 'BULL', 'ALL') NOT NULL DEFAULT 'LACTATING',
  `description` TEXT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_by` VARCHAR(36) NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_ration_stage` (`target_stage`),
  INDEX `idx_ration_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Create Ration Items Table
CREATE TABLE IF NOT EXISTS `ration_items` (
  `id` VARCHAR(36) NOT NULL,
  `ration_id` VARCHAR(36) NOT NULL,
  `stock_item_id` VARCHAR(36) NOT NULL,
  `quantity_kg` DECIMAL(8,2) NOT NULL,
  `notes` VARCHAR(255) NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ration_stock_item` (`ration_id`, `stock_item_id`),
  INDEX `idx_ration_items_ration` (`ration_id`),
  INDEX `idx_ration_items_stock` (`stock_item_id`),
  CONSTRAINT `fk_ration_items_ration` FOREIGN KEY (`ration_id`) REFERENCES `ration_definitions` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ration_items_stock` FOREIGN KEY (`stock_item_id`) REFERENCES `stock_items` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Enhance Feed Entries Table
ALTER TABLE `feed_entries`
  MODIFY COLUMN `animal_id` VARCHAR(36) NULL,
  ADD COLUMN IF NOT EXISTS `group_name` VARCHAR(100) NULL AFTER `animal_id`,
  ADD COLUMN IF NOT EXISTS `ration_id` VARCHAR(36) NULL AFTER `group_name`,
  ADD COLUMN IF NOT EXISTS `unit_cost` DECIMAL(10,2) NOT NULL DEFAULT 0.00 AFTER `quantity_kg`,
  ADD COLUMN IF NOT EXISTS `total_cost` DECIMAL(10,2) NOT NULL DEFAULT 0.00 AFTER `unit_cost`,
  ADD COLUMN IF NOT EXISTS `shift` ENUM('MORNING', 'EVENING', 'ALL_DAY') NOT NULL DEFAULT 'ALL_DAY' AFTER `total_cost`,
  ADD COLUMN IF NOT EXISTS `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;

ALTER TABLE `feed_entries`
  ADD INDEX IF NOT EXISTS `idx_feed_ration` (`ration_id`),
  ADD INDEX IF NOT EXISTS `idx_feed_group` (`group_name`, `record_date`);

SET FOREIGN_KEY_CHECKS = 1;
