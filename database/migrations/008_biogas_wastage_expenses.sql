-- ============================================================================
-- Dairy Farm Management System - Migration 008
-- Phase 11: Biogas Fertiliser, Wastage & Losses and Costs & Expenses
-- ============================================================================

-- 1. Enhance biogas_runs with run_number, stock_item_id, and usage/sales tracking
ALTER TABLE `biogas_runs`
  ADD COLUMN `run_number` VARCHAR(50) NULL AFTER `id`,
  ADD COLUMN `stock_item_id` VARCHAR(36) NULL AFTER `moisture_pct`,
  ADD COLUMN `usage_type` ENUM('STORE_STOCK', 'FARM_INTERNAL', 'DIRECT_SALE') NOT NULL DEFAULT 'STORE_STOCK' AFTER `bags_packed_50kg`,
  ADD COLUMN `usage_quantity_kg` DECIMAL(10,2) NOT NULL DEFAULT 0.00 AFTER `usage_type`,
  ADD COLUMN `sale_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00 AFTER `usage_quantity_kg`,
  ADD COLUMN `buyer_or_farm_plot` VARCHAR(120) NULL AFTER `sale_amount`,
  ADD UNIQUE KEY `uk_biogas_run_number` (`run_number`),
  ADD INDEX `idx_biogas_stock_item` (`stock_item_id`),
  ADD CONSTRAINT `fk_biogas_stock_item` FOREIGN KEY (`stock_item_id`) REFERENCES `stock_items` (`id`) ON DELETE SET NULL;

-- 2. Enhance wastage_records with wastage_number, stock_item_id, and batch tracking
ALTER TABLE `wastage_records`
  ADD COLUMN `wastage_number` VARCHAR(50) NULL AFTER `id`,
  ADD COLUMN `stock_item_id` VARCHAR(36) NULL AFTER `stock_type`,
  ADD COLUMN `production_batch_id` VARCHAR(36) NULL AFTER `stock_item_id`,
  ADD UNIQUE KEY `uk_wastage_number` (`wastage_number`),
  ADD INDEX `idx_wastage_stock_item` (`stock_item_id`),
  ADD INDEX `idx_wastage_batch` (`production_batch_id`),
  ADD CONSTRAINT `fk_wastage_stock_item` FOREIGN KEY (`stock_item_id`) REFERENCES `stock_items` (`id`) ON DELETE SET NULL;

-- 3. Enhance operating_expenses with expense_number, invoice_number, and extended categories
ALTER TABLE `operating_expenses`
  ADD COLUMN `expense_number` VARCHAR(50) NULL AFTER `id`,
  ADD COLUMN `invoice_number` VARCHAR(80) NULL AFTER `payee`,
  MODIFY COLUMN `category` ENUM('ELECTRICITY', 'VET', 'TRANSPORT', 'MAINTENANCE', 'COLD_ROOM', 'CLEANING', 'LABOUR', 'FEED_SUPPLEMENT', 'FUEL', 'OTHER') NOT NULL,
  ADD UNIQUE KEY `uk_expense_number` (`expense_number`),
  ADD INDEX `idx_expense_invoice` (`invoice_number`),
  ADD INDEX `idx_expense_centre_date` (`cost_centre`, `record_date`);
