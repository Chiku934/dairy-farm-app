import { PartialType } from '@nestjs/swagger';
import { CreateMilkingLogDto } from './create-milking-log.dto';

export class UpdateMilkingLogDto extends PartialType(CreateMilkingLogDto) {}
