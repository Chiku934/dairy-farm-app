import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SalesController } from './sales.controller';
import { SalesService } from './sales.service';
import { CustomerEntity } from './entities/customer.entity';
import { SalesOrderEntity } from './entities/sales-order.entity';
import { SalesOrderItemEntity } from './entities/sales-order-item.entity';
import { SalesDispatchEntity } from './entities/sales-dispatch.entity';
import { SalesDispatchItemEntity } from './entities/sales-dispatch-item.entity';
import { CustomerPaymentEntity } from './entities/customer-payment.entity';
import { AuditModule } from '../audit/audit.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      CustomerEntity,
      SalesOrderEntity,
      SalesOrderItemEntity,
      SalesDispatchEntity,
      SalesDispatchItemEntity,
      CustomerPaymentEntity,
    ]),
    AuditModule,
  ],
  controllers: [SalesController],
  providers: [SalesService],
  exports: [SalesService],
})
export class SalesModule {}
