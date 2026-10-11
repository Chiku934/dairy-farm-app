import { TypeOrmModuleOptions } from '@nestjs/typeorm';

export const getDatabaseConfig = (): TypeOrmModuleOptions => ({
  type: 'mysql',
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '3306', 10),
  username: process.env.DB_USERNAME || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_DATABASE || 'dairy_farm_db',
  entities: [__dirname + '/../../**/*.entity{.ts,.js}'],
  synchronize: false, // Strict migration-based schema management
  logging: process.env.NODE_ENV === 'development',
});
