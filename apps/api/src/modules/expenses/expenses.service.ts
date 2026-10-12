import {
  Injectable,
  NotFoundException,
  ConflictException,
  BadRequestException,
} from '@nestjs/common';
import { DataSource } from 'typeorm';
import { randomUUID } from 'crypto';
import { OperatingExpenseEntity } from './entities/operating-expense.entity';
import { CreateExpenseDto } from './dto/create-expense.dto';
import { ExpenseQueryDto } from './dto/expense-query.dto';
import { AuditLogEntity } from '../audit/entities/audit-log.entity';
import { CostCentre, PaymentMethod } from '@dairy-farm/api-contracts';

@Injectable()
export class ExpensesService {
  constructor(private readonly dataSource: DataSource) {}

  async createExpense(dto: CreateExpenseDto, userId?: string): Promise<OperatingExpenseEntity> {
    if (dto.amount <= 0) {
      throw new BadRequestException('Expense amount must be strictly greater than zero');
    }

    const expenseNumber = dto.expenseNumber?.trim() || `EXP-${Date.now().toString().slice(-6)}`;
    const invoiceNumber = dto.invoiceNumber?.trim() || null;
    const payee = dto.payee?.trim() || null;

    return await this.dataSource.transaction(async (manager) => {
      // Check duplicate expenseNumber
      const existingNumber = await manager.findOne(OperatingExpenseEntity, {
        where: { expense_number: expenseNumber },
      });
      if (existingNumber) {
        throw new ConflictException(`Expense number ${expenseNumber} already exists`);
      }

      // Check duplicate invoiceNumber for the same payee and cost centre to avoid double counting
      if (invoiceNumber && payee) {
        const existingInvoice = await manager.findOne(OperatingExpenseEntity, {
          where: {
            cost_centre: dto.costCentre,
            payee,
            invoice_number: invoiceNumber,
          },
        });
        if (existingInvoice) {
          throw new ConflictException(
            `Duplicate invoice voucher ${invoiceNumber} already recorded for payee "${payee}" under ${dto.costCentre}`,
          );
        }
      }

      const expenseId = randomUUID();
      const expense = manager.create(OperatingExpenseEntity, {
        id: expenseId,
        expense_number: expenseNumber,
        record_date: dto.recordDate,
        cost_centre: dto.costCentre,
        category: dto.category,
        amount: dto.amount,
        production_batch_id: dto.productionBatchId || null,
        payee,
        invoice_number: invoiceNumber,
        payment_method: dto.paymentMethod || PaymentMethod.CASH,
        notes: dto.notes?.trim() || null,
        created_by: userId || null,
      });

      const savedExpense = await manager.save(OperatingExpenseEntity, expense);

      // Audit Log
      const auditLog = manager.create(AuditLogEntity, {
        id: randomUUID(),
        entityType: 'operating_expenses',
        entityId: expenseId,
        action: 'EXPENSE_RECORDED',
        newValues: {
          expenseNumber,
          costCentre: dto.costCentre,
          category: dto.category,
          amount: dto.amount,
          payee,
        },
        userId: userId || 'system',
      });
      await manager.save(AuditLogEntity, auditLog);

      return savedExpense;
    });
  }

  async findAll(query: ExpenseQueryDto) {
    const page = query.page || 1;
    const limit = query.limit || 20;
    const skip = (page - 1) * limit;

    const qb = this.dataSource
      .getRepository(OperatingExpenseEntity)
      .createQueryBuilder('exp')
      .leftJoinAndSelect('exp.production_batch', 'production_batch')
      .orderBy('exp.record_date', 'DESC')
      .addOrderBy('exp.created_at', 'DESC');

    if (query.startDate) {
      qb.andWhere('exp.record_date >= :startDate', { startDate: query.startDate });
    }
    if (query.endDate) {
      qb.andWhere('exp.record_date <= :endDate', { endDate: query.endDate });
    }
    if (query.costCentre) {
      qb.andWhere('exp.cost_centre = :costCentre', { costCentre: query.costCentre });
    }
    if (query.category) {
      qb.andWhere('exp.category = :category', { category: query.category });
    }
    if (query.productionBatchId) {
      qb.andWhere('exp.production_batch_id = :batchId', { batchId: query.productionBatchId });
    }

    const [items, total] = await qb.skip(skip).take(limit).getManyAndCount();

    // Summary aggregates
    const summaryRaw = await this.dataSource
      .getRepository(OperatingExpenseEntity)
      .createQueryBuilder('exp')
      .select('SUM(exp.amount)', 'totalAmount')
      .addSelect(`SUM(CASE WHEN exp.cost_centre = '${CostCentre.FARM}' THEN exp.amount ELSE 0 END)`, 'farmTotal')
      .addSelect(`SUM(CASE WHEN exp.cost_centre = '${CostCentre.PRODUCTION}' THEN exp.amount ELSE 0 END)`, 'prodTotal')
      .addSelect(`SUM(CASE WHEN exp.cost_centre = '${CostCentre.BIOGAS}' THEN exp.amount ELSE 0 END)`, 'biogasTotal')
      .getRawOne();

    const totalAmount = parseFloat(summaryRaw?.totalAmount || '0');
    const farmTotal = parseFloat(summaryRaw?.farmTotal || '0');
    const prodTotal = parseFloat(summaryRaw?.prodTotal || '0');
    const biogasTotal = parseFloat(summaryRaw?.biogasTotal || '0');

    return {
      items,
      total,
      page,
      totalPages: Math.ceil(total / limit) || 1,
      summary: {
        totalExpenses: Math.round(totalAmount * 100) / 100,
        byCostCentre: {
          farm: Math.round(farmTotal * 100) / 100,
          production: Math.round(prodTotal * 100) / 100,
          biogas: Math.round(biogasTotal * 100) / 100,
        },
      },
    };
  }

  async findOne(id: string): Promise<OperatingExpenseEntity> {
    const expense = await this.dataSource
      .getRepository(OperatingExpenseEntity)
      .createQueryBuilder('exp')
      .leftJoinAndSelect('exp.production_batch', 'production_batch')
      .where('exp.id = :id', { id })
      .getOne();

    if (!expense) {
      throw new NotFoundException(`Operating expense with ID ${id} not found`);
    }
    return expense;
  }
}
