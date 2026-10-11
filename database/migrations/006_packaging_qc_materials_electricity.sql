-- ============================================================================
-- Migration 006: Packaging, Quality Records, Material Issues & Electricity Readings
-- ============================================================================

-- 1. Enhance electricity_readings with opening and closing meter counters
ALTER TABLE `electricity_readings`
  ADD COLUMN `opening_reading_kwh` DECIMAL(10,2) NULL AFTER `department`,
  ADD COLUMN `closing_reading_kwh` DECIMAL(10,2) NULL AFTER `opening_reading_kwh`;

-- 2. Enhance packaging_runs with total packaged quantity, scrap units, and flexible pack units
ALTER TABLE `packaging_runs`
  MODIFY COLUMN `pack_unit` VARCHAR(20) NOT NULL DEFAULT 'LITRE',
  ADD COLUMN `total_packaged_quantity` DECIMAL(8,2) NOT NULL DEFAULT 0.00 AFTER `number_of_packs`,
  ADD COLUMN `scrap_units` INT NOT NULL DEFAULT 0 AFTER `material_consumed`;

-- 3. Enhance material_issues with unit cost and total cost for direct cost accounting
ALTER TABLE `material_issues`
  ADD COLUMN `unit_cost` DECIMAL(10,2) NULL AFTER `quantity`,
  ADD COLUMN `total_cost` DECIMAL(10,2) NULL AFTER `unit_cost`;
