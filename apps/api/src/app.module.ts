import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { getDatabaseConfig } from './modules/database/database.config';
import { HealthModule } from './modules/health/health.module';
import { SettingsModule } from './modules/settings/settings.module';
import { UsersModule } from './modules/users/users.module';
import { AuthModule } from './modules/auth/auth.module';
import { MasterDataModule } from './modules/master-data/master-data.module';
import { AuditModule } from './modules/audit/audit.module';
import { DashboardModule } from './modules/dashboard/dashboard.module';
import { HerdModule } from './modules/herd/herd.module';
import { AnimalHealthModule } from './modules/animal-health/animal-health.module';
import { BreedingModule } from './modules/breeding/breeding.module';
import { MilkingModule } from './modules/milking/milking.module';
import { FeedModule } from './modules/feed/feed.module';
import { CostingModule } from './modules/costing/costing.module';
import { BmcModule } from './modules/bmc/bmc.module';
import { ProductionModule } from './modules/production/production.module';
import { PackagingModule } from './modules/packaging/packaging.module';
import { QualityModule } from './modules/quality/quality.module';
import { MaterialsModule } from './modules/materials/materials.module';
import { ElectricityModule } from './modules/electricity/electricity.module';
import { InventoryModule } from './modules/inventory/inventory.module';
import { SalesModule } from './modules/sales/sales.module';
import { BiogasModule } from './modules/biogas/biogas.module';
import { WastageModule } from './modules/wastage/wastage.module';
import { ExpensesModule } from './modules/expenses/expenses.module';
import { EmployeesModule } from './modules/employees/employees.module';
import { LicencesModule } from './modules/licences/licences.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: ['.env.local', '.env'],
    }),
    TypeOrmModule.forRootAsync({
      useFactory: () => getDatabaseConfig(),
    }),
    HealthModule,
    SettingsModule,
    UsersModule,
    AuthModule,
    MasterDataModule,
    AuditModule,
    DashboardModule,
    HerdModule,
    AnimalHealthModule,
    BreedingModule,
    MilkingModule,
    FeedModule,
    CostingModule,
    BmcModule,
    ProductionModule,
    PackagingModule,
    QualityModule,
    MaterialsModule,
    ElectricityModule,
    InventoryModule,
    SalesModule,
    BiogasModule,
    WastageModule,
    ExpensesModule,
    EmployeesModule,
    LicencesModule,
  ],
})
export class AppModule {}

