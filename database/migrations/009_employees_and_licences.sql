-- ============================================================================
-- Dairy Farm Management System - Migration 009
-- Phase 12: Employees and FSSAI & Licences
-- ============================================================================

-- 1. Enhance employees table with employment status
ALTER TABLE `employees`
  ADD COLUMN `status` ENUM('ACTIVE', 'ON_LEAVE', 'TERMINATED', 'RESIGNED') NOT NULL DEFAULT 'ACTIVE' AFTER `is_active`,
  ADD INDEX `idx_employee_status` (`status`);

-- 2. Enhance regulatory_licences table with licence_type, reminder_status and reminder_sent_at
ALTER TABLE `regulatory_licences`
  ADD COLUMN `licence_type` ENUM('FSSAI', 'POLLUTION_CONTROL', 'TRADE_LICENSE', 'FIRE_SAFETY', 'GROUNDWATER', 'DAIRY_REGISTRATION', 'OTHER') NOT NULL DEFAULT 'OTHER' AFTER `licence_name`,
  MODIFY COLUMN `status` ENUM('ACTIVE', 'EXPIRING_SOON', 'EXPIRED', 'SUSPENDED') NOT NULL DEFAULT 'ACTIVE',
  ADD COLUMN `reminder_status` ENUM('PENDING', 'NOTIFIED', 'DISMISSED') NOT NULL DEFAULT 'PENDING' AFTER `status`,
  ADD COLUMN `reminder_sent_at` DATETIME NULL AFTER `reminder_status`,
  ADD INDEX `idx_licence_type` (`licence_type`),
  ADD INDEX `idx_licence_reminder_status` (`reminder_status`);
