-- ============================================================================
-- Dairy Farm Management System - Migration 007
-- Phase 10: Common Inventory, Orders & Dispatch, Sales and Customer Payments
-- ============================================================================

-- 1. Suppliers Table
CREATE TABLE IF NOT EXISTS `suppliers` (
  `id` VARCHAR(36) NOT NULL,
  `name` VARCHAR(120) NOT NULL UNIQUE,
  `contact_person` VARCHAR(100) NULL,
  `phone` VARCHAR(20) NULL,
  `email` VARCHAR(120) NULL,
  `address` VARCHAR(255) NULL,
  `category` ENUM('FEED', 'MEDICINE', 'PACKAGING', 'LPG', 'CLEANING', 'PROCESSING_INGREDIENT', 'EQUIPMENT', 'GENERAL') NOT NULL DEFAULT 'GENERAL',
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_supplier_name` (`name`),
  INDEX `idx_supplier_cat` (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Enhance stock_receipts with supplier_id link
ALTER TABLE `stock_receipts`
  ADD COLUMN `supplier_id` VARCHAR(36) NULL AFTER `supplier_name`,
  ADD INDEX `idx_receipt_supplier_id` (`supplier_id`);

-- 3. Enhance sales_orders status to include PARTIALLY_FULFILLED
ALTER TABLE `sales_orders`
  MODIFY COLUMN `status` ENUM('PENDING', 'PARTIALLY_FULFILLED', 'FULFILLED', 'CANCELLED') NOT NULL DEFAULT 'PENDING';

-- 4. Sales Order Items Table (sales order lines)
CREATE TABLE IF NOT EXISTS `sales_order_items` (
  `id` VARCHAR(36) NOT NULL,
  `order_id` VARCHAR(36) NOT NULL,
  `product_type` ENUM('MILK', 'PANEER', 'KHOYA', 'GHEE', 'DAHI', 'BUTTER', 'BIOGAS_FERTILISER') NOT NULL,
  `pack_size` DECIMAL(6,2) NOT NULL DEFAULT 1.00,
  `pack_unit` VARCHAR(20) NOT NULL DEFAULT 'LITRE',
  `quantity_ordered` INT NOT NULL,
  `quantity_dispatched` INT NOT NULL DEFAULT 0,
  `unit_price` DECIMAL(10,2) NOT NULL,
  `total_price` DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (`id`),
  INDEX `idx_order_item_order` (`order_id`),
  CONSTRAINT `fk_order_items_order` FOREIGN KEY (`order_id`) REFERENCES `sales_orders` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. Sales Dispatch Items Table (sales dispatch lines)
CREATE TABLE IF NOT EXISTS `sales_dispatch_items` (
  `id` VARCHAR(36) NOT NULL,
  `dispatch_id` VARCHAR(36) NOT NULL,
  `order_item_id` VARCHAR(36) NULL,
  `packaging_run_id` VARCHAR(36) NULL,
  `product_type` ENUM('MILK', 'PANEER', 'KHOYA', 'GHEE', 'DAHI', 'BUTTER', 'BIOGAS_FERTILISER') NOT NULL,
  `pack_size` DECIMAL(6,2) NOT NULL DEFAULT 1.00,
  `pack_unit` VARCHAR(20) NOT NULL DEFAULT 'LITRE',
  `quantity` INT NOT NULL,
  `unit_price` DECIMAL(10,2) NOT NULL,
  `total_price` DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (`id`),
  INDEX `idx_dispatch_item_dispatch` (`dispatch_id`),
  CONSTRAINT `fk_dispatch_items_dispatch` FOREIGN KEY (`dispatch_id`) REFERENCES `sales_dispatches` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. Extend stock_ledger_entries transaction_type to include SALES_DISPATCH
ALTER TABLE `stock_ledger_entries`
  MODIFY COLUMN `transaction_type` ENUM('RECEIPT', 'ISSUE', 'BATCH_CONSUMPTION', 'PACKAGING_CONSUMPTION', 'SALES_DISPATCH', 'WASTAGE', 'ADJUSTMENT') NOT NULL;

-- 7. Seed Initial Suppliers and Customers for dev/demo if not present
INSERT IGNORE INTO `suppliers` (`id`, `name`, `contact_person`, `phone`, `email`, `category`) VALUES
('sup-01', 'Odisha Agro Feeds Ltd', 'Bikram Sahu', '+91 9437012345', 'agro@odishafeeds.in', 'FEED'),
('sup-02', 'Nilachal Packaging Solutions', 'Sunita Jena', '+91 9437023456', 'sales@nilachalpack.com', 'PACKAGING'),
('sup-03', 'Hindustan Petroleum LPG Dist.', 'Manoj Das', '+91 9437034567', 'hp_koraput@hpcl.co.in', 'LPG'),
('sup-04', 'VetMed Pharmaceuticals', 'Dr. Panda', '+91 9437045678', 'orders@vetmedodisha.com', 'MEDICINE');

INSERT IGNORE INTO `customers` (`id`, `name`, `phone`, `email`, `address`, `customer_type`, `credit_limit`, `current_balance`) VALUES
('cust-01', 'Annapurna Sweet Stall', '+91 9861011111', 'annapurna@koraput.in', 'Main Market, Koraput', 'WHOLESALE', 25000.00, 0.00),
('cust-02', 'Tribal Dairy Retail Outlet', '+91 9861022222', 'retail@tribaldairy.org', 'NH-26 Junction, Jeypore', 'RETAIL', 5000.00, 0.00),
('cust-03', 'Hotel Green Valley', '+91 9861033333', 'purchase@greenvalley.com', 'Hill View Road, Koraput', 'WHOLESALE', 40000.00, 0.00);
