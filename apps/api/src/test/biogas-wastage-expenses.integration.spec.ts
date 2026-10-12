import { Test, TestingModule } from '@nestjs/testing';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { v4 as uuidv4 } from 'uuid';
import { ConflictException, BadRequestException } from '@nestjs/common';
import {
  StockType,
  WastageReason,
  CostCentre,
  ExpenseCategory,
  PaymentMethod,
  BiogasUsageType,
  StockTransactionType,
} from '@dairy-farm/api-contracts';

import { BiogasModule } from '../modules/biogas/biogas.module';
import { BiogasService } from '../modules/biogas/biogas.service';
import { BiogasRunEntity } from '../modules/biogas/entities/biogas-run.entity';

import { WastageModule } from '../modules/wastage/wastage.module';
import { WastageService } from '../modules/wastage/wastage.service';
import { WastageRecordEntity } from '../modules/wastage/entities/wastage-record.entity';

import { ExpensesModule } from '../modules/expenses/expenses.module';
import { ExpensesService } from '../modules/expenses/expenses.service';
import { OperatingExpenseEntity } from '../modules/expenses/entities/operating-expense.entity';

import { StockItemEntity } from '../modules/feed/entities/stock-item.entity';
import { StockLedgerEntryEntity } from '../modules/inventory/entities/stock-ledger-entry.entity';
import { AuditModule } from '../modules/audit/audit.module';
import { AuditLogEntity } from '../modules/audit/entities/audit-log.entity';

import { ConfigModule } from '@nestjs/config';
import { getDatabaseConfig } from '../modules/database/database.config';

