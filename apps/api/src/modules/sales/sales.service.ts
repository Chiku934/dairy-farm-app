import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ConflictException,
} from '@nestjs/common';
import { DataSource } from 'typeorm';
import { v4 as uuidv4 } from 'uuid';
import { OrderStatus, PaymentMethod, ProductType } from '@dairy-farm/api-contracts';
import { CustomerEntity } from './entities/customer.entity';
import { SalesOrderEntity } from './entities/sales-order.entity';
import { SalesOrderItemEntity } from './entities/sales-order-item.entity';
import { SalesDispatchEntity } from './entities/sales-dispatch.entity';
import { SalesDispatchItemEntity } from './entities/sales-dispatch-item.entity';
import { CustomerPaymentEntity } from './entities/customer-payment.entity';
import { CreateCustomerDto } from './dto/create-customer.dto';
import { CreateSalesOrderDto } from './dto/create-sales-order.dto';
import { CreateSalesDispatchDto } from './dto/create-sales-dispatch.dto';
import { CreateCustomerPaymentDto } from './dto/create-customer-payment.dto';
import {
  SalesOrderQueryDto,
  SalesDispatchQueryDto,
  CustomerPaymentQueryDto,
} from './dto/sales-query.dto';
import { AuditService } from '../audit/audit.service';
import { AuthenticatedUser } from '../../common/decorators/current-user.decorator';

