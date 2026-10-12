import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { BiogasRunEntity } from './entities/biogas-run.entity';
import { BiogasService } from './biogas.service';
import { BiogasController } from './biogas.controller';

@Module({
  imports: [TypeOrmModule.forFeature([BiogasRunEntity])],
  controllers: [BiogasController],
  providers: [BiogasService],
  exports: [BiogasService],
})
export class BiogasModule {}
