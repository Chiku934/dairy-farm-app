-- ============================================================================
-- Dairy Farm Management System - Herd, Health & Breeding Enhancements
-- Migration: 003_herd_health_breeding_enhancements.sql
-- ============================================================================

-- 1. Enhance animals table for archive workflows and lineage indexing
ALTER TABLE `animals`
  ADD COLUMN `is_archived` BOOLEAN NOT NULL DEFAULT FALSE AFTER `notes`,
  ADD COLUMN `archived_at` DATETIME NULL AFTER `is_archived`,
  ADD COLUMN `archive_reason` VARCHAR(255) NULL AFTER `archived_at`,
  ADD INDEX `idx_animals_archived_status` (`is_archived`, `status`),
  ADD INDEX `idx_animals_dam_tag` (`dam_tag`);

-- 2. Enhance health_records table to distinguish veterinary diagnosis from treatment, track creator and audit timestamps
ALTER TABLE `health_records`
  ADD COLUMN `diagnosis` VARCHAR(150) NULL AFTER `care_type`,
  ADD COLUMN `created_by` VARCHAR(36) NULL AFTER `notes`,
  ADD COLUMN `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP AFTER `created_at`,
  ADD INDEX `idx_health_care_type` (`care_type`),
  ADD INDEX `idx_health_next_due` (`next_due_date`),
  ADD INDEX `idx_health_record_date` (`record_date`);

-- 3. Enhance breeding_records table for pregnancy check reminders and audit timestamps
ALTER TABLE `breeding_records`
  ADD COLUMN `next_check_date` DATE NULL AFTER `expected_calving_date`,
  ADD COLUMN `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP AFTER `created_at`,
  ADD INDEX `idx_breeding_event_type` (`event_type`),
  ADD INDEX `idx_breeding_next_check` (`next_check_date`);