@Injectable()
export class SalesService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly auditService: AuditService,
  ) {}

  // ==========================================================================
  // 1. CUSTOMERS
  // ==========================================================================

  async getCustomers() {
    return this.dataSource.getRepository(CustomerEntity).find({
      where: { isActive: true },
      order: { name: 'ASC' },
    });
  }

  async getCustomerById(id: string) {
    const customer = await this.dataSource.getRepository(CustomerEntity).findOne({ where: { id } });
    if (!customer) {
      throw new NotFoundException(`Customer with ID "${id}" not found.`);
    }

    const dispatches = await this.dataSource.getRepository(SalesDispatchEntity).find({
      where: { customerId: id },
      order: { recordDate: 'DESC' },
      take: 20,
    });

    const payments = await this.dataSource.getRepository(CustomerPaymentEntity).find({
      where: { customerId: id },
      order: { recordDate: 'DESC' },
      take: 20,
    });

    return {
      ...customer,
      recentDispatches: dispatches,
      recentPayments: payments,
    };
  }

  async createCustomer(dto: CreateCustomerDto, user: AuthenticatedUser) {
    const existing = await this.dataSource.getRepository(CustomerEntity).findOne({
      where: { name: dto.name.trim() },
    });
    if (existing) {
      throw new ConflictException(`Customer with name "${dto.name}" already exists.`);
    }

    const customer = this.dataSource.getRepository(CustomerEntity).create({
      id: uuidv4(),
      name: dto.name.trim(),
      phone: dto.phone?.trim() || null,
      email: dto.email?.trim() || null,
      address: dto.address?.trim() || null,
      customerType: dto.customerType,
      creditLimit: dto.creditLimit ? Math.round(Number(dto.creditLimit) * 100) / 100 : 0.0,
      currentBalance: 0.0,
      isActive: true,
    });

    const saved = await this.dataSource.getRepository(CustomerEntity).save(customer);

    await this.auditService.logAction({
      userId: user?.userId,
      action: 'CREATE_CUSTOMER',
      entityType: 'CUSTOMER',
      entityId: saved.id,
      newValues: { name: saved.name, type: saved.customerType },
    });

    return saved;
  }

  // ==========================================================================
  // 2. SALES ORDERS
  // ==========================================================================

  async getOrders(query: SalesOrderQueryDto) {
    const page = Math.max(1, Number(query.page) || 1);
    const limit = Math.max(1, Math.min(100, Number(query.limit) || 20));
    const offset = (page - 1) * limit;

    const qb = this.dataSource
      .getRepository(SalesOrderEntity)
      .createQueryBuilder('order')
      .leftJoinAndSelect('order.customer', 'customer')
      .leftJoinAndSelect('order.items', 'items');

    if (query.status) {
      qb.andWhere('order.status = :status', { status: query.status });
    }
    if (query.customerId) {
      qb.andWhere('order.customer_id = :customerId', { customerId: query.customerId });
    }
    if (query.startDate) {
      qb.andWhere('order.order_date >= :startDate', { startDate: query.startDate });
    }
    if (query.endDate) {
      qb.andWhere('order.order_date <= :endDate', { endDate: query.endDate });
    }

    qb.orderBy('order.order_date', 'DESC').addOrderBy('order.created_at', 'DESC');

    const [items, total] = await qb.skip(offset).take(limit).getManyAndCount();

    return {
      items,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async getOrderById(id: string) {
    const order = await this.dataSource.getRepository(SalesOrderEntity).findOne({
      where: { id },
      relations: ['customer', 'items'],
    });
    if (!order) {
      throw new NotFoundException(`Sales order with ID "${id}" not found.`);
    }

    const dispatches = await this.dataSource.getRepository(SalesDispatchEntity).find({
      where: { orderId: id },
      relations: ['items'],
    });

    return {
      ...order,
      dispatches,
    };
  }

  async createOrder(dto: CreateSalesOrderDto, user: AuthenticatedUser) {
    if (!dto.items || dto.items.length === 0) {
      throw new BadRequestException('Sales order must contain at least one line item.');
    }

    const customer = await this.dataSource.getRepository(CustomerEntity).findOne({
      where: { id: dto.customerId },
    });
    if (!customer) {
      throw new NotFoundException(`Customer with ID "${dto.customerId}" not found.`);
    }

    const orderNumber =
      dto.orderNumber?.trim() ||
      `SO-${dto.orderDate.replace(/-/g, '')}-${Math.floor(1000 + Math.random() * 9000)}`;

    const existing = await this.dataSource.getRepository(SalesOrderEntity).findOne({
      where: { orderNumber },
    });
    if (existing) {
      throw new ConflictException(`Order with number "${orderNumber}" already exists.`);
    }

    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      const orderId = uuidv4();
      let orderTotal = 0;

      const orderItems = dto.items.map((itemDto) => {
        const qty = Math.round(Number(itemDto.quantityOrdered));
        const price = Math.round(Number(itemDto.unitPrice) * 100) / 100;
        const lineTotal = Math.round(qty * price * 100) / 100;
        orderTotal += lineTotal;

        return queryRunner.manager.create(SalesOrderItemEntity, {
          id: uuidv4(),
          orderId,
          productType: itemDto.productType,
          packSize: itemDto.packSize || 1.0,
          packUnit: itemDto.packUnit || 'LITRE',
          quantityOrdered: qty,
          quantityDispatched: 0,
          unitPrice: price,
          totalPrice: lineTotal,
        });
      });

      orderTotal = Math.round(orderTotal * 100) / 100;

      const order = queryRunner.manager.create(SalesOrderEntity, {
        id: orderId,
        orderNumber,
        customerId: dto.customerId,
        orderDate: dto.orderDate,
        deliveryDate: dto.deliveryDate,
        status: OrderStatus.PENDING,
        totalAmount: orderTotal,
        notes: dto.notes ? dto.notes.trim() : null,
        createdBy: user?.userId || null,
      });

      await queryRunner.manager.save(order);
      await queryRunner.manager.save(orderItems);

      await queryRunner.commitTransaction();

      await this.auditService.logAction({
        userId: user?.userId,
        action: 'CREATE_SALES_ORDER',
        entityType: 'SALES_ORDER',
        entityId: orderId,
        newValues: { orderNumber, customerId: dto.customerId, totalAmount: orderTotal },
      });

      return this.getOrderById(orderId);
    } catch (err) {
      await queryRunner.rollbackTransaction();
      throw err;
    } finally {
      await queryRunner.release();
    }
  }

  async cancelOrder(id: string, user: AuthenticatedUser) {
    const order = await this.dataSource.getRepository(SalesOrderEntity).findOne({
      where: { id },
      relations: ['items'],
    });
    if (!order) {
      throw new NotFoundException(`Sales order with ID "${id}" not found.`);
    }

    if (order.status === OrderStatus.CANCELLED) {
      return order;
    }

    if (order.status !== OrderStatus.PENDING) {
      throw new BadRequestException(
        `Cannot cancel order in "${order.status}" status. Only PENDING orders without dispatches can be cancelled.`,
      );
    }

    order.status = OrderStatus.CANCELLED;
    await this.dataSource.getRepository(SalesOrderEntity.name).save(order);

    await this.auditService.logAction({
      userId: user?.userId,
      action: 'CANCEL_SALES_ORDER',
      entityType: 'SALES_ORDER',
      entityId: id,
      newValues: { status: OrderStatus.CANCELLED },
    });

    return order;
  }

  // ==========================================================================
  // 3. SALES DISPATCHES
  // ==========================================================================

  async getDispatches(query: SalesDispatchQueryDto) {
    const page = Math.max(1, Number(query.page) || 1);
    const limit = Math.max(1, Math.min(100, Number(query.limit) || 20));
    const offset = (page - 1) * limit;

    const qb = this.dataSource
      .getRepository(SalesDispatchEntity)
      .createQueryBuilder('dispatch')
      .leftJoinAndSelect('dispatch.customer', 'customer')
      .leftJoinAndSelect('dispatch.items', 'items');

    if (query.productType) {
      qb.andWhere('dispatch.product_type = :productType', { productType: query.productType });
    }
    if (query.customerId) {
      qb.andWhere('dispatch.customer_id = :customerId', { customerId: query.customerId });
    }
    if (query.orderId) {
      qb.andWhere('dispatch.order_id = :orderId', { orderId: query.orderId });
    }
    if (query.startDate) {
      qb.andWhere('dispatch.record_date >= :startDate', { startDate: query.startDate });
    }
    if (query.endDate) {
      qb.andWhere('dispatch.record_date <= :endDate', { endDate: query.endDate });
    }

    qb.orderBy('dispatch.record_date', 'DESC').addOrderBy('dispatch.created_at', 'DESC');

    const [items, total] = await qb.skip(offset).take(limit).getManyAndCount();

    return {
      items,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async getDispatchById(id: string) {
    const dispatch = await this.dataSource.getRepository(SalesDispatchEntity).findOne({
      where: { id },
      relations: ['customer', 'items'],
    });
    if (!dispatch) {
      throw new NotFoundException(`Sales dispatch with ID "${id}" not found.`);
    }
    return dispatch;
  }

  async createDispatch(dto: CreateSalesDispatchDto, user: AuthenticatedUser) {
    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      // 1. Pessimistic lock on Customer
      const customer = await queryRunner.manager
        .createQueryBuilder(CustomerEntity, 'c')
        .setLock('pessimistic_write')
        .where('c.id = :id', { id: dto.customerId })
        .getOne();

      if (!customer) {
        throw new NotFoundException(`Customer with ID "${dto.customerId}" not found.`);
      }

      // 2. Resolve Dispatch Lines & Summary Fields
      let totalAmount = 0;
      let primaryProductType: ProductType = dto.productType || ProductType.MILK;
      let primaryPacksSold = 0;
      let primaryPricePerPack = 0;

      const dispatchId = uuidv4();
      const dispatchItems: SalesDispatchItemEntity[] = [];

      if (dto.items && dto.items.length > 0) {
        for (const itemDto of dto.items) {
          const qty = Math.round(Number(itemDto.quantity));
          const price = Math.round(Number(itemDto.unitPrice) * 100) / 100;
          const lineTotal = Math.round(qty * price * 100) / 100;
          totalAmount += lineTotal;

          dispatchItems.push(
            queryRunner.manager.create(SalesDispatchItemEntity, {
              id: uuidv4(),
              dispatchId,
              orderItemId: itemDto.orderItemId || null,
              packagingRunId: itemDto.packagingRunId || null,
              productType: itemDto.productType,
              packSize: itemDto.packSize || 1.0,
              packUnit: itemDto.packUnit || 'LITRE',
              quantity: qty,
              unitPrice: price,
              totalPrice: lineTotal,
            }),
          );
        }
        primaryProductType = dto.items[0].productType;
        primaryPacksSold = dto.items.reduce((sum, i) => sum + i.quantity, 0);
        primaryPricePerPack = dto.items[0].unitPrice;
      } else {
        if (!dto.productType || !dto.packsSold || !dto.pricePerPack) {
          throw new BadRequestException('Single-line dispatch requires productType, packsSold, and pricePerPack.');
        }
        const qty = Math.round(Number(dto.packsSold));
        const price = Math.round(Number(dto.pricePerPack) * 100) / 100;
        totalAmount = Math.round(qty * price * 100) / 100;
        primaryProductType = dto.productType;
        primaryPacksSold = qty;
        primaryPricePerPack = price;

        dispatchItems.push(
          queryRunner.manager.create(SalesDispatchItemEntity, {
            id: uuidv4(),
            dispatchId,
            orderItemId: null,
            packagingRunId: dto.packagingRunId || null,
            productType: dto.productType,
            packSize: 1.0,
            packUnit: 'LITRE',
            quantity: qty,
            unitPrice: price,
            totalPrice: totalAmount,
          }),
        );
      }

      totalAmount = Math.round(totalAmount * 100) / 100;
      const amountReceived = Math.round((Number(dto.amountReceived) || 0) * 100) / 100;
      if (amountReceived < 0) {
        throw new BadRequestException('Amount received cannot be negative.');
      }
      const balanceDue = Math.round((totalAmount - amountReceived) * 100) / 100;

      // 3. Handle Order Linkage & Partial/Full Fulfillment Transition
      if (dto.orderId) {
        const order = await queryRunner.manager
          .createQueryBuilder(SalesOrderEntity, 'o')
          .setLock('pessimistic_write')
          .leftJoinAndSelect('o.items', 'items')
          .where('o.id = :id', { id: dto.orderId })
          .getOne();

        if (!order) {
          throw new NotFoundException(`Referenced sales order "${dto.orderId}" not found.`);
        }
        if (order.status === OrderStatus.CANCELLED) {
          throw new BadRequestException('Cannot dispatch against a CANCELLED sales order.');
        }

        // Increment dispatched quantity on matching order items
        if (order.items && order.items.length > 0) {
          for (const dItem of dispatchItems) {
            let matchedOrderItem = order.items.find((oi) => oi.id === dItem.orderItemId);
            if (!matchedOrderItem) {
              matchedOrderItem = order.items.find(
                (oi) =>
                  oi.productType === dItem.productType &&
                  oi.quantityDispatched < oi.quantityOrdered,
              );
            }
            if (matchedOrderItem) {
              matchedOrderItem.quantityDispatched += dItem.quantity;
              dItem.orderItemId = matchedOrderItem.id;
              await queryRunner.manager.save(matchedOrderItem);
            }
          }

          // Evaluate order fulfillment state
          const totalOrdered = order.items.reduce((s, i) => s + i.quantityOrdered, 0);
          const totalDispatched = order.items.reduce((s, i) => s + i.quantityDispatched, 0);

          if (totalDispatched >= totalOrdered) {
            order.status = OrderStatus.FULFILLED;
          } else if (totalDispatched > 0) {
            order.status = OrderStatus.PARTIALLY_FULFILLED;
          }
          await queryRunner.manager.save(order);
        }
      }

      // 4. Generate Dispatch Number
      const dispatchNumber =
        dto.dispatchNumber?.trim() ||
        `DSP-${dto.recordDate.replace(/-/g, '')}-${Math.floor(1000 + Math.random() * 9000)}`;

      const existingDispatch = await queryRunner.manager.findOne(SalesDispatchEntity, {
        where: { dispatchNumber },
      });
      if (existingDispatch) {
        throw new ConflictException(`Dispatch number "${dispatchNumber}" already exists.`);
      }

      // 5. Save Sales Dispatch
      const dispatch = queryRunner.manager.create(SalesDispatchEntity, {
        id: dispatchId,
        dispatchNumber,
        orderId: dto.orderId || null,
        customerId: dto.customerId,
        recordDate: dto.recordDate,
        packagingRunId: dto.packagingRunId || null,
        productType: primaryProductType,
        packsSold: primaryPacksSold,
        pricePerPack: primaryPricePerPack,
        totalAmount,
        amountReceived,
        balanceDue,
        paymentMethod: dto.paymentMethod || PaymentMethod.CASH,
        notes: dto.notes ? dto.notes.trim() : null,
        createdBy: user?.userId || null,
      });

      await queryRunner.manager.save(dispatch);
      await queryRunner.manager.save(dispatchItems);

      // 6. Update Customer Accounts Receivable Balance
      customer.currentBalance = Math.round((Number(customer.currentBalance) + balanceDue) * 100) / 100;
      await queryRunner.manager.save(customer);

      // 7. If cash/advance was collected at dispatch, generate linked CustomerPayment
      if (amountReceived > 0) {
        const paymentNumber = `PAY-${dto.recordDate.replace(/-/g, '')}-${Math.floor(1000 + Math.random() * 9000)}`;
        const payment = queryRunner.manager.create(CustomerPaymentEntity, {
          id: uuidv4(),
          paymentNumber,
          customerId: dto.customerId,
          dispatchId,
          recordDate: dto.recordDate,
          amountReceived,
          paymentMethod: dto.paymentMethod || PaymentMethod.CASH,
          referenceCode: `DISPATCH-${dispatchNumber}`,
          notes: 'Settlement collected at time of delivery/dispatch',
          createdBy: user?.userId || null,
        });
        await queryRunner.manager.save(payment);
      }

      await queryRunner.commitTransaction();

      await this.auditService.logAction({
        userId: user?.userId,
        action: 'CREATE_SALES_DISPATCH',
        entityType: 'SALES_DISPATCH',
        entityId: dispatchId,
        newValues: {
          dispatchNumber,
          customerId: dto.customerId,
          totalAmount,
          balanceDue,
          amountReceived,
        },
      });

      return this.getDispatchById(dispatchId);
    } catch (err) {
      await queryRunner.rollbackTransaction();
      throw err;
    } finally {
      await queryRunner.release();
    }
  }

  // ==========================================================================
  // 4. CUSTOMER PAYMENTS
  // ==========================================================================

  async getPayments(query: CustomerPaymentQueryDto) {
    const page = Math.max(1, Number(query.page) || 1);
    const limit = Math.max(1, Math.min(100, Number(query.limit) || 20));
    const offset = (page - 1) * limit;

    const qb = this.dataSource
      .getRepository(CustomerPaymentEntity)
      .createQueryBuilder('payment')
      .leftJoinAndSelect('payment.customer', 'customer');

    if (query.customerId) {
      qb.andWhere('payment.customer_id = :customerId', { customerId: query.customerId });
    }
    if (query.dispatchId) {
      qb.andWhere('payment.dispatch_id = :dispatchId', { dispatchId: query.dispatchId });
    }
    if (query.startDate) {
      qb.andWhere('payment.record_date >= :startDate', { startDate: query.startDate });
    }
    if (query.endDate) {
      qb.andWhere('payment.record_date <= :endDate', { endDate: query.endDate });
    }

    qb.orderBy('payment.record_date', 'DESC').addOrderBy('payment.created_at', 'DESC');

    const [items, total] = await qb.skip(offset).take(limit).getManyAndCount();

    return {
      items,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async createPayment(dto: CreateCustomerPaymentDto, user: AuthenticatedUser) {
    const amount = Math.round(Number(dto.amountReceived) * 100) / 100;
    if (amount <= 0) {
      throw new BadRequestException('Amount received must be greater than zero.');
    }

    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      // 1. Lock Customer
      const customer = await queryRunner.manager
        .createQueryBuilder(CustomerEntity, 'c')
        .setLock('pessimistic_write')
        .where('c.id = :id', { id: dto.customerId })
        .getOne();

      if (!customer) {
        throw new NotFoundException(`Customer with ID "${dto.customerId}" not found.`);
      }

      // 2. Lock Dispatch if specified
      let linkedDispatch: SalesDispatchEntity | null = null;
      if (dto.dispatchId) {
        linkedDispatch = await queryRunner.manager
          .createQueryBuilder(SalesDispatchEntity, 'd')
          .setLock('pessimistic_write')
          .where('d.id = :id', { id: dto.dispatchId })
          .getOne();

        if (!linkedDispatch) {
          throw new NotFoundException(`Referenced dispatch "${dto.dispatchId}" not found.`);
        }
      }

      // 3. Generate Payment Number
      const paymentNumber =
        dto.paymentNumber?.trim() ||
        `PAY-${dto.recordDate.replace(/-/g, '')}-${Math.floor(1000 + Math.random() * 9000)}`;

      const existing = await queryRunner.manager.findOne(CustomerPaymentEntity, {
        where: { paymentNumber },
      });
      if (existing) {
        throw new ConflictException(`Payment number "${paymentNumber}" already exists.`);
      }

      // 4. Save Payment
      const paymentId = uuidv4();
      const payment = queryRunner.manager.create(CustomerPaymentEntity, {
        id: paymentId,
        paymentNumber,
        customerId: dto.customerId,
        dispatchId: dto.dispatchId || null,
        recordDate: dto.recordDate,
        amountReceived: amount,
        paymentMethod: dto.paymentMethod,
        referenceCode: dto.referenceCode?.trim() || null,
        notes: dto.notes ? dto.notes.trim() : null,
        createdBy: user?.userId || null,
      });

      await queryRunner.manager.save(payment);

      // 5. Deduct Customer Balance
      customer.currentBalance = Math.round((Number(customer.currentBalance) - amount) * 100) / 100;
      await queryRunner.manager.save(customer);

      // 6. Deduct Dispatch Balance Due if linked
      if (linkedDispatch) {
        const currentDue = Number(linkedDispatch.balanceDue);
        const newDue = Math.max(0, Math.round((currentDue - amount) * 100) / 100);
        linkedDispatch.balanceDue = newDue;
        linkedDispatch.amountReceived = Math.round((Number(linkedDispatch.amountReceived) + amount) * 100) / 100;
        await queryRunner.manager.save(linkedDispatch);
      }

      await queryRunner.commitTransaction();

      await this.auditService.logAction({
        userId: user?.userId,
        action: 'CREATE_CUSTOMER_PAYMENT',
        entityType: 'CUSTOMER_PAYMENT',
        entityId: paymentId,
        newValues: {
          paymentNumber,
          customerId: dto.customerId,
          amountReceived: amount,
          newCustomerBalance: customer.currentBalance,
        },
      });

      return payment;
    } catch (err) {
      await queryRunner.rollbackTransaction();
      throw err;
    } finally {
      await queryRunner.release();
    }
  }
}