describe('Phase 11: Biogas Fertiliser, Wastage & Losses and Costs & Expenses Integration Tests', () => {
  let module: TestingModule;
  let dataSource: DataSource;
  let biogasService: BiogasService;
  let wastageService: WastageService;
  let expensesService: ExpensesService;

  const testUserId = 'usr-dev-admin';

  beforeAll(async () => {
    module = await Test.createTestingModule({
      imports: [
        ConfigModule.forRoot({ isGlobal: true }),
        TypeOrmModule.forRootAsync({
          useFactory: () => getDatabaseConfig(),
        }),
        BiogasModule,
        WastageModule,
        ExpensesModule,
        AuditModule,
      ],
    }).compile();

    dataSource = module.get<DataSource>(DataSource);
    biogasService = module.get<BiogasService>(BiogasService);
    wastageService = module.get<WastageService>(WastageService);
    expensesService = module.get<ExpensesService>(ExpensesService);
  });

  afterAll(async () => {
    if (dataSource && dataSource.isInitialized) {
      await dataSource.destroy();
    }
  });

  // --------------------------------------------------------------------------
  // 1. Biogas Fertiliser Production, Bags & Inventory Ledger Integration
  // --------------------------------------------------------------------------
  describe('1. Biogas Fertiliser Production, Bags & Inventory Ledger', () => {
    const testFertiliserItemId = `item-bio-fert-${Date.now()}`;
    const runNum1 = `BIO-TEST-${Date.now().toString().slice(-5)}-1`;

    beforeAll(async () => {
      // Seed dedicated bio-fertiliser stock item
      await dataSource.query(
        `INSERT INTO stock_items (id, name, used_by, category, unit, current_stock, weighted_avg_price, reorder_level)
         VALUES (?, ?, 'BIOGAS', 'OTHER', 'KG', 50.00, 15.00, 20.00)`,
        [testFertiliserItemId, `Test Dry Bio-Manure ${Date.now()}`],
      );
    });

    afterAll(async () => {
      await dataSource.query(`DELETE FROM stock_ledger_entries WHERE stock_item_id = ?`, [testFertiliserItemId]);
      await dataSource.query(`DELETE FROM biogas_runs WHERE id NOT IN ('bio-01', 'bio-02')`);
      await dataSource.query(`DELETE FROM stock_items WHERE id = ?`, [testFertiliserItemId]);
    });

    it('records biogas production run, computes yield, and credits stock item ledger', async () => {
      // 1000kg slurry in, 200kg dry fertiliser out
      // Bags: 10 x 1kg = 10kg, 10 x 5kg = 50kg, 4 x 25kg = 100kg -> Total bag weight = 160kg <= 200kg (valid)
      const run = await biogasService.createRun(
        {
          runNumber: runNum1,
          recordDate: '2026-10-12',
          slurryInputKg: 1000.0,
          dryFertiliserOutputKg: 200.0,
          moisturePct: 18.5,
          stockItemId: testFertiliserItemId,
          bagsPacked1kg: 10,
          bagsPacked5kg: 10,
          bagsPacked25kg: 4,
          bagsPacked50kg: 0,
          usageType: BiogasUsageType.STORE_STOCK,
          notes: 'Standard batch digestion run',
        },
        testUserId,
      );

      expect(run).toBeDefined();
      expect(run.run_number).toBe(runNum1);
      expect(Number(run.dry_fertiliser_output_kg)).toBe(200.0);

      // Verify stock_items was credited: 50.0 + 200.0 = 250.0 KG
      const updatedItem = await dataSource.getRepository(StockItemEntity).findOneBy({ id: testFertiliserItemId });
      expect(Number(updatedItem?.current_stock)).toBe(250.0);

      // Verify stock ledger entry was generated
      const ledgerEntry = await dataSource.getRepository(StockLedgerEntryEntity).findOneBy({
        stockItemId: testFertiliserItemId,
        referenceId: runNum1,
      });
      expect(ledgerEntry).toBeDefined();
      expect(ledgerEntry?.transactionType).toBe(StockTransactionType.RECEIPT);
      expect(Number(ledgerEntry?.quantityChange)).toBe(200.0);
      expect(Number(ledgerEntry?.balanceAfter)).toBe(250.0);

      // Verify audit log
      const audit = await dataSource.getRepository(AuditLogEntity).findOneBy({
        entityId: run.id,
        action: 'BIOGAS_RUN_CREATED',
      });
      expect(audit).toBeDefined();
    });

    it('rejects biogas run when total bag weight exceeds dry fertiliser output', async () => {
      // dry output: 50kg, but bags: 2 x 50kg = 100kg > 50kg -> must fail
      await expect(
        biogasService.createRun(
          {
            recordDate: '2026-10-12',
            slurryInputKg: 500.0,
            dryFertiliserOutputKg: 50.0,
            bagsPacked50kg: 2,
            usageType: BiogasUsageType.STORE_STOCK,
          },
          testUserId,
        ),
      ).rejects.toThrow(BadRequestException);
    });

    it('prevents duplicate biogas run submission with same run_number', async () => {
      await expect(
        biogasService.createRun(
          {
            runNumber: runNum1,
            recordDate: '2026-10-12',
            slurryInputKg: 500.0,
            dryFertiliserOutputKg: 100.0,
          },
          testUserId,
        ),
      ).rejects.toThrow(ConflictException);
    });
  });

  // --------------------------------------------------------------------------
  // 2. Wastage & Losses, Stock Ledger Decrement and Rollback Integrity
  // --------------------------------------------------------------------------
  describe('2. Wastage & Losses and Shared Stock Ledger Integration', () => {
    const testItemId = `item-wst-test-${Date.now()}`;
    const wstNum1 = `WST-TEST-${Date.now().toString().slice(-5)}-1`;

    beforeAll(async () => {
      // Seed item with 80 units @ ₹40.00
      await dataSource.query(
        `INSERT INTO stock_items (id, name, used_by, category, unit, current_stock, weighted_avg_price, reorder_level)
         VALUES (?, ?, 'PRODUCTION', 'PACKAGING', 'PCS', 80.00, 40.00, 20.00)`,
        [testItemId, `Test Packaging Boxes ${Date.now()}`],
      );
    });

    afterAll(async () => {
      await dataSource.query(`DELETE FROM stock_ledger_entries WHERE stock_item_id = ?`, [testItemId]);
      await dataSource.query(`DELETE FROM wastage_records WHERE id != 'wst-01'`);
      await dataSource.query(`DELETE FROM stock_items WHERE id = ?`, [testItemId]);
    });

    it('records SUPPLY wastage, writes off stock, computes loss cost, and records in stock ledger', async () => {
      // 80 on hand. Write off 15 units due to handling damage.
      // Expected new stock: 80 - 15 = 65
      // Expected estimated loss cost: 15 * 40.00 = ₹600.00
      const wastage = await wastageService.recordWastage(
        {
          wastageNumber: wstNum1,
          recordDate: '2026-10-12',
          stockType: StockType.SUPPLY,
          stockItemId: testItemId,
          referenceId: 'LOT-DAMAGED-01',
          quantityLost: 15.0,
          unit: 'PCS',
          reason: WastageReason.HANDLING,
          notes: 'Crushed during warehouse reorganizing',
        },
        testUserId,
      );

      expect(wastage).toBeDefined();
      expect(wastage.wastage_number).toBe(wstNum1);
      expect(Number(wastage.estimated_loss_cost)).toBe(600.0);

      // Verify stock was decremented
      const item = await dataSource.getRepository(StockItemEntity).findOneBy({ id: testItemId });
      expect(Number(item?.current_stock)).toBe(65.0);

      // Verify stock ledger entry was recorded
      const entry = await dataSource.getRepository(StockLedgerEntryEntity).findOneBy({
        stockItemId: testItemId,
        referenceId: wstNum1,
      });
      expect(entry).toBeDefined();
      expect(entry?.transactionType).toBe(StockTransactionType.WASTAGE);
      expect(Number(entry?.quantityChange)).toBe(-15.0);
      expect(Number(entry?.balanceAfter)).toBe(65.0);
    });

    it('rejects wastage when quantity lost exceeds current on-hand stock and leaves stock unchanged', async () => {
      // Current stock is 65. Attempting to waste 100 units must fail with INSUFFICIENT_STOCK
      await expect(
        wastageService.recordWastage(
          {
            recordDate: '2026-10-12',
            stockType: StockType.SUPPLY,
            stockItemId: testItemId,
            referenceId: 'LOT-DAMAGED-OVER',
            quantityLost: 100.0,
            unit: 'PCS',
            reason: WastageReason.SPOILAGE,
          },
          testUserId,
        ),
      ).rejects.toThrow(BadRequestException);

      // Verify balance was rolled back and remains precisely 65.0
      const item = await dataSource.getRepository(StockItemEntity).findOneBy({ id: testItemId });
      expect(Number(item?.current_stock)).toBe(65.0);
    });

    it('records BMC milk wastage with standard rate calculation', async () => {
      const bmcWst = await wastageService.recordWastage(
        {
          recordDate: '2026-10-12',
          stockType: StockType.BMC,
          referenceId: 'BMC-SILO-01',
          quantityLost: 50.0,
          unit: 'LITRE',
          reason: WastageReason.SPOILAGE,
          notes: 'Power failure cooling loss',
        },
        testUserId,
      );

      // Standard rate 50 * 32.00 = 1600.00
      expect(Number(bmcWst.estimated_loss_cost)).toBe(1600.0);
    });

    it('prevents duplicate wastage record submission with identical wastage_number', async () => {
      await expect(
        wastageService.recordWastage(
          {
            wastageNumber: wstNum1,
            recordDate: '2026-10-12',
            stockType: StockType.SUPPLY,
            stockItemId: testItemId,
            referenceId: 'LOT-DAMAGED-DUP',
            quantityLost: 5.0,
            unit: 'PCS',
            reason: WastageReason.EXPIRY,
          },
          testUserId,
        ),
      ).rejects.toThrow(ConflictException);
    });
  });

  // --------------------------------------------------------------------------
  // 3. Costs & Expenses, Cost Centre Aggregation and Duplicate Guards
  // --------------------------------------------------------------------------
  describe('3. Operating Expenses & Cost Centre Accounting', () => {
    const expNum1 = `EXP-TEST-${Date.now().toString().slice(-5)}-1`;
    const invNum1 = `INV-VENDOR-${Date.now().toString().slice(-5)}-1`;

    afterAll(async () => {
      await dataSource.query(`DELETE FROM operating_expenses WHERE id NOT IN ('exp-01', 'exp-02', 'exp-03')`);
    });

    it('records operating expense and tracks payee and payment method', async () => {
      const expense = await expensesService.createExpense(
        {
          expenseNumber: expNum1,
          recordDate: '2026-10-12',
          costCentre: CostCentre.PRODUCTION,
          category: ExpenseCategory.CLEANING,
          amount: 1450.5,
          payee: 'CleanTech Chemical Supplies',
          invoiceNumber: invNum1,
          paymentMethod: PaymentMethod.UPI,
          notes: 'Monthly bulk CIP cleaning detergent',
        },
        testUserId,
      );

      expect(expense).toBeDefined();
      expect(expense.expense_number).toBe(expNum1);
      expect(Number(expense.amount)).toBe(1450.5);
      expect(expense.payee).toBe('CleanTech Chemical Supplies');

      // Verify audit log
      const audit = await dataSource.getRepository(AuditLogEntity).findOneBy({
        entityId: expense.id,
        action: 'EXPENSE_RECORDED',
      });
      expect(audit).toBeDefined();
    });

    it('rejects non-positive expense amounts', async () => {
      await expect(
        expensesService.createExpense(
          {
            recordDate: '2026-10-12',
            costCentre: CostCentre.FARM,
            category: ExpenseCategory.VET,
            amount: 0.0,
          },
          testUserId,
        ),
      ).rejects.toThrow(BadRequestException);

      await expect(
        expensesService.createExpense(
          {
            recordDate: '2026-10-12',
            costCentre: CostCentre.FARM,
            category: ExpenseCategory.VET,
            amount: -500.0,
          },
          testUserId,
        ),
      ).rejects.toThrow(BadRequestException);
    });

    it('prevents duplicate expense entry for identical vendor invoice in same cost centre', async () => {
      await expect(
        expensesService.createExpense(
          {
            recordDate: '2026-10-12',
            costCentre: CostCentre.PRODUCTION,
            category: ExpenseCategory.CLEANING,
            amount: 1450.5,
            payee: 'CleanTech Chemical Supplies',
            invoiceNumber: invNum1,
          },
          testUserId,
        ),
      ).rejects.toThrow(ConflictException);
    });

    it('computes aggregated expense totals across cost centres in query endpoint', async () => {
      // Add one FARM expense and one BIOGAS expense
      await expensesService.createExpense({
        recordDate: '2026-10-12',
        costCentre: CostCentre.FARM,
        category: ExpenseCategory.MAINTENANCE,
        amount: 2500.0,
        payee: 'Tractor Repair Workshop',
      });

      await expensesService.createExpense({
        recordDate: '2026-10-12',
        costCentre: CostCentre.BIOGAS,
        category: ExpenseCategory.MAINTENANCE,
        amount: 800.0,
        payee: 'Valve & Pipe Hardware',
      });

      const res = await expensesService.findAll({ page: 1, limit: 50 });
      expect(res.items.length).toBeGreaterThanOrEqual(3);
      expect(res.summary.totalExpenses).toBeGreaterThanOrEqual(1450.5 + 2500.0 + 800.0);
      expect(res.summary.byCostCentre.farm).toBeGreaterThanOrEqual(2500.0);
      expect(res.summary.byCostCentre.production).toBeGreaterThanOrEqual(1450.5);
      expect(res.summary.byCostCentre.biogas).toBeGreaterThanOrEqual(800.0);
    });
  });
});
