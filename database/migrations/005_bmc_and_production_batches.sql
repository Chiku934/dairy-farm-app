-- Migration 005: BMC Milk Intake, Production Batches, and Traceability
-- Implements Phase 8 requirements for BMC intake auditing, batch yield, and end-to-end lineage

-- 1. Enhance BMC Intake Logs with shift, operator, and rejection reason
ALTER TABLE `bmc_intake_logs`
  ADD COLUMN `shift` ENUM('AM', 'PM') NOT NULL DEFAULT 'AM' AFTER `record_date`,
  ADD COLUMN `rejection_reason` VARCHAR(255) NULL AFTER `decision`,
  ADD COLUMN `operator_id` VARCHAR(36) NULL AFTER `notes`,
  ADD COLUMN `operator_name` VARCHAR(100) NULL AFTER `operator_id`,
  ADD INDEX `idx_bmc_date_shift_source` (`record_date`, `shift`, `source`);

-- 2. Enhance Production Batches with shift, status, operator, and yield metrics
ALTER TABLE `production_batches`
  ADD COLUMN `shift` ENUM('AM', 'PM') NOT NULL DEFAULT 'AM' AFTER `record_date`,
  ADD COLUMN `status` ENUM('PLANNED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED') NOT NULL DEFAULT 'COMPLETED' AFTER `product_type`,
  ADD COLUMN `yield_percentage` DECIMAL(6,2) NULL AFTER `finished_quantity`,
  ADD COLUMN `lpg_stock_item_id` VARCHAR(36) NULL AFTER `lpg_used_kg`,
  ADD COLUMN `operator_id` VARCHAR(36) NULL AFTER `notes`,
  ADD COLUMN `operator_name` VARCHAR(100) NULL AFTER `operator_id`,
  ADD CONSTRAINT `fk_pb_lpg_stock` FOREIGN KEY (`lpg_stock_item_id`) REFERENCES `stock_items` (`id`) ON DELETE SET NULL,
  ADD INDEX `idx_pb_date_product` (`record_date`, `product_type`, `status`);

-- Backfill initial yield percentage for existing seeded batches
UPDATE `production_batches`
SET `yield_percentage` = ROUND((`finished_quantity` / `bmc_milk_consumed_l`) * 100, 2)
WHERE `bmc_milk_consumed_l` > 0 AND `yield_percentage` IS NULL;

-- 3. Create Production Batch to Intake Lots Traceability Junction Table
CREATE TABLE IF NOT EXISTS `production_batch_intakes` (
  `id` VARCHAR(36) NOT NULL PRIMARY KEY,
  `production_batch_id` VARCHAR(36) NOT NULL,
  `intake_id` VARCHAR(36) NOT NULL,
  `litres_used` DECIMAL(8,2) NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_pbi_batch` FOREIGN KEY (`production_batch_id`) REFERENCES `production_batches` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_pbi_intake` FOREIGN KEY (`intake_id`) REFERENCES `bmc_intake_logs` (`id`) ON DELETE RESTRICT,
  INDEX `idx_pbi_batch` (`production_batch_id`),
  INDEX `idx_pbi_intake` (`intake_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Seed sample linkage for existing batches pb-01 and pb-02 if available
INSERT IGNORE INTO `production_batch_intakes` (`id`, `production_batch_id`, `intake_id`, `litres_used`, `created_at`) VALUES
('pbi-01', 'pb-01', 'bmc-01', 50.00, NOW()),
('pbi-02', 'pb-02', 'bmc-02', 72.40, NOW()),
('pbi-03', 'pb-02', 'bmc-03', 47.60, NOW());
