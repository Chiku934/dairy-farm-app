-- ============================================================================
-- Migration 010: Enterprise Performance Optimizations and Justified Indexes
-- Description: Adds high-impact composite indexes identified through EXPLAIN
--              query plan analysis to eliminate full table scans, filesorts,
--              and unindexed subqueries across high-throughput tables.
-- ============================================================================

-- 1. Milking Logs: Composite index for disposition-filtered date ranges (Dashboard & Reports)
-- Justification: Eliminates full table scan (type: ALL) on milking_logs when filtering
--                by disposition = 'ELIGIBLE' AND record_date BETWEEN ? AND ?.
CREATE INDEX IF NOT EXISTS idx_milking_disposition_date 
  ON milking_logs (disposition, record_date);

-- Milking Logs: Composite index for individual animal milking history
-- Justification: Accelerates animal timeline lookup and ensures index order by date.
CREATE INDEX IF NOT EXISTS idx_milking_animal_date 
  ON milking_logs (animal_id, record_date);

-- 2. Health Records: Composite index for animal medical history ordered by date
-- Justification: Eliminates filesort ('Using filesort') when retrieving an animal's
--                health timeline ordered by record_date DESC.
CREATE INDEX IF NOT EXISTS idx_health_animal_date 
  ON health_records (animal_id, record_date);

-- Health Records: Composite index for active milk withdrawal safety checks
-- Justification: Enables index-only evaluation for correlated subquery
--                EXISTS (SELECT 1 FROM health_records hr WHERE hr.animal_id = a.id AND hr.withdrawal_until >= CURRENT_DATE).
CREATE INDEX IF NOT EXISTS idx_health_animal_withdrawal 
  ON health_records (animal_id, withdrawal_until);

-- 3. Breeding Records: Composite index for animal breeding timeline ordered by date
-- Justification: Eliminates filesort ('Using filesort') on breeding history timeline.
CREATE INDEX IF NOT EXISTS idx_breeding_animal_date 
  ON breeding_records (animal_id, record_date);

-- 4. Stock Items: Category index for inventory filtering and valuation reports
-- Justification: Eliminates full table scan (type: ALL) when filtering stock items by category.
CREATE INDEX IF NOT EXISTS idx_stock_category 
  ON stock_items (category);

-- Stock Items: Reorder level composite index for low inventory alert scans
-- Justification: Optimizes dashboard alert scan WHERE current_stock <= reorder_level.
CREATE INDEX IF NOT EXISTS idx_stock_reorder 
  ON stock_items (current_stock, reorder_level);

-- 5. Animals: Composite index for active herd directory ordered by creation date
-- Justification: Eliminates full table scan and filesort on primary herd listing
--                WHERE is_archived = false ORDER BY created_at DESC.
CREATE INDEX IF NOT EXISTS idx_animals_archived_created 
  ON animals (is_archived, created_at);

-- 6. Sales Dispatches: Composite index for date-ranged dispatches joined with customer
-- Justification: Accelerates sales report queries joining customer on customer_id within date ranges.
CREATE INDEX IF NOT EXISTS idx_sales_date_customer 
  ON sales_dispatches (record_date, customer_id);

-- 7. Customer Payments: Composite index for customer payment reconciliations
-- Justification: Speeds up customer ledger lookups by date range.
CREATE INDEX IF NOT EXISTS idx_payment_date_customer 
  ON customer_payments (record_date, customer_id);
