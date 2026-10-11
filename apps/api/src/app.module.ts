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
  ],
})
export class AppModule {}
